import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/screenshots/repositories/screenshot_repository.dart';
import 'package:screenshot_brain/shared/models/expense_model.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

/// Pure tests over the repository's query-building/predicate helpers.
/// No Isar database, no plugins, no filesystem — the helpers are pure
/// functions over in-memory models, mirroring exactly what the repository
/// hands to Isar.
void main() {
  ScreenshotModel screenshot({
    required int id,
    String filePath = '/shots/a.png',
    DateTime? createdAt,
    String? category,
    bool isProcessed = false,
  }) {
    return ScreenshotModel()
      ..id = id
      ..filePath = filePath
      ..createdAt = createdAt ?? DateTime(2026, 10, 1)
      ..category = category
      ..isProcessed = isProcessed;
  }

  ExpenseModel expense({
    required int id,
    required int screenshotId,
  }) {
    return ExpenseModel()
      ..id = id
      ..screenshotId = screenshotId
      ..createdAt = DateTime(2026, 10, 1);
  }

  group('orphanedScreenshotRowIds', () {
    test('selects rows whose file path is gone', () {
      final rows = [
        screenshot(id: 1, filePath: '/keep/1.png'),
        screenshot(id: 2, filePath: '/gone/2.png'),
        screenshot(id: 3, filePath: '/gone/3.png'),
      ];
      expect(
        orphanedScreenshotRowIds({'/keep/1.png'}, rows),
        orderedEquals([2, 3]),
      );
    });

    test('returns nothing when every path still exists', () {
      final rows = [
        screenshot(id: 1, filePath: '/a.png'),
        screenshot(id: 2, filePath: '/b.png'),
      ];
      expect(
        orphanedScreenshotRowIds({'/a.png', '/b.png'}, rows),
        isEmpty,
      );
    });

    test('treats an empty existing-paths set as every row being orphaned', () {
      final rows = [screenshot(id: 7, filePath: '/a.png')];
      expect(orphanedScreenshotRowIds(const {}, rows), orderedEquals([7]));
    });
  });

  group('orphanedExpenseRowIds', () {
    // DEFECT PROOF: the bulk-delete sweep removed screenshot rows but never
    // consulted expense rows, so expenses pointing at deleted screenshots
    // survived as orphans. This helper is what the repository now uses to
    // cascade the delete.
    test('selects expenses that reference any deleted screenshot', () {
      final expenses = [
        expense(id: 10, screenshotId: 1),
        expense(id: 11, screenshotId: 2),
        expense(id: 12, screenshotId: 3),
      ];
      expect(
        orphanedExpenseRowIds({2}, expenses),
        orderedEquals([11]),
      );
    });

    test('selects every dependent row of a multi-id sweep', () {
      final expenses = [
        expense(id: 10, screenshotId: 1),
        expense(id: 11, screenshotId: 5),
        expense(id: 12, screenshotId: 9),
        expense(id: 13, screenshotId: 5),
      ];
      expect(
        orphanedExpenseRowIds({5, 9}, expenses),
        orderedEquals([11, 12, 13]),
      );
    });

    test('returns nothing when no expense points at a deleted screenshot', () {
      final expenses = [expense(id: 10, screenshotId: 1)];
      expect(orphanedExpenseRowIds({2, 3}, expenses), isEmpty);
    });
  });

  group('compareUnprocessedOrder', () {
    // DEFECT PROOF: the unprocessed queue is `limit`-bounded. With only
    // createdAt as the sort key, ties (Isar stores second precision, so a
    // burst of screenshots sharing an mtime is routine) have no defined
    // order — the selection taken by the limit could shift between runs,
    // showing one row twice across passes while another is never picked up.
    final tied = [
      screenshot(id: 3, createdAt: DateTime(2026, 10, 2, 12)),
      screenshot(id: 1, createdAt: DateTime(2026, 10, 2, 12)),
      screenshot(id: 2, createdAt: DateTime(2026, 10, 1, 12)),
    ];

    test('orders oldest first, ties by id ascending', () {
      final sorted = [...tied]..sort(compareUnprocessedOrder);
      expect(sorted.map((m) => m.id).toList(), orderedEquals([2, 1, 3]));
    });

    test('breaks createdAt ties deterministically by id', () {
      final forward = [...tied]..sort(compareUnprocessedOrder);
      final reverse = [...tied.reversed]..sort(compareUnprocessedOrder);
      expect(
        forward.map((m) => m.id).toList(),
        orderedEquals(reverse.map((m) => m.id).toList()),
      );
      // The two tied rows must come out id-ascending regardless of input.
      final tiedOnly = [
        screenshot(id: 3, createdAt: DateTime(2026, 10, 2, 12)),
        screenshot(id: 1, createdAt: DateTime(2026, 10, 2, 12)),
      ];
      final a = [...tiedOnly]..sort(compareUnprocessedOrder);
      final b = [...tiedOnly.reversed]..sort(compareUnprocessedOrder);
      expect(a.map((m) => m.id).toList(), orderedEquals([1, 3]));
      expect(b.map((m) => m.id).toList(), orderedEquals([1, 3]));
    });

    test('a createdAt-only comparator (the old query shape) is not stable', () {
      // Control: shows why the secondary key is needed — with ties, the
      // ordering depends on input order, so a `limit` page boundary can
      // move between runs.
      int byDateOnly(ScreenshotModel a, ScreenshotModel b) =>
          a.createdAt.compareTo(b.createdAt);
      final tiedOnly = [
        screenshot(id: 3, createdAt: DateTime(2026, 10, 2, 12)),
        screenshot(id: 1, createdAt: DateTime(2026, 10, 2, 12)),
      ];
      final a = [...tiedOnly]..sort(byDateOnly);
      final b = [...tiedOnly.reversed]..sort(byDateOnly);
      expect(
        a.map((m) => m.id).toList(),
        isNot(orderedEquals(b.map((m) => m.id).toList())),
      );
    });
  });
}
