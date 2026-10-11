import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/categorization_service.dart';
import '../../../services/database_service.dart';
import '../../../services/expense_extraction_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/screenshot_scanner_service.dart';
import '../../../shared/models/expense_model.dart';
import '../../../shared/models/screenshot_model.dart';
import '../models/screenshot_item.dart';
import '../repositories/screenshot_repository.dart';
import '../../home/providers/home_provider.dart';

final screenshotRepositoryProvider = Provider<ScreenshotRepository>((ref) {
  return ScreenshotRepository();
});

final screenshotListProvider = FutureProvider<List<ScreenshotItem>>((
  ref,
) async {
  final repo = ref.read(screenshotRepositoryProvider);
  final items = await repo.getAllScreenshots();
  debugPrint(
    '[ScreenshotListProvider] Returning ${items.length} screenshots from DB',
  );
  return items;
});

final screenshotDetailProvider = FutureProvider.family<ScreenshotItem?, int>((
  ref,
  id,
) async {
  final repo = ref.read(screenshotRepositoryProvider);
  return repo.getScreenshotById(id);
});

final searchScreenshotsProvider =
    FutureProvider.family<List<ScreenshotItem>, String>((ref, query) async {
      final repo = ref.read(screenshotRepositoryProvider);
      return repo.searchScreenshots(query);
    });

final scanningProvider = StateProvider<bool>((ref) => false);

/// Paths the database already persists — the input the scanner needs so it can
/// drop known assets before touching photo_manager.
///
/// Blank paths are ignored so a half-written row can never mask a real file.
@visibleForTesting
Set<String> knownFilePaths(Iterable<ScreenshotItem> items) {
  return {
    for (final item in items)
      if (item.filePath.isNotEmpty) item.filePath,
  };
}

/// Pure pre-filter over scanner output: keeps files whose path is not already
/// known. Order (newest first, as produced by the scanner) is preserved.
@visibleForTesting
List<File> filesNotIn(List<File> discovered, Set<String> knownPaths) {
  if (knownPaths.isEmpty) return discovered;
  return discovered.where((file) => !knownPaths.contains(file.path)).toList();
}

/// Builds the fresh [ScreenshotModel] row for a discovered file.
///
/// Kept side-effect free (and `@visibleForTesting`) so the persistence shape
/// of a scan is unit-testable without Isar or photo_manager. A new row is
/// always unprocessed and non-expense: those flags are only set after OCR and
/// categorization succeed.
@visibleForTesting
ScreenshotModel newScreenshotModel({
  required String filePath,
  required DateTime modified,
  required int sizeInBytes,
}) {
  return ScreenshotModel()
    ..filePath = filePath
    ..createdAt = modified
    ..fileSize = sizeInBytes
    ..isProcessed = false
    ..isExpense = false;
}

/// Outcome counters of one [ScanScreenshotsNotifier.scan] pass.
@immutable
class ScanOutcome {
  const ScanOutcome({
    this.databaseReady = true,
    this.discovered = 0,
    this.persisted = 0,
    this.duplicatesSkipped = 0,
    this.failures = 0,
  });

  /// Pass-through used by the ready guard so an aborted scan still returns a
  /// well-formed outcome.
  const ScanOutcome.aborted()
    : databaseReady = false,
      discovered = 0,
      persisted = 0,
      duplicatesSkipped = 0,
      failures = 0;

  /// False when the scan refused to run because Isar was never opened.
  final bool databaseReady;

  /// Files the scanner reported before dedupe.
  final int discovered;

  /// Rows inserted into the database.
  final int persisted;

  /// Files already present in the database.
  final int duplicatesSkipped;

  /// Files whose processing threw and were isolated from the rest of the run.
  final int failures;

  bool get wasAborted => !databaseReady;

  /// Whether anything new landed, i.e. whether cached lists must refresh.
  bool get changedAnything => persisted > 0;

  @override
  String toString() =>
      'ScanOutcome(databaseReady: $databaseReady, discovered: $discovered, '
      'persisted: $persisted, duplicatesSkipped: $duplicatesSkipped, '
      'failures: $failures)';
}

