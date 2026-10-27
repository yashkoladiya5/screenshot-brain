import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/expenses/models/expense_item.dart';
import 'package:screenshot_brain/features/expenses/providers/expense_provider.dart';
import 'package:screenshot_brain/features/expenses/repositories/expense_repository.dart';
import 'package:screenshot_brain/features/home/providers/home_provider.dart';

/// Test double for [ExpenseRepository]: `implements` (never `extends`), so
/// the repository's Isar field initializer is never evaluated — the whole
/// provider chain below runs on in-memory models only.
class _FakeExpenseRepo implements ExpenseRepository {
  _FakeExpenseRepo([List<ExpenseItem>? items]) : items = items ?? [];

  /// Mutated in place to simulate rows landing between reads (a scan pass).
  List<ExpenseItem> items;
  Object? failure;
  int getAllCalls = 0;

  @override
  Future<List<ExpenseItem>> getAllExpenses() async {
    getAllCalls++;
    if (failure != null) throw failure!;
    return List<ExpenseItem>.unmodifiable(items);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed');
}

/// Mutable stand-in for the two Isar count queries behind
/// [screenshotCountProvider] / [unprocessedCountProvider]. Overridden bodies
/// read it lazily, so recomputation observes the "current" table size.
class _MutableCounts {
  _MutableCounts({this.screenshots = 0, this.unprocessed = 0});

