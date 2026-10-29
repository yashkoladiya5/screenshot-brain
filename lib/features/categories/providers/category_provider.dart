import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';

/// Canonical category vocabulary shared across the app. Must stay aligned
/// with `CategorizationService` output labels.
const List<String> kCategoryList = [
  'Payments',
  'UPI Receipts',
  'Shopping',
  'Travel Tickets',
  'Bills',
  'Documents',
  'OTP Screenshots',
  'Addresses',
  'Notes',
  'Social Media',
  'Other',
];

/// Bucket that receives screenshots which have not been categorized yet.
const String kUncategorizedBucket = 'Other';

/// Category a stored row belongs to: uncategorized rows (`category == null`)
/// and blank/padded labels live in the `Other` bucket. Trimming (and folding
/// empties) is what every other surface already promises —
/// `ScreenshotItem.categoryDisplay`, `ExpenseSnapshot.byCategory` and
/// `AnalyticsService` all normalize on the trimmed value; without it a row
/// saved with `category: ''` was counted under a nameless bucket and the
/// Categories screen rendered a card whose title was literally blank.
String effectiveCategoryOf(String? storedCategory) {
  final trimmed = (storedCategory ?? '').trim();
  return trimmed.isEmpty ? kUncategorizedBucket : trimmed;
}

/// Counts rows by [effectiveCategoryOf], the same bucketing the category
/// badges promise. Kept pure so the count/query symmetry can be tested
/// without a database.
Map<String, int> countByBucket(Iterable<String?> storedCategories) {
  final counts = <String, int>{};
  for (final stored in storedCategories) {
    final bucket = effectiveCategoryOf(stored);
    counts[bucket] = (counts[bucket] ?? 0) + 1;
  }
  return counts;
}

/// Whether the listing for [bucket] must also return uncategorized rows.
/// The `Other` badge counts those rows, so its query has to include them;
/// every other bucket matches only its exact label.
bool bucketQueryIncludesNulls(String bucket) => bucket == kUncategorizedBucket;

/// Whether a stored row counted into [bucket] is returned by that bucket's
/// listing — the symmetry contract between [categoryCountsProvider] and
/// [screenshotsByCategoryProvider].
bool screenshotMatchesBucket(String? storedCategory, String bucket) =>
    effectiveCategoryOf(storedCategory) == bucket;

/// Orders raw category counts for display: most screenshots first, then by
/// the canonical vocabulary order, then alphabetically for unknown extras.
///
/// When [includeEmpty] is true, every canonical category appears even with a
/// zero count; counts for categories outside [canonical] are kept regardless.
Map<String, int> orderCategoryCounts(
  Map<String, int> raw, {
  List<String> canonical = kCategoryList,
  bool includeEmpty = false,
}) {
  final entries = <String, int>{};
  if (includeEmpty) {
    for (final category in canonical) {
      entries[category] = raw[category] ?? 0;
    }
  }
  for (final entry in raw.entries) {
    if (entry.value > 0 || !includeEmpty) {
      entries[entry.key] = entry.value;
    }
  }

  int canonicalRank(String category) {
    final index = canonical.indexOf(category);
    return index == -1 ? canonical.length : index;
  }

  final ordered = entries.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      final byCanonical =
          canonicalRank(a.key).compareTo(canonicalRank(b.key));
      if (byCanonical != 0) return byCanonical;
      return a.key.compareTo(b.key);
    });
  return Map<String, int>.fromEntries(ordered);
}

final categoryListProvider = Provider<List<String>>((ref) {
  return kCategoryList;
});

final categoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = DatabaseService.db;
  final all = await db.screenshotModels.where().findAll();
  final counts = countByBucket(all.map((screenshot) => screenshot.category));
  return orderCategoryCounts(counts);
});

final screenshotsByCategoryProvider =
    FutureProvider.family<List<ScreenshotModel>, String>((ref, category) {
  final db = DatabaseService.db;
  final filter = db.screenshotModels.filter().categoryEqualTo(category);
  // Uncategorized rows are counted in the `Other` badge, so the `Other`
  // listing must include them; otherwise the card promises screenshots
  // the screen then fails to show.
  final query = bucketQueryIncludesNulls(category)
      ? filter.or().categoryIsNull()
      : filter;
  return query.sortByCreatedAtDesc().findAll();
});
