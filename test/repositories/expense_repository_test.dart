import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/expenses/repositories/expense_repository.dart';

/// Pure tests over the date windows the expense repository hands to Isar.
/// No Isar database, no plugins, no filesystem: the window helpers are plain
/// functions over `DateTime`, and `_between` below reproduces exactly what
/// `filter().expenseDateBetween(a, b)` does (both bounds inclusive).
bool _between(DateTime value, DateTime lower, DateTime upper) =>
    !value.isBefore(lower) && !value.isAfter(upper);

void main() {
  group('monthQueryWindow', () {
    test('spans the whole month from midnight on day 1', () {
      final (start, end) = monthQueryWindow(DateTime(2026, 10));
      expect(start, DateTime(2026, 10, 1));
      expect(end.year, 2026);
      expect(end.month, 10);
      expect(end.day, 31);
    });

    test('ignores the day and time of the requested month', () {
      expect(
        monthQueryWindow(DateTime(2026, 10, 17, 14, 30, 5)),
        monthQueryWindow(DateTime(2026, 10)),
      );
      expect(monthQueryWindow(DateTime(2026, 10)).$1, DateTime(2026, 10, 1));
    });

    // DEFECT PROOF: the month window used to end at `23:59:59` on the last
    // day, so an expense timestamped inside the final second of the month was
    // outside the Isar `between` range and silently missing from monthly
    // totals. The bound must reach the end of the day.
    test('covers the final second of the last day', () {
      final (start, end) = monthQueryWindow(DateTime(2026, 10));
      final lateDay = [
        DateTime(2026, 10, 31, 23, 59, 59),
        DateTime(2026, 10, 31, 23, 59, 59, 500),
        DateTime(2026, 10, 31, 23, 59, 59, 999, 999),
      ];
      for (final timestamp in lateDay) {
        expect(
          _between(timestamp, start, end),
          isTrue,
          reason: '$timestamp must be inside the October window',
        );
      }
      // Control: with the old `23:59:59` bound, the two sub-second rows fell
      // outside the range and vanished from October's totals.
      final oldEnd = DateTime(2026, 10, 31, 23, 59, 59);
      expect(_between(lateDay[1], start, oldEnd), isFalse);
      expect(_between(lateDay[2], start, oldEnd), isFalse);
    });

    test('does not leak the next month into the window', () {
      final (start, end) = monthQueryWindow(DateTime(2026, 10));
      expect(_between(DateTime(2026, 10, 1), start, end), isTrue);
      expect(
        _between(DateTime(2026, 9, 30, 23, 59, 59, 999, 999), start, end),
        isFalse,
      );
      for (final nextMonth in [
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 1, 0, 0, 0, 0, 1),
      ]) {
        expect(_between(nextMonth, start, end), isFalse);
      }
    });

    test('handles December rollover and February leap years', () {
      final (decStart, decEnd) = monthQueryWindow(DateTime(2026, 12));
      expect(decStart, DateTime(2026, 12, 1));
      expect(decEnd, DateTime(2026, 12, 31, 23, 59, 59, 999, 999));

      final (_, febLeapEnd) = monthQueryWindow(DateTime(2024, 2));
      expect(febLeapEnd, DateTime(2024, 2, 29, 23, 59, 59, 999, 999));

      final (_, febEnd) = monthQueryWindow(DateTime(2026, 2));
      expect(febEnd, DateTime(2026, 2, 28, 23, 59, 59, 999, 999));
    });

    test('end bound is the last microsecond of the month', () {
      for (final month in [
        DateTime(2026, 1),
        DateTime(2026, 4),
        DateTime(2026, 12),
      ]) {
        final (start, end) = monthQueryWindow(month);
        expect(
          end.add(const Duration(microseconds: 1)),
          DateTime(start.year, start.month + 1, 1),
          reason: 'the microsecond after the window is the next month start',
        );
      }
    });
  });

  group('endOfDayInclusive', () {
    test('normalises any time of day to the last microsecond', () {
      for (final t in [
        DateTime(2026, 7, 4),
        DateTime(2026, 7, 4, 13, 45, 30, 123, 456),
        DateTime(2026, 7, 4, 23, 59, 59, 999, 999),
      ]) {
        expect(
          endOfDayInclusive(t),
          DateTime(2026, 7, 4, 23, 59, 59, 999, 999),
        );
      }
    });
  });

  group('periodQueryWindow', () {
    // DEFECT PROOF: `getTotalForPeriod` handed the caller's raw `start`/`end`
    // to Isar and only then re-filtered at day granularity in
    // AnalyticsService.totalAmount, so a period ending on 31 Oct dropped
    // everything after 00:00 of 31 Oct before analytics ever saw it.
    test('widens the Isar window to whole days', () {
      final (start, end) = periodQueryWindow(
        DateTime(2026, 10, 1, 12),
        DateTime(2026, 10, 31),
      );
      expect(start, DateTime(2026, 10, 1));
      expect(end, DateTime(2026, 10, 31, 23, 59, 59, 999, 999));
      expect(
        _between(DateTime(2026, 10, 31, 23, 59, 59, 500), start, end),
        isTrue,
      );
      expect(_between(DateTime(2026, 11, 1), start, end), isFalse);
    });

    test('a same-day period still covers the whole day', () {
      final (start, end) = periodQueryWindow(
        DateTime(2026, 10, 5, 8, 30),
        DateTime(2026, 10, 5, 9),
      );
      expect(start, DateTime(2026, 10, 5));
      expect(end, DateTime(2026, 10, 5, 23, 59, 59, 999, 999));
      expect(
        _between(DateTime(2026, 10, 5, 23, 59, 59, 999), start, end),
        isTrue,
      );
    });
  });
}
