import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ScreenshotModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final db = DatabaseService.db;
  final lowerQuery = query.toLowerCase();

  final all = await db.screenshotModels.where().findAll();
  return all.where((s) {
    return (s.extractedText?.toLowerCase().contains(lowerQuery) ?? false) ||
        s.filePath.toLowerCase().contains(lowerQuery) ||
        (s.category?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();
});

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
