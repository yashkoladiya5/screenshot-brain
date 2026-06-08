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

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  return ScreenshotRepository();
});

final screenshotListProvider = FutureProvider<List<ScreenshotItem>>((ref) async {
  final repo = ref.read(screenshotRepositoryProvider);
  return repo.getAllScreenshots();
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
    ref.read(scanningProvider.notifier).state = true;
    try {
      final repo = ref.read(screenshotRepositoryProvider);
      final files = await ScreenshotScannerService.scanScreenshots();
      final ocrService = OcrService();
      
      for (final file in files) {
        final stat = await file.stat();
        final existing = await DatabaseService.db.screenshotModels
            .filter()
            .filePathEqualTo(file.path)
            .findFirst();
        
        if (existing != null) continue;
        
        final model = ScreenshotModel();
        model.filePath = file.path;
        model.createdAt = stat.modified;
        model.fileSize = await file.length();
        model.isProcessed = false;
        model.isExpense = false;
        
        final id = await repo.saveScreenshot(model);
        
        try {
          final text = await ocrService.extractTextFromFile(file);
          await repo.updateExtractedText(id, text);
          
          final category = CategorizationService.categorize(text);
          await repo.updateCategory(id, category);
          
          if (CategorizationService.isExpense(text)) {
            await repo.markAsExpense(id, true);
            final expense = ExpenseExtractionService.extractExpense(text, id);
            await DatabaseService.db.expenseModels.put(expense);
          }
        } catch (_) {}
      }
      
      ocrService.dispose();
    } finally {
      ref.read(scanningProvider.notifier).state = false;
    }
  }
}

final scanScreenshotsProvider = AsyncNotifierProvider<ScanScreenshotsNotifier, void>(() {
  return ScanScreenshotsNotifier();
});

final deleteScreenshotProvider = FutureProvider.family<void, int>((ref, id) async {
  final repo = ref.read(screenshotRepositoryProvider);
  await DatabaseService.db.expenseModels.filter().screenshotIdEqualTo(id).deleteAll();
  await repo.deleteScreenshot(id);
  ref.invalidate(screenshotListProvider);
});
