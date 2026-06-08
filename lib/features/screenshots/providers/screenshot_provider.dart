import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/categorization_service.dart';
import '../../../services/expense_extraction_service.dart';
import '../../../services/screenshot_scanner_service.dart';
import '../../../shared/models/screenshot_model.dart';
import '../../../shared/models/expense_model.dart';
import '../models/screenshot_item.dart';
import '../repositories/screenshot_repository.dart';
import '../../home/providers/home_provider.dart';

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  return ScreenshotRepository();
});

final screenshotListProvider = FutureProvider<List<ScreenshotItem>>((ref) async {
  final repo = ref.read(screenshotRepositoryProvider);
  final items = await repo.getAllScreenshots();
  debugPrint('[ScreenshotListProvider] Returning ${items.length} screenshots from DB');
  return items;
});

final screenshotDetailProvider = FutureProvider.family<ScreenshotItem?, int>((ref, id) async {
  final repo = ref.read(screenshotRepositoryProvider);
  return repo.getScreenshotById(id);
});

final searchScreenshotsProvider = FutureProvider.family<List<ScreenshotItem>, String>((ref, query) async {
  final repo = ref.read(screenshotRepositoryProvider);
  return repo.searchScreenshots(query);
});

final scanningProvider = StateProvider<bool>((ref) => false);

class ScanScreenshotsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> scan() async {
    debugPrint('[ScanNotifier] scan() started');
    ref.read(scanningProvider.notifier).state = true;
    try {
      final repo = ref.read(screenshotRepositoryProvider);
      final files = await ScreenshotScannerService.scanScreenshots();
      debugPrint('[ScanNotifier] scanScreenshots returned ${files.length} files');

      final ocrService = OcrService();
      int newScreenshots = 0;

      for (final file in files) {
        final stat = await file.stat();
        final existing = await DatabaseService.db.screenshotModels
            .filter()
            .filePathEqualTo(file.path)
            .findFirst();

        if (existing != null) {
          debugPrint('[ScanNotifier] Skipping duplicate: ${file.path}');
          continue;
        }

        debugPrint('[ScanNotifier] New file: ${file.path}');

        final model = ScreenshotModel();
        model.filePath = file.path;
        model.createdAt = stat.modified;
        model.fileSize = await file.length();
        model.isProcessed = false;
        model.isExpense = false;

        final id = await repo.saveScreenshot(model);
        debugPrint('[ScanNotifier] Saved screenshot id=$id filePath=${file.path}');
        newScreenshots++;

        try {
          final text = await ocrService.extractTextFromFile(file);
          debugPrint('[ScanNotifier] OCR text length=${text.length} for id=$id');
          await repo.updateExtractedText(id, text);

          final category = CategorizationService.categorize(text);
          debugPrint('[ScanNotifier] Category="$category" for id=$id');
          await repo.updateCategory(id, category);

          if (CategorizationService.isExpense(text)) {
            await repo.markAsExpense(id, true);
            final expense = ExpenseExtractionService.extractExpense(text, id);
            await DatabaseService.db.writeTxn(() => DatabaseService.db.expenseModels.put(expense));
            debugPrint('[ScanNotifier] Marked as expense id=$id');
          }
        } catch (e) {
          debugPrint('[ScanNotifier] OCR/categorize error for $id: $e');
        }
      }

      ocrService.dispose();
      debugPrint('[ScanNotifier] Scan complete. $newScreenshots new screenshots added.');

      final totalInDb = await DatabaseService.db.screenshotModels.count();
      debugPrint('[ScanNotifier] Total screenshots in DB after scan: $totalInDb');

      ref.invalidate(screenshotListProvider);
      ref.invalidate(homeStatsProvider);
      debugPrint('[ScanNotifier] Invalidated screenshotListProvider and homeStatsProvider');
    } catch (e) {
      debugPrint('[ScanNotifier] scan() error: $e');
    } finally {
      ref.read(scanningProvider.notifier).state = false;
      debugPrint('[ScanNotifier] scan() finished');
    }
  }
}

final scanScreenshotsProvider = AsyncNotifierProvider<ScanScreenshotsNotifier, void>(() {
  return ScanScreenshotsNotifier();
});

final deleteScreenshotProvider = FutureProvider.family<void, int>((ref, id) async {
  final repo = ref.read(screenshotRepositoryProvider);
  final db = DatabaseService.db;
  await db.writeTxn(() => db.expenseModels.filter().screenshotIdEqualTo(id).deleteAll());
  await repo.deleteScreenshot(id);
  ref.invalidate(screenshotListProvider);
  ref.invalidate(homeStatsProvider);
  debugPrint('[DeleteProvider] Deleted screenshot id=$id');
});
