import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/duration_extensions.dart';

void main() {
  group('formatDurationShort', () {
    test('hours and minutes', () {
      expect(
        const Duration(hours: 1, minutes: 5).formatDurationShort(),
        '1h 5m',
      );
      expect(const Duration(hours: 2).formatDurationShort(), '2h');
      expect(const Duration(minutes: 45).formatDurationShort(), '45m');
      expect(const Duration(seconds: 9).formatDurationShort(), '9s');
    });

    test('zero and days', () {
      expect(Duration.zero.formatDurationShort(), '0s');
      expect(const Duration(days: 2, hours: 3).formatDurationShort(), '2d 3h');
      expect(
        const Duration(
          days: 1,
          hours: 2,
          minutes: 3,
          seconds: 4,
        ).formatDurationShort(),
        '1d 2h 3m 4s',
      );
    });

    test('sub-second durations render as 0s', () {
      expect(const Duration(milliseconds: 500).formatDurationShort(), '0s');
    });

    test('negative durations use absolute value', () {
      expect(
        const Duration(hours: -1, minutes: -5).formatDurationShort(),
        '1h 5m',
      );
    });
  });

  group('asHoursMinutesSeconds', () {
    test('splits components', () {
      final parts = const Duration(
        hours: 2,
        minutes: 34,
        seconds: 56,
      ).asHoursMinutesSeconds;
      expect(parts.hours, 2);
      expect(parts.minutes, 34);
      expect(parts.seconds, 56);
    });

    test('rolls >59 minutes into hours', () {
      final parts = const Duration(
        minutes: 90,
        seconds: 30,
      ).asHoursMinutesSeconds;
      expect(parts.hours, 1);
      expect(parts.minutes, 30);
      expect(parts.seconds, 30);
    });

    test('zero and sub-minute', () {
      final z = Duration.zero.asHoursMinutesSeconds;
      expect((z.hours, z.minutes, z.seconds), (0, 0, 0));
      final s = const Duration(seconds: 7).asHoursMinutesSeconds;
      expect((s.hours, s.minutes, s.seconds), (0, 0, 7));
    });
  });

  group('clamp', () {
    test('within range returns unchanged', () {
      const d = Duration(minutes: 5);
      expect(
        d.clamp(const Duration(minutes: 1), const Duration(minutes: 10)),
        d,
      );
    });

    test('below min clamps up', () {
      expect(
        Duration.zero.clamp(
          const Duration(seconds: 1),
          const Duration(minutes: 1),
        ),
        const Duration(seconds: 1),
      );
    });

    test('above max clamps down', () {
      expect(
        const Duration(
          hours: 5,
        ).clamp(const Duration(minutes: 1), const Duration(hours: 1)),
        const Duration(hours: 1),
      );
    });

    test('defensively swaps inverted bounds', () {
      // Inverted bounds (10, 5) are treated as the range [5, 10].
      expect(
        const Duration(
          minutes: 7,
        ).clamp(const Duration(minutes: 10), const Duration(minutes: 5)),
        const Duration(minutes: 7),
      );
      expect(
        const Duration(
          minutes: 3,
        ).clamp(const Duration(minutes: 10), const Duration(minutes: 5)),
        const Duration(minutes: 5),
      );
      expect(
        const Duration(
          minutes: 20,
        ).clamp(const Duration(minutes: 10), const Duration(minutes: 5)),
        const Duration(minutes: 10),
      );
    });
  });

  group('existing pad-based formatters (API kept)', () {
    test('toMmSs', () {
      expect(const Duration(minutes: 4, seconds: 5).toMmSs(), '04:05');
      expect(const Duration(seconds: 59).toMmSs(), '00:59');
      expect(const Duration(minutes: 65).toMmSs(), '05:00'); // remainder style
    });

    test('toHhMmSs', () {
      expect(
        const Duration(hours: 1, minutes: 2, seconds: 3).toHhMmSs(),
        '01:02:03',
      );
      expect(const Duration(hours: 25).toHhMmSs(), '25:00:00');
    });
  });
}
