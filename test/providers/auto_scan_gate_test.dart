import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/screenshots/providers/screenshot_provider.dart';
import 'package:screenshot_brain/features/settings/providers/settings_provider.dart';

void main() {
  group('isAutoScanDue', () {
    final noon = DateTime(2026, 10, 11, 12);

    test('disabled setting vetoes every trigger, even the first', () {
      expect(
        isAutoScanDue(
          enabled: false,
          intervalHours: 24,
          lastAutoScanAt: null,
          now: noon,
        ),
        isFalse,
      );
    });

    test('no previous stamp means the first scan is always due', () {
      expect(
        isAutoScanDue(
          enabled: true,
          intervalHours: 24,
          lastAutoScanAt: null,
          now: noon,
        ),
        isTrue,
      );
    });

    test('just under the interval is not due, exactly on it is', () {
      bool due(Duration elapsed) =>
          isAutoScanDue(
            enabled: true,
            intervalHours: 24,
            lastAutoScanAt: noon,
            now: noon.add(elapsed),
          );
      expect(due(const Duration(hours: 23, minutes: 59)), isFalse);
      expect(due(const Duration(hours: 24)), isTrue);
      expect(due(const Duration(hours: 25)), isTrue);
    });

    test('a clock that moved backwards re-arms instead of freezing', () {
      expect(
        isAutoScanDue(
          enabled: true,
          intervalHours: 24,
          lastAutoScanAt: noon,
          now: noon.subtract(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });

    test('zero interval never blocks a scan', () {
      expect(
        isAutoScanDue(
          enabled: true,
          intervalHours: 0,
          lastAutoScanAt: noon,
          now: noon,
        ),
        isTrue,
      );
    });
  });

  group('ScanScreenshotsNotifier.scanIfDue', () {
    // Isar is never opened in these tests, so scan() hits the ready guard and
    // aborts immediately — enough to exercise the cadence gate for real.
    test('disabled auto scan never stamps or runs', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(settingsProvider.notifier).toggleAutoScan();
      final notifier = container.read(scanScreenshotsProvider.notifier);

      final ran = await notifier.scanIfDue(now: DateTime(2026, 10, 11));

      expect(ran, isFalse);
      expect(notifier.lastAutoScanAt, isNull);
    });

    test('first due call stamps the reference time, immediate second is skipped', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(scanScreenshotsProvider.notifier);
      final now = DateTime(2026, 10, 11, 9);

      final first = await notifier.scanIfDue(now: now);
      final second = await notifier.scanIfDue(now: now.add(const Duration(minutes: 5)));

      expect(first, isTrue);
      expect(notifier.lastAutoScanAt, now);
      expect(second, isFalse);
      expect(notifier.lastAutoScanAt, now);
    });

    test('honors the user-configured interval from settings', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(settingsProvider.notifier).setScanInterval(2);
      final notifier = container.read(scanScreenshotsProvider.notifier);
      final start = DateTime(2026, 10, 11, 9);
      await notifier.scanIfDue(now: start);

      final early = await notifier.scanIfDue(
        now: start.add(const Duration(hours: 1, minutes: 59)),
      );
      final late = await notifier.scanIfDue(
        now: start.add(const Duration(hours: 2)),
      );

      expect(early, isFalse);
      expect(late, isTrue);
      expect(notifier.lastAutoScanAt, start.add(const Duration(hours: 2)));
    });
  });
}
