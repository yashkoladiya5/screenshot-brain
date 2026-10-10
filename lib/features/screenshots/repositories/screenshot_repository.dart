import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../../services/analytics_service.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';
import '../models/screenshot_item.dart';

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

  Future<void> deleteScreenshot(int id) async {
    await db.writeTxn(() => db.screenshotModels.delete(id));
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
  Future<List<ScreenshotItem>> getUnprocessedScreenshots({int? limit}) async {
    final query = db.screenshotModels
        .filter()
        .isProcessedEqualTo(false)
        .sortByCreatedAt();
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
  /// [existingFilePaths]. Accepting the existing-paths set as a parameter
  /// keeps this method free of filesystem/plugin dependencies and testable.
  /// Returns the number of orphaned rows deleted.
  Future<int> deleteOrphanedScreenshots(Set<String> existingFilePaths) async {
    final all = await db.screenshotModels.where().findAll();
    final orphanIds = all
        .where((model) => !existingFilePaths.contains(model.filePath))
        .map((model) => model.id)
        .toList();
    if (orphanIds.isEmpty) return 0;
    await db.writeTxn(() => db.screenshotModels.deleteAll(orphanIds));
    debugPrint(
      '[ScreenshotRepo] deleteOrphanedScreenshots() removed ${orphanIds.length} rows',
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
