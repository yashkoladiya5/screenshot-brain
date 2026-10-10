import '../shared/models/expense_model.dart';
import '../shared/models/screenshot_model.dart';

/// A single month in a time series.
///
/// [month] is always normalized to the first day of the month at midnight
/// (local time). [total] is unused (0.0) for count-only series such as
/// screenshot uploads.
class MonthlyBucket {
  final DateTime month;
  final int count;
  final double total;

  const MonthlyBucket({
    required this.month,
    required this.count,
    this.total = 0.0,
  });

  String get monthKey =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';

  @override
  String toString() =>
      'MonthlyBucket(month: $monthKey, count: $count, total: $total)';
}

/// Aggregated spending for one category, with its share of the grand total.
class CategoryBucket {
  final String category;
  final double total;
  final int count;

  /// Percentage of the grand total, rounded to two decimals.
  /// Always 0.0 when the grand total is zero or negative.
  final double percentage;

  const CategoryBucket({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
  });

  @override
  String toString() =>
      'CategoryBucket(category: $category, total: $total, count: $count, '
      'percentage: $percentage)';
}

/// Aggregated spending for one merchant.
class MerchantBucket {
  final String merchant;
  final double total;
  final int count;

  const MerchantBucket({
    required this.merchant,
    required this.total,
    required this.count,
  });

  @override
  String toString() =>
      'MerchantBucket(merchant: $merchant, total: $total, count: $count)';
}

/// Streak and day-average statistics over an expense list.
class StreakStats {
  /// Consecutive calendar days (ending at the reference day, or the day
  /// before it) that each contain at least one expense.
  final int currentStreak;

  /// Longest run of consecutive spending days across the whole dataset.
  final int longestStreak;

  /// Number of distinct calendar days that contain at least one expense.
  final int spendingDays;

  /// Total amount divided by [spendingDays] (0.0 when there are none).
  final double averagePerSpendingDay;

  /// Total amount divided by the calendar span (first .. last spending
  /// day, inclusive). 0.0 when there are no expenses.
  final double averagePerCalendarDay;

  const StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.spendingDays,
    required this.averagePerSpendingDay,
    required this.averagePerCalendarDay,
  });

  @override
  String toString() =>
      'StreakStats(current: $currentStreak, longest: $longestStreak, '
      'spendingDays: $spendingDays, avgPerSpendingDay: '
      '$averagePerSpendingDay, avgPerCalendarDay: $averagePerCalendarDay)';
}

/// Pure, side-effect-free aggregation helpers over in-memory model lists.
///
/// Everything here is unit-testable without Isar, plugins or the filesystem.
/// Repositories fetch raw models and delegate the math to this service so
/// the same logic is reusable from providers and dashboards later.
class AnalyticsService {
  AnalyticsService._();

  static const String uncategorizedLabel = 'Uncategorized';
  static const String unknownMerchantLabel = 'Unknown';

  /// Effective date of an expense: [ExpenseModel.expenseDate] when set,
  /// otherwise the row creation time.
  static DateTime expenseDateOf(ExpenseModel expense) =>
      expense.expenseDate ?? expense.createdAt;

  /// Effective amount of an expense (null treated as 0.0).
  static double expenseAmountOf(ExpenseModel expense) => expense.amount ?? 0.0;

  /// Sum of expense amounts, optionally restricted to
  /// `[start, end]` (inclusive) on the effective expense date.
  static double totalAmount(
    List<ExpenseModel> expenses, {
    DateTime? start,
    DateTime? end,
  }) {
    double total = 0;
    for (final e in expenses) {
      final date = expenseDateOf(e);
      if (start != null && date.isBefore(start)) continue;
      if (end != null && date.isAfter(end)) continue;
      total += expenseAmountOf(e);
    }
    return total;
  }

  /// Month-by-month expense series between [from] and [to] (inclusive,
  /// month granularity). Months without expenses are filled with zero
  /// buckets so dashboards never show gaps.
  static List<MonthlyBucket> monthlyExpenseSeries(
    List<ExpenseModel> expenses, {
    required DateTime from,
    DateTime? to,
  }) {
    return _monthlySeries(
      expenses.map((e) {
        final d = expenseDateOf(e);
        return (d, expenseAmountOf(e));
      }).toList(),
      from: from,
      to: to,
    );
  }

  /// Month-by-month screenshot upload counts between [from] and [to]
  /// (inclusive, month granularity), gaps filled with zero buckets.
  static List<MonthlyBucket> monthlyScreenshotSeries(
    List<ScreenshotModel> screenshots, {
    required DateTime from,
    DateTime? to,
  }) {
    return _monthlySeries(
      screenshots.map((s) => (s.createdAt, 0.0)).toList(),
      from: from,
      to: to,
    );
  }

