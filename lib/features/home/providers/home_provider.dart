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

/// Builds the dashboard payload from the shared data sources:
/// - expenses come from the single `expenseListProvider` scan, aggregated
///   in memory through the shared [ExpenseSnapshot] contract (sum-then-round
///   totals, canonical breakdown/recent lists — no ad-hoc float math at this
///   layer);
/// - screenshot figures use cheap Isar counts instead of full-table loads.
///
/// Riverpod invalidation only flows downstream: the scan/delete flows and
/// pull-to-refresh invalidate *this* provider alone, so a rebuild would
/// happily re-emit the cached pre-scan values of [screenshotCountProvider],
/// [unprocessedCountProvider] and the expense rows behind
/// [expenseSnapshotProvider]. Every recompute therefore *refreshes* its
/// sources — a forced re-read that, unlike `watch`, adds no upstream
/// subscription, so refreshing a source can never re-dirty homeStatsProvider
/// and spiral into recompute loops. Expenses are pulled exactly once per
/// rebuild and aggregated through the shared [ExpenseSnapshot] contract in
/// memory. Screenshots and expenses only change through paths that
/// invalidate this provider (scan pass, screenshot delete, manual refresh),
/// so dropping the watches costs no live updates.
///
/// Any backend failure propagates as AsyncError (no debugPrint-and-swallow).
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final expenses = await ref.refresh(expenseListProvider.future);
  final snapshot = ExpenseSnapshot.from(expenses);
  final screenshotCount = await ref.refresh(screenshotCountProvider.future);
  final unprocessedCount = await ref.refresh(unprocessedCountProvider.future);

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