/// Imports new screenshots from the device gallery and runs OCR on them.
///
/// Guarantees, in order of importance:
/// * the [OcrService] (a native ML Kit recognizer holding a camera-vision
///   handle) is disposed on **every** exit path, including errors thrown
///   mid-loop, via `try/finally`;
/// * a failure on one file is logged and counted, and never aborts the batch
///   nor discards the row already written for that file — OCR/categorization
///   errors are isolated a second time inside the row so the screenshot stays
///   queued (`isProcessed == false`) for a later retry;
/// * `scanningProvider` is always reset, cached lists are only invalidated
///   when work actually landed, and Isar access is gated by the
///   `DatabaseService.isInitialized` ready check instead of relying on the
///   `db` getter to throw.
class ScanScreenshotsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Scans the gallery for new screenshots and runs OCR on them.
  ///
  /// Never throws to the UI (screens fire this and forget it): per-file
  /// failures are logged and counted, batch failures additionally surface as
  /// the provider's `AsyncError` state, and the counters of the pass are
  /// summarised through [ScanOutcome] in the log.
  Future<void> scan() async {
    debugPrint('[ScanNotifier] scan() started');
    if (!DatabaseService.isInitialized) {
      debugPrint(
        '[ScanNotifier] Aborted: database not initialized '
        '(call DatabaseService.init() first) ${const ScanOutcome.aborted()}',
      );
      return;
    }

    ref.read(scanningProvider.notifier).state = true;
    OcrService? ocrService;
    var discovered = 0;
    var persisted = 0;
    var duplicatesSkipped = 0;
    var failures = 0;
    var outcome = const ScanOutcome();
    try {
      final repo = ref.read(screenshotRepositoryProvider);

      // Hand the already-known paths to the scanner so it can skip resolving
      // them; the per-file check below stays as a cheap correctness guard
      // against races between concurrent scans.
      final knownPaths = knownFilePaths(await repo.getAllScreenshots());
      final files = await ScreenshotScannerService.scanScreenshots(
        knownPaths: knownPaths,
      );
      discovered = files.length;
      debugPrint('[ScanNotifier] scanScreenshots returned $discovered files');

      ocrService = OcrService();

      for (final file in filesNotIn(files, knownPaths)) {
        try {
          final id = await _persistNewScreenshot(repo, file);
          if (id == null) {
            duplicatesSkipped++;
            continue;
          }

          persisted++;
          await _enrichWithOcr(repo, ocrService, file, id);
        } catch (e, st) {
          // Per-file isolation: a broken/unreadable file must not stop the
          // remaining screenshots from being imported.
          failures++;
          debugPrint('[ScanNotifier] File error for ${file.path}: $e\n$st');
        }
      }

      outcome = ScanOutcome(
        discovered: discovered,
        persisted: persisted,
        duplicatesSkipped: duplicatesSkipped,
        failures: failures,
      );
      debugPrint('[ScanNotifier] Scan complete. $outcome');
      final totalInDb = await DatabaseService.db.screenshotModels.count();
      debugPrint(
        '[ScanNotifier] Total screenshots in DB after scan: $totalInDb',
      );

      if (outcome.changedAnything) {
        ref.invalidate(screenshotListProvider);
        ref.invalidate(homeStatsProvider);
        debugPrint(
          '[ScanNotifier] Invalidated screenshotListProvider and homeStatsProvider',
        );
      }
      _publishState(const AsyncData<void>(null));
    } catch (e, st) {
      debugPrint('[ScanNotifier] scan() error: $e\n$st');
      outcome = ScanOutcome(
        discovered: discovered,
        persisted: persisted,
        duplicatesSkipped: duplicatesSkipped,
        failures: failures + 1,
      );
      _publishState(AsyncError<void>(e, st));
    } finally {
      // Guaranteed release of the native text recognizer on success, on a
      // per-file error, and on any top-level failure of the scan itself.
      ocrService?.dispose();
      ref.read(scanningProvider.notifier).state = false;
      debugPrint('[ScanNotifier] scan() finished');
    }
  }

  /// Sets [state] unless the container went away while the scan was running
  /// (a long OCR batch outliving the screen that started it is normal).
  void _publishState(AsyncValue<void> value) {
    try {
      state = value;
    } catch (e) {
      debugPrint('[ScanNotifier] Could not publish state: $e');
    }
  }

  /// Inserts the row for [file] unless the exact path is already stored.
  /// Returns the new id, or null when the file was a duplicate.
  Future<int?> _persistNewScreenshot(
    ScreenshotRepository repo,
    File file,
  ) async {
    final stat = await file.stat();
    final existing = await DatabaseService.db.screenshotModels
        .filter()
        .filePathEqualTo(file.path)
        .findFirst();
    if (existing != null) {
      debugPrint('[ScanNotifier] Skipping duplicate: ${file.path}');
      return null;
    }

    debugPrint('[ScanNotifier] New file: ${file.path}');
    final id = await repo.saveScreenshot(
      newScreenshotModel(
        filePath: file.path,
        modified: stat.modified,
        sizeInBytes: stat.size,
      ),
    );
    debugPrint('[ScanNotifier] Saved screenshot id=$id filePath=${file.path}');
    return id;
  }

  /// OCR + categorization + expense extraction for one stored row.
  ///
  /// Failures here are contained: the screenshot row stays in the database
  /// flagged `isProcessed == false` so the unprocessed queue picks it up on a
  /// later scan.
  Future<void> _enrichWithOcr(
    ScreenshotRepository repo,
    OcrService ocrService,
    File file,
    int id,
  ) async {
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
        await DatabaseService.db.writeTxn(
          () => DatabaseService.db.expenseModels.put(expense),
        );
        debugPrint('[ScanNotifier] Marked as expense id=$id');
      }
    } catch (e) {
      debugPrint('[ScanNotifier] OCR/categorize error for $id: $e');
    }
  }
}

final scanScreenshotsProvider =
    AsyncNotifierProvider<ScanScreenshotsNotifier, void>(() {
      return ScanScreenshotsNotifier();
    });

final deleteScreenshotProvider = FutureProvider.family<void, int>((
  ref,
  id,
) async {
  final repo = ref.read(screenshotRepositoryProvider);
  final db = DatabaseService.db;
  await db.writeTxn(
    () => db.expenseModels.filter().screenshotIdEqualTo(id).deleteAll(),
  );
  await repo.deleteScreenshot(id);
  ref.invalidate(screenshotListProvider);
  ref.invalidate(homeStatsProvider);
  debugPrint('[DeleteProvider] Deleted screenshot id=$id');
});