  static List<MonthlyBucket> _monthlySeries(
    List<(DateTime, double)> entries, {
    required DateTime from,
    DateTime? to,
  }) {
    final startMonth = monthStart(from);
    final endMonth = monthStart(to ?? DateTime.now());
    if (endMonth.isBefore(startMonth)) return const [];

    final counts = <DateTime, int>{};
    final totals = <DateTime, double>{};
    var cursor = startMonth;
    while (!cursor.isAfter(endMonth)) {
      counts[cursor] = 0;
      totals[cursor] = 0.0;
      cursor = nextMonth(cursor);
    }

    for (final (date, amount) in entries) {
      final month = monthStart(date);
      if (month.isBefore(startMonth) || month.isAfter(endMonth)) continue;
      counts[month] = counts[month]! + 1;
      totals[month] = totals[month]! + amount;
    }

    final result = <MonthlyBucket>[];
    for (final m in counts.keys.toList()..sort()) {
      result.add(MonthlyBucket(month: m, count: counts[m]!, total: totals[m]!));
    }
    return result;
  }

  /// Per-category totals with percentage shares of the grand total,
  /// sorted by total descending. Percentages are rounded to two decimals;
  /// when the grand total is zero or negative every share is 0.0.
  static List<CategoryBucket> categoryShares(List<ExpenseModel> expenses) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in expenses) {
      final cat = _categoryOf(e);
      totals[cat] = (totals[cat] ?? 0) + expenseAmountOf(e);
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    double grandTotal = 0;
    for (final t in totals.values) {
      grandTotal += t;
    }
    final hasPositiveBase = grandTotal > 0;

    final buckets =
        totals.entries.map((entry) {
          final percentage = hasPositiveBase
              ? roundTo2(entry.value / grandTotal * 100)
              : 0.0;
          return CategoryBucket(
            category: entry.key,
            total: roundTo2(entry.value),
            count: counts[entry.key]!,
            percentage: percentage,
          );
        }).toList()..sort((a, b) {
          final byTotal = b.total.compareTo(a.total);
          return byTotal != 0 ? byTotal : a.category.compareTo(b.category);
        });
    return buckets;
  }

  /// Merchant totals sorted by amount descending, capped at [limit].
  static List<MerchantBucket> topMerchants(
    List<ExpenseModel> expenses, {
    int limit = 5,
  }) {
    if (limit <= 0) return const [];
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in expenses) {
      final merchant = _merchantOf(e);
      totals[merchant] = (totals[merchant] ?? 0) + expenseAmountOf(e);
      counts[merchant] = (counts[merchant] ?? 0) + 1;
    }
    final buckets =
        totals.entries.map((entry) {
          return MerchantBucket(
            merchant: entry.key,
            total: roundTo2(entry.value),
            count: counts[entry.key]!,
          );
        }).toList()..sort((a, b) {
          final byTotal = b.total.compareTo(a.total);
          return byTotal != 0 ? byTotal : a.merchant.compareTo(b.merchant);
        });
    return buckets.take(limit).toList();
  }

  /// Streak and day-average statistics.
  ///
  /// The current streak anchors at [referenceDate] (default: today) when
  /// that day has spending, otherwise at the day before it (grace of one
  /// day) and falls back to 0 when neither day has spending.
  static StreakStats spendingStreaks(
    List<ExpenseModel> expenses, {
    DateTime? referenceDate,
  }) {
    if (expenses.isEmpty) {
      return const StreakStats(
        currentStreak: 0,
        longestStreak: 0,
        spendingDays: 0,
        averagePerSpendingDay: 0.0,
        averagePerCalendarDay: 0.0,
      );
    }

    final dayAmounts = <DateTime, double>{};
    for (final e in expenses) {
      final day = dateOnly(expenseDateOf(e));
      dayAmounts[day] = (dayAmounts[day] ?? 0) + expenseAmountOf(e);
    }

    final days = dayAmounts.keys.toList()..sort();
    final total = dayAmounts.values.fold<double>(0, (sum, v) => sum + v);

    int longest = 1;
    int run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    final reference = dateOnly(referenceDate ?? DateTime.now());
    DateTime? anchor;
    if (dayAmounts.containsKey(reference)) {
      anchor = reference;
    } else {
      final yesterday = reference.subtract(const Duration(days: 1));
      if (dayAmounts.containsKey(yesterday)) anchor = yesterday;
    }
    int current = 0;
    if (anchor != null) {
      var cursor = anchor;
      while (dayAmounts.containsKey(cursor)) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }

    final spanDays = days.last.difference(days.first).inDays + 1; // >= 1

    return StreakStats(
      currentStreak: current,
      longestStreak: longest,
      spendingDays: days.length,
      averagePerSpendingDay: roundTo2(total / days.length),
      averagePerCalendarDay: roundTo2(total / spanDays),
    );
  }

  static String _categoryOf(ExpenseModel e) {
    final cat = e.category?.trim();
    return (cat == null || cat.isEmpty) ? uncategorizedLabel : cat;
  }

  static String _merchantOf(ExpenseModel e) {
    final m = e.merchant?.trim();
    return (m == null || m.isEmpty) ? unknownMerchantLabel : m;
  }

  /// First day of the month at midnight (local).
  static DateTime monthStart(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// First day of the next month at midnight (local).
  static DateTime nextMonth(DateTime monthStart) =>
      DateTime(monthStart.year, monthStart.month + 1, 1);

  /// Midnight at the start of the given day (local).
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Round to two decimals (also used by repositories for display totals).
  static double roundTo2(num value) => (value * 100).roundToDouble() / 100;
}