  int screenshots;
  int unprocessed;
}

ProviderContainer _homeContainer({
  required _MutableCounts counts,
  required _FakeExpenseRepo repo,
}) {
  final container = ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(repo),
      screenshotCountProvider.overrideWith((ref) async => counts.screenshots),
      unprocessedCountProvider.overrideWith((ref) async => counts.unprocessed),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

ExpenseItem _expense({
  required int id,
  double? amount,
  String? category,
  DateTime? expenseDate,
  DateTime? createdAt,
}) {
  return ExpenseItem(
    id: id,
    screenshotId: 1,
    amount: amount,
    merchant: 'M$id',
    category: category,
    expenseDate: expenseDate,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 10, 12),
  );
}

/// Four rupee amounts whose naive `double` sum drifts below the exact value:
/// 99.99 + 99.99 + 99.99 + 34.59 == 334.55999999999995.
final _artifactAmounts = [99.99, 99.99, 99.99, 34.59];

void main() {
  group('HomeStats aggregation', () {
    test(
      'maps counts and snapshot figures onto the dashboard payload',
      () async {
        final counts = _MutableCounts(screenshots: 42, unprocessed: 5);
        final repo = _FakeExpenseRepo([
          _expense(id: 1, amount: 1200, category: 'Food'),
          _expense(id: 2, amount: 3600, category: 'Bills'),
        ]);
        final container = _homeContainer(counts: counts, repo: repo);

        final stats = await container.read(homeStatsProvider.future);

        expect(stats.screenshotCount, 42);
        expect(stats.unprocessedCount, 5);
        expect(stats.expenseCount, 2);
        expect(stats.totalExpenses, 4800);
        expect(stats.expensesByCategory['Bills'], 3600);
        expect(stats.expensesByCategory['Food'], 1200);
      },
    );

    test(
      'money figures stay sum-then-round; no float artifact leaks in',
      () async {
        final counts = _MutableCounts(screenshots: 1, unprocessed: 0);
        final repo = _FakeExpenseRepo([
          for (final (index, amount) in _artifactAmounts.indexed)
            _expense(id: index + 1, amount: amount, category: 'Food'),
        ]);
        final container = _homeContainer(counts: counts, repo: repo);

        final stats = await container.read(homeStatsProvider.future);

        // Naive double accumulation at this layer would surface
        // 334.55999999999995 to the dashboard.
        expect(stats.totalExpenses, 334.56);
        expect(stats.expensesByCategory['Food'], 334.56);
      },
    );

    test(
      'monthlyExpenses keeps the snapshot rounding (0.1 + 0.2 == 0.3)',
      () async {
        // The provider wires DateTime.now() for its month window, so this
        // pins the aggregation contract: home forwards the snapshot's
        // once-rounded monthly total, never a raw float sum.
        final counts = _MutableCounts(screenshots: 1);
        final now = DateTime.now();
        final repo = _FakeExpenseRepo([
          _expense(id: 1, amount: 0.1, expenseDate: now),
          _expense(id: 2, amount: 0.2, expenseDate: now),
          _expense(
            id: 3,
            amount: 5,
            expenseDate: DateTime(
              now.year,
              now.month == 1 ? 12 : now.month - 1,
              15,
            ),
          ),
        ]);
        final container = _homeContainer(counts: counts, repo: repo);

        final stats = await container.read(homeStatsProvider.future);

        expect(stats.monthlyExpenses, 0.3);
        expect(stats.totalExpenses, 5.3);
      },
    );

    test('recentExpenses is capped at five and newest-first', () async {
      final counts = _MutableCounts(screenshots: 3);
      final repo = _FakeExpenseRepo([
        for (var i = 0; i < 8; i++)
          _expense(
            id: i + 1,
            amount: 10,
            createdAt: DateTime.utc(
              2026,
              1,
              10,
              8,
            ).subtract(Duration(hours: i)),
          ),
      ]);
      final container = _homeContainer(counts: counts, repo: repo);

      final stats = await container.read(homeStatsProvider.future);

      expect(stats.recentExpenses.length, 5);
      expect(stats.recentExpenses.map((e) => e.id).toList(), [1, 2, 3, 4, 5]);
      expect(stats.expenseCount, 8);
    });

    test(
      'repository failures surface as errors, not a permanent spinner',
      () async {
        final counts = _MutableCounts(screenshots: 1);
        final repo = _FakeExpenseRepo(const []);
        repo.failure = StateError('expense scan failed');
        final container = _homeContainer(counts: counts, repo: repo);

        await expectLater(
          container.read(homeStatsProvider.future),
          throwsStateError,
        );
      },
    );
  });

  group('home dashboard refresh after a scan pass', () {
    // ScanScreenshotsNotifier (and deleteScreenshotProvider) only call
    // `ref.invalidate(homeStatsProvider)` once rows landed. Invalidating a
    // dependent never re-reads its sources, so unless homeStatsProvider
    // itself busts the upstream caches the dashboard keeps showing the
    // numbers captured before the scan.

    test('invalidate(homeStatsProvider) re-reads screenshot counts', () async {
      final counts = _MutableCounts(screenshots: 10, unprocessed: 4);
      final repo = _FakeExpenseRepo(const []);
      final container = _homeContainer(counts: counts, repo: repo);
      container.listen(homeStatsProvider, (_, _) {});

      final before = await container.read(homeStatsProvider.future);
      expect(before.screenshotCount, 10);
      expect(before.unprocessedCount, 4);

      // Scan persists two screenshots (one still unprocessed) and then
      // invalidates homeStatsProvider exactly like ScanScreenshotsNotifier.
      counts.screenshots = 12;
      counts.unprocessed = 5;
      container.invalidate(homeStatsProvider);

      final after = await container.read(homeStatsProvider.future);
      expect(
        after.screenshotCount,
        12,
        reason: 'dashboard must not reuse the pre-scan cached count',
      );
      expect(after.unprocessedCount, 5);
    });

    test('invalidate(homeStatsProvider) re-reads expense figures', () async {
      final counts = _MutableCounts(screenshots: 1);
      final repo = _FakeExpenseRepo([
        _expense(id: 1, amount: 50, category: 'Food'),
      ]);
      final container = _homeContainer(counts: counts, repo: repo);
      container.listen(homeStatsProvider, (_, _) {});

      final before = await container.read(homeStatsProvider.future);
      expect(before.expenseCount, 1);
      expect(before.totalExpenses, 50);

      // OCR extracted a new expense row during the scan pass.
      repo.items = [
        ...repo.items,
        _expense(id: 2, amount: 25, category: 'Travel'),
      ];
      container.invalidate(homeStatsProvider);

      final after = await container.read(homeStatsProvider.future);
      expect(
        after.expenseCount,
        2,
        reason: 'expense figures must refresh after the scan invalidation',
      );
      expect(after.totalExpenses, 75);
      expect(after.expensesByCategory['Travel'], 25);

      // One refetch per invalidation — never a recompute loop. The initial
      // read computes once; the scan rebuild computes the expense chain once
      // more (a second homeStats build from upstream churn would explode
      // this counter).
      expect(repo.getAllCalls, 2);
    });
  });
}
