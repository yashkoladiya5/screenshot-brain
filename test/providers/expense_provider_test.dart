import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/expenses/models/expense_item.dart';
import 'package:screenshot_brain/features/expenses/providers/expense_provider.dart';
import 'package:screenshot_brain/features/expenses/repositories/expense_repository.dart';

/// Test double for [ExpenseRepository]: `implements` (never `extends`), so
/// the repository's `final Isar db = DatabaseService.db` field initializer —
/// which throws without a native Isar — is never evaluated.
class _FakeExpenseRepo implements ExpenseRepository {
  _FakeExpenseRepo({this.items = const [], this.failure});

  final List<ExpenseItem> items;
  final Object? failure;
  int getAllCalls = 0;

  @override
  Future<List<ExpenseItem>> getAllExpenses() async {
    getAllCalls++;
    if (failure != null) throw failure!;
    return items;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not needed');
}

ExpenseItem expense({
  required int id,
  double? amount,
  String? merchant,
  String? category,
  String? description,
  DateTime? expenseDate,
  DateTime? createdAt,
}) {
  return ExpenseItem(
    id: id,
    screenshotId: 1,
    amount: amount,
    merchant: merchant,
    category: category,
    description: description,
    expenseDate: expenseDate,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 10, 12),
  );
}

/// Four rupee amounts whose naive `double` sum drifts below the exact value:
/// 99.99 + 99.99 + 99.99 + 34.59 == 334.55999999999995.
final _artifactAmounts = [99.99, 99.99, 99.99, 34.59];

