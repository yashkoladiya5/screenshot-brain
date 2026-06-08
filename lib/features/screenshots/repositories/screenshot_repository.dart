import 'package:isar/isar.dart';
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
    return models.map(_toItem).toList();
  }

  Future<ScreenshotItem?> getScreenshotById(int id) async {
    final model = await db.screenshotModels.get(id);
    return model != null ? _toItem(model) : null;
  }

  Future<int> saveScreenshot(ScreenshotModel model) async {
    return db.screenshotModels.put(model);
  }

  Future<void> updateCategory(int id, String category) async {
    final model = await db.screenshotModels.get(id);
    if (model != null) {
      model.category = category;
      await db.screenshotModels.put(model);
    }
  }

  Future<void> updateExtractedText(int id, String text) async {
    final model = await db.screenshotModels.get(id);
    if (model != null) {
      model.extractedText = text;
      model.isProcessed = true;
      await db.screenshotModels.put(model);
    }
  }

  Future<void> markAsExpense(int id, bool isExpense) async {
    final model = await db.screenshotModels.get(id);
    if (model != null) {
      model.isExpense = isExpense;
      await db.screenshotModels.put(model);
    }
  }

  Future<void> deleteScreenshot(int id) async {
    await db.screenshotModels.delete(id);
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
