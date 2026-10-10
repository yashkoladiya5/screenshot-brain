import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/screenshot_model.dart';
import '../../expenses/models/expense_item.dart';
import '../../expenses/providers/expense_provider.dart';

class HomeStats {
  final int screenshotCount;
  final int expenseCount;
  final int unprocessedCount;
  final double totalExpenses;

  /// Sum of expenses dated in the current calendar month.
  final double monthlyExpenses;

  /// Spend per category across all known expenses.
  final Map<String, double> expensesByCategory;

  final List<ExpenseItem> recentExpenses;

  const HomeStats({
    required this.screenshotCount,
    required this.expenseCount,
    required this.unprocessedCount,
    required this.totalExpenses,
    required this.recentExpenses,
    this.monthlyExpenses = 0,
    this.expensesByCategory = const {},
  });
}

/// Number of stored screenshots without pulling every row into memory.
final screenshotCountProvider = FutureProvider<int>((ref) async {
  final db = DatabaseService.db;
  return db.screenshotModels.count();
});

/// Screenshots that have not been processed yet, counted server-side.
final unprocessedCountProvider = FutureProvider<int>((ref) async {
  final db = DatabaseService.db;
  return db.screenshotModels.filter().isProcessedEqualTo(false).count();
});

/// Builds the dashboard payload from shared derived sources:
/// - expense figures come from [expenseSnapshotProvider], which itself is fed
///   by the single shared `expenseListProvider` scan, so home never triggers
///   duplicate concurrent expense table scans;
/// - screenshot figures use cheap Isar counts instead of full-table loads.
///
/// Any backend failure propagates as AsyncError (no debugPrint-and-swallow).
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final snapshot = await ref.watch(expenseSnapshotProvider.future);
  final screenshotCount = await ref.watch(screenshotCountProvider.future);
  final unprocessedCount = await ref.watch(unprocessedCountProvider.future);

  return HomeStats(
    screenshotCount: screenshotCount,
    expenseCount: snapshot.expenses.length,
    unprocessedCount: unprocessedCount,
    totalExpenses: snapshot.total,
    monthlyExpenses: snapshot.monthlyTotal,
    expensesByCategory: snapshot.byCategory,
    recentExpenses: snapshot.recent.take(5).toList(),
  );
});
