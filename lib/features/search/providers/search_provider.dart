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

/// Case-insensitive substring match against extracted text, file path and
/// category. An empty [normalizedQuery] never matches (callers keep their
/// last results instead of re-querying).
bool screenshotMatchesQuery(
  ScreenshotModel screenshot,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return false;
  return (screenshot.extractedText?.toLowerCase().contains(normalizedQuery) ??
          false) ||
      screenshot.filePath.toLowerCase().contains(normalizedQuery) ||
      (screenshot.category?.toLowerCase().contains(normalizedQuery) ?? false);
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
/// - Queries are normalized (trim / collapse whitespace / lowercase).
/// - Empty or whitespace-only queries keep the last non-empty results.
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

    // Any error propagates and becomes AsyncError on this provider.
    final results = await ref.read(screenshotSearcherProvider)(currentQuery);
    _lastResults = results;
    return results;
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
