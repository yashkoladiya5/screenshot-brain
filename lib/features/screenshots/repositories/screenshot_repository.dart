import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../../services/analytics_service.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/expense_model.dart';
import '../../../shared/models/screenshot_model.dart';
import '../models/screenshot_item.dart';

/// Rows of [all] whose file path is no longer on disk.
///
/// Pure extraction of [ScreenshotRepository.deleteOrphanedScreenshots]'s
/// predicate so the sweep's selection can be tested without Isar.
@visibleForTesting
List<int> orphanedScreenshotRowIds(
  Set<String> existingFilePaths,
  Iterable<ScreenshotModel> all,
) {
  return [
    for (final model in all)
      if (!existingFilePaths.contains(model.filePath)) model.id,
  ];
}

/// Expense rows that would be stranded by deleting [deletedScreenshotIds].
///
/// An [ExpenseModel] carries only a plain `screenshotId` (no Isar backlink),
/// so deleting a screenshot does NOT cascade on its own: without this sweep
/// every dependent expense row survives and points at a screenshot that no
/// longer exists.
@visibleForTesting
List<int> orphanedExpenseRowIds(
  Set<int> deletedScreenshotIds,
  Iterable<ExpenseModel> expenses,
) {
  return [
    for (final expense in expenses)
      if (deletedScreenshotIds.contains(expense.screenshotId)) expense.id,
  ];
}

/// Ordering contract of [ScreenshotRepository.getUnprocessedScreenshots]:
/// oldest first, then id ascending.
///
/// The queue is `limit`-bounded, so the ordering has to be total: Isar
/// timestamps keep second precision and a burst of screenshots can easily
/// share a `createdAt`. With date alone the tie order (and therefore which
/// rows a `limit` page selects) can shift between runs, re-serving one row
/// while another is never picked up; `id` makes the sequence deterministic.
/// The query mirrors this with `sortByCreatedAt().thenById()`.
@visibleForTesting
int compareUnprocessedOrder(ScreenshotModel a, ScreenshotModel b) {
  final byDate = a.createdAt.compareTo(b.createdAt);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}

class ScreenshotRepository {
  final Isar db = DatabaseService.db;

  Future<List<ScreenshotItem>> getAllScreenshots({String? category}) async {
    final query = db.screenshotModels.where();
    final models = await (category != null
        ? query.filter().categoryEqualTo(category).findAll()
        : query.findAll());
    debugPrint(
      '[ScreenshotRepo] getAllScreenshots() returning ${models.length} items (category=$category)',
    );
    return models.map(_toItem).toList();
  }

  Future<ScreenshotItem?> getScreenshotById(int id) async {
    final model = await db.screenshotModels.get(id);
    return model != null ? _toItem(model) : null;
  }

  Future<int> saveScreenshot(ScreenshotModel model) async {
    return db.writeTxn(() => db.screenshotModels.put(model));
  }

  Future<void> updateCategory(int id, String category) async {
    await db.writeTxn(() async {
      final model = await db.screenshotModels.get(id);
      if (model != null) {
        model.category = category;
        await db.screenshotModels.put(model);
      }
    });
  }

  Future<void> updateExtractedText(int id, String text) async {
    await db.writeTxn(() async {
      final model = await db.screenshotModels.get(id);
      if (model != null) {
        model.extractedText = text;
        model.isProcessed = true;
        await db.screenshotModels.put(model);
      }
    });
  }

  Future<void> markAsExpense(int id, bool isExpense) async {
    await db.writeTxn(() async {
      final model = await db.screenshotModels.get(id);
      if (model != null) {
        model.isExpense = isExpense;
        await db.screenshotModels.put(model);
      }
    });
  }

  /// Deletes one screenshot row and the expense rows derived from it.
  ///
  /// `ExpenseModel.screenshotId` is a plain id with no Isar backlink, so the
  /// dependent rows do not cascade automatically; deleting the screenshot
  /// without them strands expenses that reference a missing row. Doing the
  /// sweep inside this method keeps the repository's contract sound even when
  /// a caller bypasses the provider-level cascade.
  Future<void> deleteScreenshot(int id) async {
    await db.writeTxn(() async {
      await db.expenseModels.filter().screenshotIdEqualTo(id).deleteAll();
      await db.screenshotModels.delete(id);
    });
  }

