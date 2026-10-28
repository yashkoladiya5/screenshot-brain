import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/date_utils.dart';

void main() {
  // All fixed dates use DateTime.utc to keep expectations DST-free; the
  // helpers themselves are calendar-based so zone does not affect results.
  // (Field-wise comparisons are used where a helper returns a local DateTime.)
  void expectDate(DateTime actual, int y, int m, int d) {
    expect(actual.year, y);
    expect(actual.month, m);
    expect(actual.day, d);
  }

  group('startOfWeek / endOfWeek (Monday start, locale-agnostic)', () {
    test('anchors midweek to Monday', () {
      final wed = DateTime.utc(2025, 6, 4); // Wed
      final start = DateUtils.startOfWeek(wed);
      expect(start.weekday, DateTime.monday);
      expect(start.day, 2);
      expect(start.hour, 0);
    });

    test('Monday maps to itself; Sunday stays in same week', () {
      final mon = DateTime.utc(2025, 6, 2);
      expect(DateUtils.startOfWeek(mon).day, 2);
      final sun = DateTime.utc(2025, 6, 8);
      expect(DateUtils.startOfWeek(sun).day, 2);
    });

    test('endOfWeek is Sunday end-of-day', () {
      final end = DateUtils.endOfWeek(DateTime.utc(2025, 6, 4));
      expect(end.weekday, DateTime.sunday);
      expect(end.day, 8);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('crosses year boundary (2025-01-01 is Wednesday)', () {
      final start = DateUtils.startOfWeek(DateTime.utc(2025, 1, 1));
      expect(start.day, 30); // Dec 30 2024
      expect(start.year, 2024);
      final end = DateUtils.endOfWeek(DateTime.utc(2025, 1, 1));
      expect(end.year, 2025);
      expect(end.month, 1);
      expect(end.day, 5);
    });
  });

  group('startOfWeek / endOfWeek are DST wall-clock safe', () {
    // Regression: both helpers used to add/subtract 24-hour `Duration`s from
    // a local midnight. In zones whose DST transition lands at midnight
    // (Asia/Beirut, America/Santiago, Asia/Tehran, Pacific/Apia, ...), the
    // week anchor came back on the wrong day or at 01:00/23:00, so a
    // "this week" filter silently dropped screenshots taken between 00:00
    // and 01:00 on Monday (or bucketed the whole week one day late).
    // Run with TZ=Asia/Beirut to see the pre-fix failure.
    test('startOfWeek of a Sunday in a midnight-DST week is Monday 00:00', () {
      final sun = DateTime(2025, 10, 26); // Sunday, Beirut week
      final start = DateUtils.startOfWeek(sun);
      expect(start.weekday, DateTime.monday);
      expect(
        [
          start.year,
          start.month,
          start.day,
          start.hour,
          start.minute,
          start.second,
        ],
        [2025, 10, 20, 0, 0, 0],
      );
    });

    test('every day of that week anchors to the same Monday midnight', () {
      for (int d = 20; d <= 26; d++) {
        final start = DateUtils.startOfWeek(DateTime(2025, 10, d));
        expect(start.day, 20, reason: 'day $d should bucket to Mon 20');
        expect(start.hour, 0);
        expect(start.minute, 0);
      }
    });

    test('endOfWeek of a midnight-DST week is Sunday 23:59:59.999', () {
      final end = DateUtils.endOfWeek(DateTime(2025, 10, 20));
      expect(end.weekday, DateTime.sunday);
      expect(
        [end.year, end.month, end.day, end.hour, end.minute, end.second],
        [2025, 10, 26, 23, 59, 59],
      );
      expect(end.millisecond, 999);
    });
  });

  group('monthKey / monthLabel', () {
    test('monthKey is zero-padded yyyy-MM', () {
      expect(DateUtils.monthKey(DateTime.utc(2025, 1)), '2025-01');
      expect(DateUtils.monthKey(DateTime.utc(2025, 12, 31)), '2025-12');
      expect(DateUtils.monthKey(DateTime.utc(2025, 9, 5)), '2025-09');
      expect(DateUtils.monthKey(DateTime.utc(999, 3)), '0999-03');
    });

    test('monthKey sorts lexicographically by chronology', () {
      final keys = [
        DateUtils.monthKey(DateTime.utc(2025, 10)),
        DateUtils.monthKey(DateTime.utc(2025, 2)),
        DateUtils.monthKey(DateTime.utc(2024, 12)),
      ]..sort();
      expect(keys, ['2024-12', '2025-02', '2025-10']);
    });

    test('monthLabel renders full month name', () {
      expect(DateUtils.monthLabel(DateTime.utc(2025, 1, 15)), 'January 2025');
      expect(DateUtils.monthLabel(DateTime.utc(2025, 12)), 'December 2025');
    });

    test('monthLabelForKey round-trips monthKey', () {
      expect(DateUtils.monthLabelForKey('2025-01'), 'January 2025');
      expect(DateUtils.monthLabelForKey('garbage'), 'garbage');
      expect(DateUtils.monthLabelForKey('2025-13'), '2025-13');
    });
  });

  group('daysBetween ignores time-of-day', () {
    test('same day different times is 0', () {
      expect(
        DateUtils.daysBetween(
          DateTime.utc(2025, 6, 1, 0, 1),
          DateTime.utc(2025, 6, 1, 23, 59),
        ),
        0,
      );
    });

    test('counts calendar days', () {
      expect(
        DateUtils.daysBetween(
          DateTime.utc(2025, 1, 30),
          DateTime.utc(2025, 2, 2),
        ),
        3,
      );
    });

    test('negative when reversed', () {
      expect(
        DateUtils.daysBetween(
          DateTime.utc(2025, 3, 5, 12),
          DateTime.utc(2025, 3, 1),
        ),
        -4,
      );
    });
  });

  group('clampToMonthEnd and month arithmetic', () {
    test('daysInMonth honors leap years', () {
      expect(DateUtils.daysInMonth(2024, 2), 29); // div by 4
      expect(DateUtils.daysInMonth(2025, 2), 28);
      expect(DateUtils.daysInMonth(2100, 2), 28); // century not div by 400
      expect(DateUtils.daysInMonth(2000, 2), 29); // div by 400
      expect(DateUtils.daysInMonth(2025, 12), 31);
      expect(DateUtils.daysInMonth(2025, 4), 30);
    });

    test('daysInMonth equals the civil Gregorian rule for every month', () {
      // Regression: daysInMonth subtracted a real 24-hour Duration from the
      // next month's local midnight. Where a DST transition lands at
      // midnight on the last day of a month (Asia/Beirut 2024-03-31,
      // Europe/Dublin 2024-03-31, Australia/Lord_Howe 2004-10-31, ...), the
      // span is 23 hours and the subtraction landed on the day *before*
      // month end — March reported 30 days, and addMonths/clampToMonthEnd
      // then clamped valid month-end dates one day early. Run the pre-fix
      // code with TZ=Asia/Beirut to watch 2024-03 report 30.
      int expected(int year, int month) {
        const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        if (month != 2) return lengths[month - 1];
        final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
        return leap ? 29 : 28;
      }

      for (var year = 1970; year <= 2035; year++) {
        for (var month = 1; month <= 12; month++) {
          expect(
            DateUtils.daysInMonth(year, month),
            expected(year, month),
            reason: 'daysInMonth($year, $month)',
          );
        }
      }
    });

    test('addMonths into a month whose end day is a midnight-DST day', () {
      // Jan 31 + 2 months is March 31 in 2024. If March were mis-measured
      // as 30 days (the pre-fix Duration bug), this clamped to March 30.
      final res = DateUtils.addMonths(DateTime(2024, 1, 31), 2);
      expectDate(res, 2024, 3, 31);
    });

    test('Jan31 + 1 month clamps to Feb28 (non-leap)', () {
      final res = DateUtils.addMonths(DateTime.utc(2025, 1, 31), 1);
      expectDate(res, 2025, 2, 28);
    });

    test('Jan31 + 1 month clamps to Feb29 in leap year', () {
      final res = DateUtils.addMonths(DateTime.utc(2024, 1, 31), 1);
      expectDate(res, 2024, 2, 29);
    });

    test('Jan31 + 13 months rolls year and clamps', () {
      final res = DateUtils.addMonths(DateTime.utc(2025, 1, 31), 13);
      expectDate(res, 2026, 2, 28);
    });

    test('backwards month subtraction clamps', () {
      final res = DateUtils.subtractMonths(DateTime.utc(2025, 3, 31), 1);
      expectDate(res, 2025, 2, 28);
    });

    test('exact month math does not drift (Mar31 +12 = Mar31)', () {
      final res = DateUtils.addMonths(DateTime.utc(2025, 3, 31), 12);
      expectDate(res, 2026, 3, 31);
    });

    test('clampToMonthEnd fixes overflowed day values, keeps time', () {
      // DateTime rolls Feb 31 -> Mar 3; clamp of the rolled date is a no-op,
      // so callers use addMonths. clampToMonthEnd still fixes a hand-built
      // date whose day exceeds its month.
      final overflow = DateTime.utc(2025, 2, 31); // == Mar 3
      expect(DateUtils.clampToMonthEnd(overflow), overflow);
      final explicit = DateTime.utc(2025, 1, 31);
      expect(DateUtils.clampToMonthEnd(explicit), explicit);
    });
  });

  group('isSameDay / isSameMonth (existing API kept)', () {
    test('isSameDay ignores time', () {
      expect(
        DateUtils.isSameDay(
          DateTime(2025, 6, 1, 0, 0),
          DateTime(2025, 6, 1, 23, 59),
        ),
        isTrue,
      );
      expect(
        DateUtils.isSameDay(DateTime(2025, 6, 1), DateTime(2025, 6, 2)),
        isFalse,
      );
    });

    test('isSameMonth compares year+month only', () {
      expect(
        DateUtils.isSameMonth(
          DateTime.utc(2025, 6, 1),
          DateTime.utc(2025, 6, 30, 23),
        ),
        isTrue,
      );
      expect(
        DateUtils.isSameMonth(
          DateTime.utc(2024, 6, 15),
          DateTime.utc(2025, 6, 15),
        ),
        isFalse,
      );
    });
  });

  group('timeAgo', () {
    test('bucketed phrasing relative to now', () {
      final now = DateTime.now();
      expect(DateUtils.timeAgo(now), 'Just now');
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(minutes: 5))),
        '5 mins ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(hours: 3))),
        '3 hours ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 4))),
        '4 days ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 45))),
        '1 month ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 400))),
        '1 year ago',
      );
    });

    test('singular units never say "1 days/months/years ago"', () {
      final now = DateTime.now();
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 1, seconds: 1))),
        '1 day ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 31, seconds: 1))),
        '1 month ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 366, seconds: 1))),
        '1 year ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(hours: 1, seconds: 1))),
        '1 hour ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(minutes: 1, seconds: 1))),
        '1 min ago',
      );
    });
  });
}
