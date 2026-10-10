import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/services/analytics_service.dart';
import 'package:screenshot_brain/shared/models/expense_model.dart';
import 'package:screenshot_brain/shared/models/screenshot_model.dart';

ExpenseModel makeExpense({
  double? amount = 10.0,
  String? merchant,
  String? category,
  DateTime? expenseDate,
  DateTime? createdAt,
}) {
  return ExpenseModel()
    ..screenshotId = 1
    ..amount = amount
    ..merchant = merchant
    ..category = category
    ..expenseDate = expenseDate
    ..createdAt = createdAt ?? expenseDate ?? DateTime(2026, 1, 1, 12);
}

ScreenshotModel makeScreenshot({
  DateTime? createdAt,
  String filePath = '/tmp/img.png',
}) {
  return ScreenshotModel()
    ..filePath = filePath
    ..createdAt = createdAt ?? DateTime(2026, 1, 1, 9);
}

void main() {
  group('AnalyticsService.monthlyExpenseSeries', () {
    test('fills gaps with zero buckets for empty input', () {
      final series = AnalyticsService.monthlyExpenseSeries(
        const [],
        from: DateTime(2026, 1, 15),
        to: DateTime(2026, 4, 2),
      );
      expect(series.length, 4);
      expect(series.map((b) => b.monthKey).toList(), [
        '2026-01',
        '2026-02',
        '2026-03',
        '2026-04',
      ]);
      for (final bucket in series) {
        expect(bucket.count, 0);
        expect(bucket.total, 0.0);
      }
    });

    test('fills intermediate months without expenses as zero buckets', () {
      final expenses = [
        makeExpense(amount: 100, expenseDate: DateTime(2026, 1, 20)),
        makeExpense(amount: 50, expenseDate: DateTime(2026, 1, 5)),
        makeExpense(amount: 70, expenseDate: DateTime(2026, 3, 10)),
      ];
      final series = AnalyticsService.monthlyExpenseSeries(
        expenses,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 1),
      );
      expect(series.length, 3);
      expect(series[0].count, 2);
      expect(series[0].total, 150.0);
      expect(series[1].count, 0);
      expect(series[1].total, 0.0);
      expect(series[2].count, 1);
      expect(series[2].total, 70.0);
    });

    test('ignores entries outside the requested range', () {
      final expenses = [
        makeExpense(amount: 10, expenseDate: DateTime(2025, 12, 31)),
        makeExpense(amount: 20, expenseDate: DateTime(2026, 2, 1)),
        makeExpense(amount: 30, expenseDate: DateTime(2026, 5, 1)),
      ];
      final series = AnalyticsService.monthlyExpenseSeries(
        expenses,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 1),
      );
      expect(series.length, 3);
      expect(series.fold<int>(0, (sum, b) => sum + b.count), 1);
      expect(series[1].total, 20.0);
    });

    test('returns empty list when to precedes from', () {
      final series = AnalyticsService.monthlyExpenseSeries(
        [makeExpense(expenseDate: DateTime(2026, 1, 1))],
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 1, 1),
      );
      expect(series, isEmpty);
    });

    test('falls back to createdAt when expenseDate is null', () {
      final series = AnalyticsService.monthlyExpenseSeries(
        [
          makeExpense(
            amount: 5,
            expenseDate: null,
            createdAt: DateTime(2026, 2, 14),
          ),
        ],
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
      );
      expect(series.length, 1);
      expect(series.single.count, 1);
      expect(series.single.total, 5.0);
    });
  });

  group('AnalyticsService.monthlyScreenshotSeries', () {
    test('groups screenshot counts per month with gap filling', () {
      final screenshots = [
        makeScreenshot(createdAt: DateTime(2026, 1, 3)),
        makeScreenshot(createdAt: DateTime(2026, 1, 20)),
        makeScreenshot(createdAt: DateTime(2026, 3, 7)),
      ];
      final series = AnalyticsService.monthlyScreenshotSeries(
        screenshots,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 3, 1),
      );
      expect(series.map((b) => b.count).toList(), [2, 0, 1]);
      expect(series.every((b) => b.total == 0.0), isTrue);
    });

    test('empty input still produces zero buckets across the range', () {
      final series = AnalyticsService.monthlyScreenshotSeries(
        const [],
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 8, 1),
      );
      expect(series.length, 3);
      expect(series.every((b) => b.count == 0), isTrue);
    });
  });

  group('AnalyticsService.categoryShares', () {
    test('returns empty list for empty input', () {
      expect(AnalyticsService.categoryShares(const []), isEmpty);
    });

    test('computes percentage shares rounded to two decimals', () {
      final expenses = [
        makeExpense(amount: 60, category: 'Food'),
        makeExpense(amount: 30, category: 'Transport'),
        makeExpense(amount: 10, category: 'Other'),
      ];
      final shares = AnalyticsService.categoryShares(expenses);
      expect(shares.first.category, 'Food');
      expect(shares[0].percentage, 60.0);
      expect(shares[1].percentage, 30.0);
      expect(shares[2].percentage, 10.0);
      expect(shares[0].total, 60.0);
      expect(shares[0].count, 1);
    });

    test('rounds repeating percentages to two decimals', () {
      final expenses = [
        makeExpense(amount: 10, category: 'A'),
        makeExpense(amount: 10, category: 'B'),
        makeExpense(amount: 10, category: 'C'),
      ];
      final shares = AnalyticsService.categoryShares(expenses);
      for (final s in shares) {
        expect(s.percentage, 33.33);
      }
    });

    test('zero grand total yields zero percentages', () {
      final expenses = [
        makeExpense(amount: 0, category: 'Food'),
        makeExpense(amount: null, category: 'Transport'),
      ];
      final shares = AnalyticsService.categoryShares(expenses);
      expect(shares.length, 2);
      expect(shares.every((s) => s.percentage == 0.0), isTrue);
    });

    test('negative grand total yields zero percentages', () {
      final expenses = [
        makeExpense(amount: -50, category: 'Refund'),
        makeExpense(amount: 20, category: 'Food'),
      ];
      final shares = AnalyticsService.categoryShares(expenses);
      expect(shares.every((s) => s.percentage == 0.0), isTrue);
      expect(shares.first.total, 20.0);
    });

    test('null or blank category falls back to Uncategorized', () {
      final shares = AnalyticsService.categoryShares([
        makeExpense(amount: 5, category: null),
        makeExpense(amount: 5, category: '  '),
      ]);
      expect(shares.single.category, AnalyticsService.uncategorizedLabel);
      expect(shares.single.count, 2);
    });
  });

  group('AnalyticsService.topMerchants', () {
    test('sorts by total and respects limit', () {
      final expenses = [
        makeExpense(amount: 40, merchant: 'Amazon'),
        makeExpense(amount: 10, merchant: 'Corner Store'),
        makeExpense(amount: 100, merchant: 'Grocery Mart'),
        makeExpense(amount: 100, merchant: 'Grocery Mart'),
      ];
      final top = AnalyticsService.topMerchants(expenses, limit: 2);
      expect(top.length, 2);
      expect(top[0].merchant, 'Grocery Mart');
      expect(top[0].total, 200.0);
      expect(top[0].count, 2);
      expect(top[1].merchant, 'Amazon');
    });

    test('blank or null merchant falls back to Unknown', () {
      final top = AnalyticsService.topMerchants([
        makeExpense(amount: 7, merchant: null),
        makeExpense(amount: 3, merchant: '   '),
      ]);
      expect(top.single.merchant, AnalyticsService.unknownMerchantLabel);
      expect(top.single.total, 10.0);
    });

    test('limit <= 0 or empty input returns no merchants', () {
      expect(
        AnalyticsService.topMerchants([makeExpense(merchant: 'X')], limit: 0),
        isEmpty,
      );
      expect(AnalyticsService.topMerchants(const []), isEmpty);
    });
  });

  group('AnalyticsService.spendingStreaks', () {
    test('empty list produces all-zero stats', () {
      final stats = AnalyticsService.spendingStreaks(const []);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.spendingDays, 0);
      expect(stats.averagePerSpendingDay, 0.0);
      expect(stats.averagePerCalendarDay, 0.0);
    });

    test('current streak counts consecutive days ending at reference day', () {
      final expenses = [
        makeExpense(expenseDate: DateTime(2026, 2, 1)),
        makeExpense(expenseDate: DateTime(2026, 2, 4)),
        makeExpense(expenseDate: DateTime(2026, 2, 5)),
        makeExpense(expenseDate: DateTime(2026, 2, 6)),
      ];
      final stats = AnalyticsService.spendingStreaks(
        expenses,
        referenceDate: DateTime(2026, 2, 6, 23, 59),
      );
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('grace day: streak anchored at yesterday when today has no spend', () {
      final expenses = [
        makeExpense(expenseDate: DateTime(2026, 2, 3)),
        makeExpense(expenseDate: DateTime(2026, 2, 4)),
      ];
      final stats = AnalyticsService.spendingStreaks(
        expenses,
        referenceDate: DateTime(2026, 2, 5),
      );
      expect(stats.currentStreak, 2);
    });

    test('current streak is zero when neither today nor yesterday spent', () {
      final stats = AnalyticsService.spendingStreaks([
        makeExpense(expenseDate: DateTime(2026, 2, 1)),
      ], referenceDate: DateTime(2026, 2, 10));
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 1);
    });

    test('longest streak spans the whole dataset', () {
      final expenses = [
        makeExpense(expenseDate: DateTime(2026, 1, 1)),
        makeExpense(expenseDate: DateTime(2026, 1, 2)),
        makeExpense(expenseDate: DateTime(2026, 1, 3)),
        makeExpense(expenseDate: DateTime(2026, 1, 4)),
        makeExpense(expenseDate: DateTime(2026, 1, 10)),
        makeExpense(expenseDate: DateTime(2026, 1, 11)),
      ];
      final stats = AnalyticsService.spendingStreaks(
        expenses,
        referenceDate: DateTime(2026, 1, 11),
      );
      expect(stats.longestStreak, 4);
      expect(stats.currentStreak, 2);
    });

    test('day averages divide totals by spending days and calendar span', () {
      final expenses = [
        makeExpense(amount: 30, expenseDate: DateTime(2026, 1, 1)),
        makeExpense(amount: 30, expenseDate: DateTime(2026, 1, 1)),
        makeExpense(amount: 60, expenseDate: DateTime(2026, 1, 5)),
      ];
      final stats = AnalyticsService.spendingStreaks(
        expenses,
        referenceDate: DateTime(2026, 1, 5),
      );
      expect(stats.spendingDays, 2);
      expect(stats.averagePerSpendingDay, 60.0); // 120 / 2
      expect(stats.averagePerCalendarDay, 24.0); // 120 / 5 (Jan1..Jan5)
    });

    test('single expense day: both averages equal the amount', () {
      final stats = AnalyticsService.spendingStreaks([
        makeExpense(amount: 42.5, expenseDate: DateTime(2026, 3, 3)),
      ], referenceDate: DateTime(2026, 3, 3));
      expect(stats.averagePerSpendingDay, 42.5);
      expect(stats.averagePerCalendarDay, 42.5);
      expect(stats.currentStreak, 1);
    });

    test('negative amounts are included in averages', () {
      final stats = AnalyticsService.spendingStreaks([
        makeExpense(amount: 100, expenseDate: DateTime(2026, 1, 1)),
        makeExpense(amount: -40, expenseDate: DateTime(2026, 1, 2)),
      ], referenceDate: DateTime(2026, 1, 2));
      expect(stats.averagePerSpendingDay, 30.0);
      expect(stats.currentStreak, 2);
    });
  });

  group('AnalyticsService.totalAmount', () {
    test('sums all amounts when no range is given', () {
      final total = AnalyticsService.totalAmount([
        makeExpense(amount: 1.5),
        makeExpense(amount: 2.5),
        makeExpense(amount: null),
      ]);
      expect(total, 4.0);
    });

    test('respects inclusive start/end on the effective date', () {
      final expenses = [
        makeExpense(amount: 10, expenseDate: DateTime(2026, 1, 31, 23)),
        makeExpense(amount: 20, expenseDate: DateTime(2026, 2, 1)),
        makeExpense(amount: 30, expenseDate: DateTime(2026, 2, 28, 12)),
        makeExpense(amount: 40, expenseDate: DateTime(2026, 3, 1)),
      ];
      expect(
        AnalyticsService.totalAmount(
          expenses,
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 28, 23, 59),
        ),
        50.0,
      );
    });

    test('empty list sums to zero', () {
      expect(AnalyticsService.totalAmount(const []), 0.0);
    });
  });

  group('AnalyticsService helpers', () {
    test('monthStart / nextMonth / dateOnly normalize correctly', () {
      expect(
        AnalyticsService.monthStart(DateTime(2026, 5, 17, 13, 45)),
        DateTime(2026, 5, 1),
      );
      expect(
        AnalyticsService.nextMonth(DateTime(2026, 12, 1)),
        DateTime(2027, 1, 1),
      );
      expect(
        AnalyticsService.dateOnly(DateTime(2026, 5, 17, 23, 59, 59)),
        DateTime(2026, 5, 17),
      );
    });

    test('roundTo2 rounds half away from zero for positives', () {
      expect(AnalyticsService.roundTo2(33.333), 33.33);
      expect(AnalyticsService.roundTo2(0.005), 0.01);
      expect(AnalyticsService.roundTo2(-1.2345), -1.23);
      expect(AnalyticsService.roundTo2(10), 10.0);
    });
  });
}
