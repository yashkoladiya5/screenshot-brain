import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/date_extensions.dart';

void main() {
  // Everything is pinned to DateTime.utc operands plus an explicit
  // `reference` clock, so no expectation depends on the host timezone,
  // the wall clock, or DST.
  final ref = DateTime.utc(2025, 6, 18, 10); // Wed 18 Jun 2025, 10:00

  group('DateTimeExtensions predicates', () {
    test('isSameDayAs compares calendar fields only, ignoring time', () {
      final morning = DateTime.utc(2025, 6, 18, 1, 5);
      final night = DateTime.utc(2025, 6, 18, 23, 59);
      expect(morning.isSameDayAs(night), isTrue);
      expect(morning.isSameDayAs(DateTime.utc(2025, 6, 19, 1)), isFalse);
    });

    test('*On predicates honour the pinned reference day', () {
      expect(DateTime.utc(2025, 6, 18).isTodayOn(ref), isTrue);
      expect(DateTime.utc(2025, 6, 17).isYesterdayOn(ref), isTrue);
      expect(DateTime.utc(2025, 6, 19).isTomorrowOn(ref), isTrue);
      expect(DateTime.utc(2025, 6, 16).isYesterdayOn(ref), isFalse);
    });

    test('dayOffsetFrom is sign-aware and midnight-normalized', () {
      expect(DateTime.utc(2025, 6, 18, 23, 59).dayOffsetFrom(ref), 0);
      expect(DateTime.utc(2025, 6, 17, 0, 1).dayOffsetFrom(ref), -1);
      expect(DateTime.utc(2025, 6, 20).dayOffsetFrom(ref), 2);
      // Month/year boundaries.
      expect(DateTime.utc(2025, 5, 31).dayOffsetFrom(ref), -18);
      expect(
        DateTime.utc(2024, 12, 31).dayOffsetFrom(DateTime.utc(2025, 1, 1)),
        -1,
      );
    });

    test('getters still resolve against the device clock', () {
      final now = DateTime.now();
      expect(now.isToday, isTrue);
      expect(now.isYesterday, isFalse);
      expect(now.isTomorrow, isFalse);
    });

    test('midnight-boundary labels never leak "Today" across a day', () {
      // Screenshot taken 2025-03-09 23:59, viewed 2025-03-10 00:01.
      // Must be "Yesterday", never "Today".
      final before = DateTime.utc(2025, 3, 9, 23, 59);
      final after = DateTime.utc(2025, 3, 10, 0, 1);
      expect(before.toRelativeDateString(reference: after), 'Yesterday');
      expect(
        before.toRelativeString(reference: after),
        'Yesterday at 11:59 PM',
      );
      expect(before.isTodayOn(after), isFalse);
    });
  });

  group('day offsets across DST-shortened/lengthened days', () {
    // Regression: dayOffsetFrom subtracted local wall midnights with
    // `difference(...).inDays`, which truncates toward zero. In
    // America/New_York, 2025-03-09 00:00 EST -> 2025-03-10 00:00 EDT spans
    // only 23 real hours, so the offset collapsed to 0: yesterday was
    // labeled "Today" and tomorrow "Today" too, and week/month timeline
    // filters built on these predicates binned the wrong days.
    // Run with TZ=America/New_York to see the pre-fix failure.
    final march9 = DateTime.utc(2025, 3, 9);
    final march10 = DateTime.utc(2025, 3, 10);

    test('calendar offsets stay exact on a 23-hour day', () {
      expect(march10.dayOffsetFrom(march9), 1);
      expect(march9.dayOffsetFrom(march10), -1);
      expect(march10.isTomorrowOn(march9), isTrue);
      expect(march9.isYesterdayOn(march10), isTrue);
      expect(march10.isTodayOn(march9), isFalse);
      expect(march9.isTodayOn(march10), isFalse);
    });

    test('relative labels survive the spring-forward week', () {
      expect(march10.toRelativeDateString(reference: march9), 'Tomorrow');
      expect(march9.toRelativeDateString(reference: march10), 'Yesterday');
    });

    test('25-hour fall-back day keeps offsets exact too', () {
      // 2025-11-01 -> 2025-11-02 in NY is fine; 2025-11-02 (the 25-hour day)
      // relative to 2025-11-03 must still be exactly -1.
      final nov2 = DateTime.utc(2025, 11, 2);
      final nov3 = DateTime.utc(2025, 11, 3);
      expect(nov2.dayOffsetFrom(nov3), -1);
      expect(nov3.dayOffsetFrom(nov2), 1);
    });
  });

  group('DateTimeExtensions formatting', () {
    final date = DateTime.utc(2023, 10, 24, 16, 30);

    test('date and time patterns', () {
      expect(date.toStandardFormat(), 'Oct 24, 2023');
      expect(date.toShortDateString(), date.toStandardFormat());
      expect(date.toCompactFormat(), '10/24/2023');
      expect(date.toTimeString(), '4:30 PM');
      expect(date.formatted, '24 Oct 2023');
      expect(date.formattedWithTime, '24 Oct 2023 16:30');
      expect(date.monthYear, 'Oct 2023');
    });

    test('toRelativeString keeps the clock part for near days', () {
      expect(
        DateTime.utc(2025, 6, 18, 16, 30).toRelativeString(reference: ref),
        'Today at 4:30 PM',
      );
      expect(
        DateTime.utc(2025, 6, 17, 9).toRelativeString(reference: ref),
        'Yesterday at 9:00 AM',
      );
      expect(
        DateTime.utc(2025, 6, 19, 20, 5).toRelativeString(reference: ref),
        'Tomorrow at 8:05 PM',
      );
    });

    test('toRelativeString falls back to the standard format further out', () {
      expect(
        DateTime.utc(2023, 10, 24).toRelativeString(reference: ref),
        'Oct 24, 2023',
      );
    });

    test('toRelativeDateString drops the clock part', () {
      expect(
        DateTime.utc(2025, 6, 18, 16).toRelativeDateString(reference: ref),
        'Today',
      );
      expect(
        DateTime.utc(2025, 6, 17).toRelativeDateString(reference: ref),
        'Yesterday',
      );
      expect(
        DateTime.utc(2025, 6, 19).toRelativeDateString(reference: ref),
        'Tomorrow',
      );
      expect(
        DateTime.utc(2020, 2, 29, 23, 59).toRelativeDateString(reference: ref),
        'Feb 29, 2020',
      );
    });

    test('midnight and noon edge renderings', () {
      expect(DateTime.utc(2025, 6, 18, 0, 0).toTimeString(), '12:00 AM');
      expect(DateTime.utc(2025, 6, 18, 12, 0).toTimeString(), '12:00 PM');
      expect(DateTime.utc(2025, 6, 18, 12, 30).toTimeString(), '12:30 PM');
    });

    test('epoch renders as a date, never crashes', () {
      final epoch = DateTime.utc(1970, 1, 1);
      expect(epoch.toStandardFormat(), 'Jan 1, 1970');
      expect(epoch.toCompactFormat(), '01/01/1970');
    });
  });
}