  Future<List<ScreenshotItem>> searchScreenshots(String query) async {
    if (query.isEmpty) return getAllScreenshots();
    final lowerQuery = query.toLowerCase();
    final all = await getAllScreenshots();
    return all.where((item) {
      return item.categoryDisplay.toLowerCase().contains(lowerQuery) ||
          (item.extractedText?.toLowerCase().contains(lowerQuery) ?? false) ||
          item.filePath.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<int> getScreenshotCount() async {
    return await db.screenshotModels.count();
  }

  /// Case-insensitive substring search restricted to [extractedText].
  Future<List<ScreenshotItem>> searchExtractedText(String query) async {
    if (query.trim().isEmpty) return const [];
    final models = await db.screenshotModels
        .filter()
        .extractedTextContains(query.trim(), caseSensitive: false)
        .findAll();
    return models.map(_toItem).toList();
  }

  /// All screenshots with the given [category].
  Future<List<ScreenshotItem>> getScreenshotsByCategory(String category) async {
    final models = await db.screenshotModels
        .filter()
        .categoryEqualTo(category)
        .findAll();
    return models.map(_toItem).toList();
  }

  /// Screenshots whose [ScreenshotModel.createdAt] falls inside
  /// `[start, end]` (inclusive).
  Future<List<ScreenshotItem>> getScreenshotsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final models = await db.screenshotModels
        .filter()
        .createdAtBetween(start, end)
        .findAll();
    return models.map(_toItem).toList();
  }

  /// Queue of screenshots that still need OCR/categorization processing.
  ///
  /// Sorted oldest first with `id` as a stable secondary key (see
  /// [compareUnprocessedOrder]): the limit means a total order decides which
  /// tied rows make the cut. `isProcessed` is a non-nullable Isar bool, so
  /// `EqualTo(false)` cannot miss NULL rows — there is no NULL state to miss.
  Future<List<ScreenshotItem>> getUnprocessedScreenshots({int? limit}) async {
    final query = db.screenshotModels
        .filter()
        .isProcessedEqualTo(false)
        .sortByCreatedAt()
        .thenById();
    final models = limit != null
        ? await query.limit(limit).findAll()
        : await query.findAll();
    return models.map(_toItem).toList();
  }

  /// Monthly upload counts for a dashboard, between [from] and [to]
  /// (inclusive, month granularity). Months without uploads are returned
  /// as zero-count buckets (gap filling delegated to [AnalyticsService]).
  Future<List<MonthlyBucket>> getMonthlyCounts({
    required DateTime from,
    DateTime? to,
  }) async {
    final models = await db.screenshotModels.where().findAll();
    return AnalyticsService.monthlyScreenshotSeries(models, from: from, to: to);
  }

  /// Deletes screenshot rows whose file path is not present in
  /// [existingFilePaths], plus the expense rows derived from them — the bulk
  /// `deleteAll` does not cascade, so without the second sweep the orphan
  /// cleanup would simply trade orphaned screenshots for orphaned expenses.
  /// Accepting the existing-paths set as a parameter keeps this method free
  /// of filesystem/plugin dependencies and testable.
  /// Returns the number of orphaned screenshot rows deleted.
  Future<int> deleteOrphanedScreenshots(Set<String> existingFilePaths) async {
    final all = await db.screenshotModels.where().findAll();
    final orphanIds = orphanedScreenshotRowIds(existingFilePaths, all);
    if (orphanIds.isEmpty) return 0;
    await db.writeTxn(() async {
      await db.screenshotModels.deleteAll(orphanIds);
      final expenses = await db.expenseModels.where().findAll();
      final expenseIds = orphanedExpenseRowIds(orphanIds.toSet(), expenses);
      if (expenseIds.isNotEmpty) {
        await db.expenseModels.deleteAll(expenseIds);
      }
    });
    debugPrint(
      '[ScreenshotRepo] deleteOrphanedScreenshots() removed '
      '${orphanIds.length} rows and cascaded their expense rows',
    );
    return orphanIds.length;
  }

  ScreenshotItem _toItem(ScreenshotModel model) {
    return ScreenshotItem(
      id: model.id,
      filePath: model.filePath,
      thumbnailPath: model.thumbnailPath,
      extractedText: model.extractedText,
      category: model.category,
      createdAt: model.createdAt,
      fileSize: model.fileSize,
      isProcessed: model.isProcessed,
      isExpense: model.isExpense,
    );
  }
}
