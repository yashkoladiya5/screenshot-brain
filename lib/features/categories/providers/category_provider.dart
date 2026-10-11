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
  final counts = <String, int>{};
  for (final screenshot in all) {
    final category = screenshot.category ?? 'Other';
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return orderCategoryCounts(counts);
});

final screenshotsByCategoryProvider =
    FutureProvider.family<List<ScreenshotModel>, String>((ref, category) {
  final db = DatabaseService.db;
  return db.screenshotModels
      .filter()
      .categoryEqualTo(category)
      .sortByCreatedAtDesc()
      .findAll();
});
