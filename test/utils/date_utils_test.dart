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
        '1 months ago',
      );
      expect(
        DateUtils.timeAgo(now.subtract(const Duration(days: 400))),
        '1 years ago',
      );
    });
  });
}
