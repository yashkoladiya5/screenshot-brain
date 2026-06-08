import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';

final categoryListProvider = Provider<List<String>>((ref) {
  return [
    'Payments', 'UPI Receipts', 'Shopping', 'Travel Tickets', 'Bills',
    'Documents', 'OTP Screenshots', 'Addresses', 'Notes', 'Social Media', 'Other',
  ];
});

final categoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = DatabaseService.db;
  final all = await db.screenshotModels.where().findAll();
  final counts = <String, int>{};
  for (final s in all) {
    final cat = s.category ?? 'Other';
    counts[cat] = (counts[cat] ?? 0) + 1;
  }
  return counts;
});

final screenshotsByCategoryProvider = FutureProvider.family<List<ScreenshotModel>, String>((ref, category) async {
  final db = DatabaseService.db;
  return db.screenshotModels.filter().categoryEqualTo(category).findAll();
});
