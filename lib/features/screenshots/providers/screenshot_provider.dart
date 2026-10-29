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
import '../../categories/providers/category_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../settings/providers/settings_provider.dart';

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

/// Rows the database holds but has never finished enriching.
///
/// A scan only processes files whose path is *unknown* to the database, so a
/// row whose OCR/categorization failed would never be touched again without
/// this retry queue (its file is known by then). Rows without a usable path
/// are left out: they cannot be re-opened as a [File], and queueing them
/// would fail — and be counted as a failure — on every single scan.
@visibleForTesting
List<ScreenshotItem> unprocessedRows(Iterable<ScreenshotItem> items) {
  return items
      .where((item) => !item.isProcessed && item.filePath.isNotEmpty)
      .toList();
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

/// Whether a scheduled auto-scan may run right now.
///
/// Pure gate over [AppSettings]: auto scan is off whenever the user disabled
/// it, and the interval since [lastAutoScanAt] has not elapsed yet. A missing
/// stamp (first run after launch) is always due, and a clock that moved
/// backwards re-arms the scan instead of freezing it for a full interval.
@visibleForTesting
bool isAutoScanDue({
  required bool enabled,
  required int intervalHours,
  required DateTime? lastAutoScanAt,
  required DateTime now,
}) {
  if (!enabled) return false;
  if (lastAutoScanAt == null) return true;
  final elapsed = now.difference(lastAutoScanAt);
  if (elapsed.isNegative) return true;
  return elapsed >= Duration(hours: intervalHours);
}

/// Outcome counters of one [ScanScreenshotsNotifier.scan] pass.
@immutable
class ScanOutcome {
  const ScanOutcome({
    this.databaseReady = true,
    this.discovered = 0,
    this.persisted = 0,
    this.reprocessed = 0,
    this.duplicatesSkipped = 0,
    this.failures = 0,
  });

  /// Pass-through used by the ready guard so an aborted scan still returns a
  /// well-formed outcome.
  const ScanOutcome.aborted()
    : databaseReady = false,
      discovered = 0,
      persisted = 0,
      reprocessed = 0,
      duplicatesSkipped = 0,
      failures = 0;

  /// False when the scan refused to run because Isar was never opened.
  final bool databaseReady;

  /// Files the scanner reported before dedupe.
  final int discovered;

  /// Rows inserted into the database.
  final int persisted;

  /// Previously stored rows whose failed enrichment was retried successfully.
  final int reprocessed;

  /// Files already present in the database.
  final int duplicatesSkipped;

  /// Files whose processing threw and were isolated from the rest of the run.
  final int failures;

  bool get wasAborted => !databaseReady;

  /// Whether stored data changed, i.e. whether cached lists and counts must
  /// refresh. Retried enrichments count too: they write new categories and
  /// expense rows even though no file was persisted.
  bool get changedAnything => persisted > 0 || reprocessed > 0;

  @override
  String toString() =>
      'ScanOutcome(databaseReady: $databaseReady, discovered: $discovered, '
      'persisted: $persisted, reprocessed: $reprocessed, '
      'duplicatesSkipped: $duplicatesSkipped, failures: $failures)';
}

/// Invalidates every provider cache computed from the screenshot/expense
/// tables.
///
/// A scan (persist, enrich, retry) and a delete mutate those tables directly;
/// any cache left out here keeps serving pre-mutation data until an unrelated
/// refresh happens to fire. That previously affected the category badges
/// ([categoryCountsProvider]) and per-category listings
/// ([screenshotsByCategoryProvider]) after scans and deletes, and the expense
/// dashboard ([expenseListProvider]) after deletes removed the screenshot's
/// expense rows.
///
/// The per-screenshot detail cache ([screenshotDetailProvider]) was the next
/// gap: it is a non-autoDispose family, so a detail screen opened *before* a
/// retry pass re-enriched that row (or *before* the row was deleted) kept
/// showing the stale pre-scan category/text — or the deleted screenshot —
/// until the manual retry was tapped.
void _invalidateMutationCaches(Ref ref) {
  ref.invalidate(screenshotListProvider);
  ref.invalidate(screenshotDetailProvider);
  ref.invalidate(homeStatsProvider);
  ref.invalidate(categoryCountsProvider);
  ref.invalidate(screenshotsByCategoryProvider);
  ref.invalidate(expenseListProvider);
}

/// Imports new screenshots from the device gallery and runs OCR on them.
///
/// Guarantees, in order of importance:
/// * the [OcrService] (a native ML Kit recognizer holding a camera-vision
///   handle) is disposed on **every** exit path, including errors thrown
///   mid-loop, via `try/finally`;
/// * a failure on one file is logged and counted in [ScanOutcome.failures],
///   and never aborts the batch nor discards the row already written for that
///   file. The row stays queued (`isProcessed == false`) and the *next* scan
///   re-enriches it through the [unprocessedRows] retry queue — scans only
///   look at unknown files, so without that queue a failed row would be
///   stranded forever and the home unprocessed count could never reach zero;
/// * `scanningProvider` is always reset, cached lists are only invalidated
///   when work actually landed, and Isar access is gated by the
///   `DatabaseService.isInitialized` ready check instead of relying on the
///   `db` getter to throw.
class ScanScreenshotsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// True while a [scan] pass is running. Without this gate two overlapping
  /// passes (the lifecycle `scanIfDue` fired on app resume while the user
  /// taps Scan on home or settings) each snapshot `stored` before either
  /// writes: the duplicate check in [_persistNewScreenshot] is a
  /// find-then-insert with no atomicity between the two, so both passes can
  /// insert a row for the same file — and the first pass to finish flips
  /// `scanningProvider` off while the other is still working.
  bool _scanInFlight = false;

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

    if (_scanInFlight) {
      debugPrint('[ScanNotifier] Skipped: another scan is already running');
      return;
    }

    ref.read(scanningProvider.notifier).state = true;
    // Set only after the flag write above succeeded, and cleared in the
    // `finally` below, so an aborted pass can never strand later scans.
    _scanInFlight = true;
    OcrService? ocrService;
    var discovered = 0;
    var persisted = 0;
    var reprocessed = 0;
    var duplicatesSkipped = 0;
    var failures = 0;
    var outcome = const ScanOutcome();
    try {
      final repo = ref.read(screenshotRepositoryProvider);

      // One stored snapshot feeds both the scanner pre-filter and the retry
      // queue, so rows persisted earlier in this same pass are never picked
      // up twice.
      final stored = await repo.getAllScreenshots();
      final knownPaths = knownFilePaths(stored);
      final pending = unprocessedRows(stored);

      // Hand the already-known paths to the scanner so it can skip resolving
      // them; the per-file check below stays as a cheap correctness guard
      // against races between concurrent scans.
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

      // Retry queue: enrichment failures from previous passes left these
      // rows isProcessed == false; their files are known now, so this is the
      // only path that ever processes them again.
      for (final row in pending) {
        try {
          await _enrichWithOcr(repo, ocrService, File(row.filePath), row.id);
          reprocessed++;
        } catch (e, st) {
          failures++;
          debugPrint(
            '[ScanNotifier] Retry error for id=${row.id} '
            '(${row.filePath}): $e\n$st',
          );
        }
      }

      outcome = ScanOutcome(
        discovered: discovered,
        persisted: persisted,
        reprocessed: reprocessed,
        duplicatesSkipped: duplicatesSkipped,
        failures: failures,
      );
      debugPrint('[ScanNotifier] Scan complete. $outcome');
      final totalInDb = await DatabaseService.db.screenshotModels.count();
      debugPrint(
        '[ScanNotifier] Total screenshots in DB after scan: $totalInDb',
      );

      if (outcome.changedAnything) {
        _invalidateMutationCaches(ref);
        debugPrint(
          '[ScanNotifier] Invalidated screenshot, home, category and expense caches',
        );
      }
      _publishState(const AsyncData<void>(null));
    } catch (e, st) {
      debugPrint('[ScanNotifier] scan() error: $e\n$st');
      outcome = ScanOutcome(
        discovered: discovered,
        persisted: persisted,
        reprocessed: reprocessed,
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

  /// The exact cache invalidation [scan] performs when a pass changed stored
  /// data. Exposed so tests can pin the invalidated provider set down.
  @visibleForTesting
  void invalidateMutationCaches() => _invalidateMutationCaches(ref);

  DateTime? _lastAutoScanAt;

  /// When the gated [scanIfDue] last let a pass through, for cadence checks.
  DateTime? get lastAutoScanAt => _lastAutoScanAt;

  /// Background/scheduled entry point honoring [AppSettings].
  ///
  /// Runs [scan] only when the user enabled auto scan and the configured
  /// interval elapsed since the previous pass. The stamp advances before the
  /// scan even if it aborts (e.g. database not ready) so a failing cadence
  /// check cannot storm the gallery with retries inside one interval.
  Future<bool> scanIfDue({DateTime? now}) async {
    final settings = ref.read(settingsProvider);
    final reference = now ?? DateTime.now();
    if (!isAutoScanDue(
      enabled: settings.autoScanEnabled,
      intervalHours: settings.scanIntervalHours,
      lastAutoScanAt: _lastAutoScanAt,
      now: reference,
    )) {
      debugPrint('[ScanNotifier] Auto-scan not due yet; skipping');
      return false;
    }
    _lastAutoScanAt = reference;
    await scan();
    return true;
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
  /// Throws to the caller on any failure so the per-file isolation counts it
  /// in [ScanOutcome.failures] (swallowing here previously made enrichment
  /// failures invisible while still claiming a clean scan). The row keeps
  /// `isProcessed == false` whenever OCR or categorization fails — the write
  /// that flips the flag is sequenced last — so the next scan's
  /// [unprocessedRows] queue retries it.
  Future<void> _enrichWithOcr(
    ScreenshotRepository repo,
    OcrService ocrService,
    File file,
    int id,
  ) async {
    final text = await ocrService.extractTextFromFile(file);
    debugPrint('[ScanNotifier] OCR text length=${text.length} for id=$id');

    final category = CategorizationService.categorize(text);
    debugPrint('[ScanNotifier] Category="$category" for id=$id');
    await repo.updateCategory(id, category);

    if (CategorizationService.isExpense(text)) {
      await repo.markAsExpense(id, true);
      // Existence guard: a retry pass re-OCRs the same row after a crash
      // between the expense write and the flag write below, and
      // [ExpenseExtractionService.extractExpense] mints a fresh auto-increment
      // row every call — without this check the retry would duplicate the
      // expense on the dashboard.
      final existingExpense = await DatabaseService.db.expenseModels
          .filter()
          .screenshotIdEqualTo(id)
          .findFirst();
      if (existingExpense == null) {
        final expense = ExpenseExtractionService.extractExpense(text, id);
        await DatabaseService.db.writeTxn(
          () => DatabaseService.db.expenseModels.put(expense),
        );
      }
      debugPrint('[ScanNotifier] Marked as expense id=$id');
    }

    // Marks the row processed; sequenced strictly last — including after the
    // expense branch — so a failure (or a process kill) at any earlier step
    // leaves the row queued for the next scan's [unprocessedRows] retry. The
    // previous order flipped the flag before the expense writes, so an
    // interrupted payment screenshot was silently never turned into an
    // expense and no retry could ever recover it.
    await repo.updateExtractedText(id, text);
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
  _invalidateMutationCaches(ref);
  debugPrint('[DeleteProvider] Deleted screenshot id=$id (caches invalidated)');
});
