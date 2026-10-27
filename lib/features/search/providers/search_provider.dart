import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';

/// How long search results wait for a "quiet" period before hitting the
/// database. Typing restarts this timer, so intermediate keystrokes never
/// reach the backend.
const Duration searchDebounceDuration = Duration(milliseconds: 300);

/// Normalizes a raw user query: trims, collapses consecutive whitespace into
/// single spaces and lowercases for case-insensitive matching.
String normalizeSearchQuery(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Case-insensitive matching against extracted text, file path and category.
/// The [normalizedQuery] must already be trimmed / whitespace-collapsed /
/// lowercased. Matching uses AND semantics per whitespace-separated token:
/// every token must appear somewhere in the screenshot (text, path or
/// category), but not necessarily as one contiguous phrase — "train ticket"
/// matches a booking screenshot whose file name says `train` and whose OCR
/// text says `ticket`. An empty [normalizedQuery] never matches (callers
/// keep their last results instead of re-querying).
bool screenshotMatchesQuery(
  ScreenshotModel screenshot,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return false;
  final text = screenshot.extractedText?.toLowerCase() ?? '';
  final path = screenshot.filePath.toLowerCase();
  final category = screenshot.category?.toLowerCase() ?? '';
  return normalizedQuery
      .split(' ')
      .every(
        (token) =>
            text.contains(token) ||
            path.contains(token) ||
            category.contains(token),
      );
}

/// Pure in-memory filtering used by both the default DB-backed searcher and
/// tests.
List<ScreenshotModel> filterScreenshotsByQuery(
  Iterable<ScreenshotModel> all,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return const [];
  return all.where((s) => screenshotMatchesQuery(s, normalizedQuery)).toList();
}

/// Data-source seam for [searchResultsProvider]. Overridable in tests so the
/// debounce/retry logic can be exercised without a running Isar database.
typedef ScreenshotSearcher =
    Future<List<ScreenshotModel>> Function(String normalizedQuery);

final screenshotSearcherProvider = Provider<ScreenshotSearcher>((ref) {
  return (normalizedQuery) async {
    final db = DatabaseService.db;
    final all = await db.screenshotModels.where().findAll();
    return filterScreenshotsByQuery(all, normalizedQuery);
  };
});

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced, error-aware search results.
///
/// - Every keystroke restarts a single [Timer]; the backend is only queried
///   once the user stops typing for [searchDebounceDuration].
/// - Queries are normalized (trim / collapse whitespace / lowercase) and
///   matched with per-word AND semantics (see [screenshotMatchesQuery]).
/// - Empty or whitespace-only queries keep the last non-empty results.
/// - Late responses or failures from abandoned queries are discarded.
/// - Backend failures surface as `AsyncError` instead of being swallowed.
class SearchResultsNotifier extends AsyncNotifier<List<ScreenshotModel>> {
  Timer? _debounceTimer;
  Completer<void>? _wake;
  int _buildId = 0;
  List<ScreenshotModel> _lastResults = const [];

  @override
  Future<List<ScreenshotModel>> build() async {
    final buildId = ++_buildId;
    final normalized = normalizeSearchQuery(ref.watch(searchQueryProvider));

    // Cancel/restart the debounce window on every keystroke and wake any
    // stale build awaiting its completer so it can exit early.
    _debounceTimer?.cancel();
    final previousWake = _wake;
    if (previousWake != null && !previousWake.isCompleted) {
      previousWake.complete();
    }

    if (normalized.isEmpty) {
      return _lastResults;
    }

    final wake = Completer<void>();
    _wake = wake;
    ref.onDispose(() {
      _debounceTimer?.cancel();
      if (!wake.isCompleted) {
        wake.complete();
      }
    });
    _debounceTimer = Timer(searchDebounceDuration, wake.complete);
    await wake.future;

    // A newer keystroke already started a fresher build; ignore this one.
    if (buildId != _buildId) return _lastResults;
    _debounceTimer?.cancel();

    // Re-read the query after the wait in case it changed while awaiting.
    final currentQuery = normalizeSearchQuery(ref.read(searchQueryProvider));
    if (currentQuery.isEmpty) return _lastResults;

    // The fetch is raced against newer keystrokes: a response (or failure)
    // that lands after a fresher build started belongs to an abandoned
    // query and must never become the current state nor the "last results"
    // an empty query would resurrect.
    try {
      final results = await ref.read(screenshotSearcherProvider)(currentQuery);
      if (buildId != _buildId) return _lastResults;
      _lastResults = results;
      return results;
    } catch (error) {
      if (buildId != _buildId) return _lastResults;
      // Surfaces as AsyncError on this provider; the screen shows a retry.
      rethrow;
    }
  }
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, List<ScreenshotModel>>(
      SearchResultsNotifier.new,
    );

final searchSuggestionsProvider = Provider<List<String>>((ref) {
  return [
    'Amazon order',
    'Train ticket',
    'Phone number',
    'Electricity bill',
    'UPI payment',
    'GPAY',
    'Address',
    'OTP',
    'Invoice',
    'Receipt',
  ];
});
