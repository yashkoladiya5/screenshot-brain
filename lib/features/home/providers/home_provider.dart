import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';
import '../../../shared/models/expense_model.dart';
import '../../expenses/models/expense_item.dart';
import '../../expenses/providers/expense_provider.dart';

class HomeStats {
  final int screenshotCount;
  final int expenseCount;
  final int unprocessedCount;
  final double totalExpenses;
  final List<ExpenseItem> recentExpenses;

  const HomeStats({
    required this.screenshotCount,
    required this.expenseCount,
    required this.unprocessedCount,
    required this.totalExpenses,
    required this.recentExpenses,
  });
}

final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final db = DatabaseService.db;
  final allScreenshots = await db.screenshotModels.where().findAll();
  final allExpenses = await db.expenseModels.where().findAll();
  final screenshotCount = allScreenshots.length;
  final expenseCount = allExpenses.length;
  final unprocessedCount = allScreenshots.where((s) => !s.isProcessed).length;

  debugPrint('[HomeProvider] screenshotCount=$screenshotCount expenseCount=$expenseCount unprocessedCount=$unprocessedCount');

  final expenseRepo = ref.read(expenseRepositoryProvider);
  final totalExpenses = await expenseRepo.getTotalExpenses();
  final recentExpenses = await expenseRepo.getRecentExpenses(limit: 5);

  return HomeStats(
    screenshotCount: screenshotCount,
    expenseCount: expenseCount,
    unprocessedCount: unprocessedCount,
    totalExpenses: totalExpenses,
    recentExpenses: recentExpenses,
  );
});