ProviderContainer _containerWith(List<ExpenseItem> items, {Object? failure}) {
  final container = ProviderContainer(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(
        _FakeExpenseRepo(items: items, failure: failure),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  // Reference month for `ExpenseSnapshot.from(..., now: ...)`: mid-January.
  final january = DateTime.utc(2026, 1, 15, 9);

  group('ExpenseSnapshot money math (sum-then-round)', () {
    test('total is rounded once after summing, not left as a float artifact', () {
      final snapshot = ExpenseSnapshot.from(
        [
          for (final (index, amount) in _artifactAmounts.indexed)
            expense(id: index + 1, amount: amount, category: 'Food'),
        ],
        now: january,
      );
      // Naive double accumulation yields 334.55999999999995.
      expect(snapshot.total, 334.56);
    });

    test('total of 0.1 + 0.2 is exactly 0.3', () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: 0.1, category: 'Food'),
          expense(id: 2, amount: 0.2, category: 'Food'),
        ],
        now: january,
      );
      expect(snapshot.total, 0.3);
    });

    test('per-category totals are rounded after each category is summed', () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: 10.10, category: 'Food'),
          expense(id: 2, amount: 10.20, category: 'Food'),
          expense(id: 3, amount: 5.00, category: 'Travel'),
        ],
        now: january,
      );
      // 10.10 + 10.20 drifts to 20.299999999999997 without a final round.
      expect(snapshot.byCategory['Food'], 20.30);
      expect(snapshot.byCategory['Travel'], 5.00);
    });

    test('monthlyTotal is rounded after summing the month', () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: 0.1, expenseDate: DateTime.utc(2026, 1, 5)),
          expense(id: 2, amount: 0.2, expenseDate: DateTime.utc(2026, 1, 6)),
        ],
        now: january,
      );
      expect(snapshot.monthlyTotal, 0.3);
    });

    test('null amounts count as zero and fall into the Other bucket', () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: null, category: null),
          expense(id: 2, amount: 5.00, category: 'Food'),
        ],
        now: january,
      );
      expect(snapshot.total, 5.00);
      expect(snapshot.byCategory['Other'], 0);
      expect(snapshot.byCategory['Food'], 5.00);
    });

    test('negative amounts (refunds) subtract from total and category', () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: 100.00, category: 'Shopping'),
          expense(id: 2, amount: -30.00, category: 'Shopping'),
        ],
        now: january,
      );
      expect(snapshot.total, 70.00);
      expect(snapshot.byCategory['Shopping'], 70.00);
    });

    test('empty source yields zero totals and empty breakdown', () {
      final snapshot = ExpenseSnapshot.from(const <ExpenseItem>[], now: january);
      expect(snapshot.total, 0);
      expect(snapshot.monthlyTotal, 0);
      expect(snapshot.byCategory, isEmpty);
      expect(snapshot.recent, isEmpty);
    });
  });

  group('ExpenseSnapshot monthly window', () {
    test('calendar-month boundaries are inclusive at both ends', () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(
            id: 1,
            amount: 10,
            expenseDate: DateTime.utc(2025, 12, 31, 23, 59, 59),
          ),
          expense(
            id: 2,
            amount: 20,
            expenseDate: DateTime.utc(2026, 1, 1, 0, 0, 0),
          ),
          expense(
            id: 3,
            amount: 30,
            expenseDate: DateTime.utc(2026, 1, 31, 23, 59, 59),
          ),
          expense(id: 4, amount: 40, expenseDate: DateTime.utc(2026, 2, 1)),
        ],
        now: january,
      );
      expect(snapshot.monthlyTotal, 50);
      expect(snapshot.total, 100);
    });

    test('falls back to createdAt for month bucketing when expenseDate is null',
    () {
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: 7.50, createdAt: DateTime.utc(2026, 1, 3)),
          expense(id: 2, amount: 2.50, createdAt: DateTime.utc(2026, 3, 3)),
        ],
        now: january,
      );
      expect(snapshot.monthlyTotal, 7.50);
    });
  });

  group('ExpenseSnapshot deterministic ordering', () {
    test('expenses are newest-first with id-descending tie-break', () {
      final sameDay = DateTime.utc(2026, 1, 10, 12);
      final snapshot = ExpenseSnapshot.from(
        [
          expense(id: 1, amount: 1, createdAt: sameDay),
          expense(id: 2, amount: 1, createdAt: sameDay),
          expense(id: 3, amount: 1, createdAt: sameDay),
        ],
        now: january,
      );
      expect(snapshot.expenses.map((e) => e.id).toList(), [3, 2, 1]);
    });

    test('same data in different repository orders yields one order', () {
      final sameDay = DateTime.utc(2026, 1, 10, 12);
      final older = DateTime.utc(2026, 1, 9, 12);
      final forward = [
        expense(id: 1, amount: 1, createdAt: sameDay),
        expense(id: 2, amount: 1, createdAt: sameDay),
        expense(id: 3, amount: 1, createdAt: older),
      ];
      final backward = forward.reversed.toList();
      expect(
        ExpenseSnapshot.from(backward, now: january).expenses.map((e) => e.id),
        ExpenseSnapshot.from(forward, now: january).expenses.map((e) => e.id),
      );
    });

    test('recent cutoff drops tied items deterministically', () {
      // 8 items with distinct createdAt plus 4 older items sharing one
      // createdAt: the recent-10 window cuts *through* the tied group, so
      // which of the tied items survive must not depend on input order.
      final tied = DateTime.utc(2026, 1, 8);
      final distinct = [
        for (var i = 0; i < 8; i++)
          expense(
            id: 100 + i,
            amount: 1,
            createdAt: DateTime.utc(2026, 1, 10, 8).subtract(
              Duration(hours: i),
            ),
          ),
      ];
      final group = [
        for (var id = 1; id <= 4; id++)
          expense(id: id, amount: 1, createdAt: tied),
      ];
      final expected = [100, 101, 102, 103, 104, 105, 106, 107, 4, 3];

      final forward = ExpenseSnapshot.from(
        [...distinct, ...group],
        now: january,
      );
      final backward = ExpenseSnapshot.from(
        [...distinct, ...group.reversed],
        now: january,
      );
      expect(forward.recent.map((e) => e.id).toList(), expected);
      expect(backward.recent.map((e) => e.id).toList(), expected);
    });

    test('byCategory iteration order is total desc, name asc, input-proof', () {
      final items = [
        expense(id: 1, amount: 50, category: 'Travel'),
        expense(id: 2, amount: 100, category: 'Food'),
        expense(id: 3, amount: 50, category: 'Hotel'),
      ];
      expect(
        ExpenseSnapshot.from(items, now: january).byCategory.keys.toList(),
        ['Food', 'Hotel', 'Travel'],
      );
      expect(
        ExpenseSnapshot.from(items.reversed.toList(), now: january)
            .byCategory
            .keys
            .toList(),
        ['Food', 'Hotel', 'Travel'],
      );
    });
  });

  group('search', () {
    final items = [
      expense(id: 1, amount: 5, merchant: 'Zomato Outlet', category: 'Food'),
      expense(id: 2, amount: 7, merchant: 'Uber', description: 'Cab ride'),
      expense(id: 3, amount: 9, merchant: 'BigBasket', category: 'Groceries'),
    ];

    test('normalizeExpenseQuery trims, lowercases and collapses whitespace',
    () {
      expect(
        normalizeExpenseQuery('  ZOMATO   outlet '),
        'zomato outlet',
      );
    });

    test('matches merchant, category or description case-insensitively', () {
      final snapshot = ExpenseSnapshot.from(items, now: january);
      expect(snapshot.search('zomato').map((e) => e.id), [1]);
      expect(snapshot.search('CAB'.toLowerCase()).map((e) => e.id), [2]);
      expect(snapshot.search('grocer').map((e) => e.id), [3]);
      expect(snapshot.search('no-match'), isEmpty);
    });

    test('empty query returns the whole ordered list', () {
      final snapshot = ExpenseSnapshot.from(items, now: january);
      expect(snapshot.search('').map((e) => e.id), [3, 2, 1]);
    });
  });

  group('provider wiring', () {
    test('derived providers expose rounded snapshot values', () async {
      final container = _containerWith([
        for (final (index, amount) in _artifactAmounts.indexed)
          expense(id: index + 1, amount: amount, category: 'Food'),
      ]);
      expect(await container.read(expenseTotalProvider.future), 334.56);
      expect(
        await container.read(expenseByCategoryProvider.future),
        {'Food': 334.56},
      );
    });

    test('snapshot, total, categories and recent share one backend scan',
    () async {
      final container = _containerWith([
        expense(id: 1, amount: 10.10, category: 'Food'),
        expense(id: 2, amount: 10.20, category: 'Food'),
      ]);
      // Pin the source so derived providers reuse the single cached scan.
      container.listen(expenseListProvider, (_, _) {});

      final snapshot = await container.read(expenseSnapshotProvider.future);
      final total = await container.read(expenseTotalProvider.future);
      final byCategory = await container.read(expenseByCategoryProvider.future);
      final recent = await container.read(recentExpensesProvider.future);
      final results = await container.read(
        expenseSearchResultsProvider.future,
      );

      expect(snapshot.total, 20.30);
      expect(total, 20.30);
      expect(byCategory['Food'], 20.30);
      expect(recent.map((e) => e.id).toList(), [2, 1]);
      expect(results.map((e) => e.id).toList(), [2, 1]);

      final repo = container.read(expenseRepositoryProvider);
      expect((repo as _FakeExpenseRepo).getAllCalls, 1);
    });

    test('repository failures surface as provider errors, not empty data',
    () async {
      final container = _containerWith(
        const [],
        failure: StateError('isar unavailable'),
      );
      await expectLater(
        container.read(expenseSnapshotProvider.future),
        throwsStateError,
      );
    });

    test('expenseMonthlyTotalProvider covers the running month', () async {
      final now = DateTime.now();
      final container = _containerWith([
        expense(id: 1, amount: 40.00, expenseDate: now),
        expense(
          id: 2,
          amount: 60.00,
          expenseDate: DateTime(now.year, now.month == 1 ? 12 : now.month - 1, 15),
        ),
      ]);
      expect(await container.read(expenseMonthlyTotalProvider.future), 40.00);
    });
  });
}
