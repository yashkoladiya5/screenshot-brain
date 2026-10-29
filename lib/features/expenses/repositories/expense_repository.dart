import 'package:isar/isar.dart';
import '../../../services/analytics_service.dart';
import '../../../services/database_service.dart';
import '../../../shared/models/expense_model.dart';
import '../models/expense_item.dart';

/// Inclusive upper bound of the calendar day containing [date], expressed as
/// the last microsecond of that day (`23:59:59.999999`) and not `23:59:59`.
///
/// Isar's `between` filter includes both bounds, so a `23:59:59` end bound
/// silently drops anything timestamped in the final second of the day (Isar
/// stores sub-second `DateTime` precision). Pairing it with
/// [AnalyticsService.dateOnly] on the lower side gives every query the same
/// day-granularity window the analytics layer re-filters with.
DateTime endOfDayInclusive(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);

/// Inclusive `[start, end]` window Isar should use for the calendar month of
/// [month] (its day and time components are ignored).
(DateTime, DateTime) monthQueryWindow(DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  return (start, endOfDayInclusive(DateTime(month.year, month.month + 1, 0)));
}

/// Inclusive `[start, end]` window Isar should use for the period a caller
/// means as `[start, end]` at day granularity.
(DateTime, DateTime) periodQueryWindow(DateTime start, DateTime end) =>
    (AnalyticsService.dateOnly(start), endOfDayInclusive(end));

class ExpenseRepository {
  final Isar db = DatabaseService.db;

  Future<List<ExpenseItem>> getAllExpenses() async {
    final models = await db.expenseModels.where().findAll();
    return models.map(_toItem).toList();
  }

  Future<List<ExpenseItem>> getExpensesByMonth(DateTime month) async {
    final (startOfMonth, endOfMonth) = monthQueryWindow(month);
    final models = await db.expenseModels
        .filter()
        .expenseDateBetween(startOfMonth, endOfMonth)
        .findAll();
    return models.map(_toItem).toList();
  }

  Future<List<ExpenseItem>> searchExpenses(String query) async {
    // A padded query matched nothing but its own spaces, and a whitespace-only
    // one ("   ", from a cleared field that never fired onChanged) skipped the
    // early return and searched for a literal space - which drops every
    // merchant without one. Normalise before deciding.
    final normalized = query.trim();
    if (normalized.isEmpty) return getAllExpenses();
    final lowerQuery = normalized.toLowerCase();
    final all = await getAllExpenses();
    return all.where((e) {
      return (e.merchant?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  Future<double> getTotalExpenses() async {
    final all = await getAllExpenses();
    double total = 0;
    for (final e in all) {
      total += (e.amount ?? 0);
    }
    return total;
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final all = await getAllExpenses();
    final byCategory = <String, double>{};
    for (final e in all) {
      // Trimming keeps a whitespace-only category from becoming its own
      // invisible bucket next to 'Other' (model getters already trim, and
      // AnalyticsService buckets on the trimmed value).
      final category = (e.category ?? '').trim();
      final cat = category.isEmpty ? 'Other' : category;
      byCategory[cat] = (byCategory[cat] ?? 0) + (e.amount ?? 0);
    }
    return byCategory;
  }

  Future<List<ExpenseItem>> getRecentExpenses({int limit = 10}) async {
    final models = await db.expenseModels.where().findAll();
    // Id-descending tie-break: `List.sort` leaves equal elements in whatever
    // order the table scan returned them, so two expenses created in the same
    // microsecond swapped places between refreshes. `take` also throws
    // ArgumentError on a negative count, so the limit is floored at zero.
    models.sort((a, b) {
      final byNewest = b.createdAt.compareTo(a.createdAt);
      return byNewest != 0 ? byNewest : b.id.compareTo(a.id);
    });
    return models.take(limit < 0 ? 0 : limit).map(_toItem).toList();
  }

  Future<void> deleteExpense(int id) async {
    await db.writeTxn(() => db.expenseModels.delete(id));
  }

  /// Total spent (sum of amounts) with effective expense date inside
  /// `[start, end]` (inclusive at day granularity, matching
  /// [AnalyticsService.totalAmount]). The Isar window is widened to whole
  /// days so a late-day timestamp is never dropped before the analytics
  /// filter gets to judge it.
  Future<double> getTotalForPeriod(DateTime start, DateTime end) async {
    final (windowStart, windowEnd) = periodQueryWindow(start, end);
    final models = await db.expenseModels
        .filter()
        .expenseDateBetween(windowStart, windowEnd)
        .findAll();
    return AnalyticsService.totalAmount(models, start: start, end: end);
  }

  /// Month-by-month spending totals between [from] and [to] (inclusive,
  /// month granularity, gaps filled with zero buckets).
  Future<List<MonthlyBucket>> getMonthlyBreakdown({
    required DateTime from,
    DateTime? to,
  }) async {
    final startMonth = AnalyticsService.monthStart(from);
    final endMonth = AnalyticsService.monthStart(to ?? DateTime.now());
    final (_, windowEnd) = monthQueryWindow(endMonth);
    final models = await db.expenseModels
        .filter()
        .expenseDateBetween(startMonth, windowEnd)
        .findAll();
    return AnalyticsService.monthlyExpenseSeries(models, from: from, to: to);
  }

  /// Per-category totals with percentage shares, sorted by total desc.
  Future<List<CategoryBucket>> getCategoryTotals() async {
    final models = await db.expenseModels.where().findAll();
    return AnalyticsService.categoryShares(models);
  }

  /// Highest-volume merchants by total spend, sorted desc.
  Future<List<MerchantBucket>> getTopMerchants({int limit = 5}) async {
    final models = await db.expenseModels.where().findAll();
    return AnalyticsService.topMerchants(models, limit: limit);
  }

  /// Removes every expense extracted from the given screenshot.
  /// Returns the number of rows deleted.
  Future<int> deleteByScreenshotId(int screenshotId) async {
    return db.writeTxn(
      () => db.expenseModels
          .filter()
          .screenshotIdEqualTo(screenshotId)
          .deleteAll(),
    );
  }

  ExpenseItem _toItem(ExpenseModel model) {
    return ExpenseItem(
      id: model.id,
      screenshotId: model.screenshotId,
      amount: model.amount,
      merchant: model.merchant,
      expenseDate: model.expenseDate,
      category: model.category,
      description: model.description,
      createdAt: model.createdAt,
    );
  }
}
