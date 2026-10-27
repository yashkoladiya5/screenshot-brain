import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/settings/providers/settings_provider.dart';

/// Pure in-memory fake behind the [SettingsPersistence] seam. No plugin, no
/// filesystem — it only records what the notifier saved and can replay a
/// stored snapshot to a fresh notifier (a simulated app restart).
class FakeSettingsPersistence implements SettingsPersistence {
  FakeSettingsPersistence({this.stored});

  AppSettings? stored;

  /// When set, [load] waits on this completer — used to stage a restore that
  /// resolves AFTER a user mutation (restart/mutation race).
  Completer<void>? loadGate;

  /// Every snapshot handed to [save], oldest first.
  final List<AppSettings> saves = [];

  @override
  Future<AppSettings?> load() async {
    await loadGate?.future;
    return stored;
  }

  @override
  Future<void> save(AppSettings settings) async {
    saves.add(settings);
    stored = settings;
  }
}

class _ThrowingPersistence implements SettingsPersistence {
  @override
  Future<AppSettings?> load() async => null;

  // A synchronous throw, not a Future error: the seam contract says failures
  // must be swallowed by SettingsNotifier, so a throwing store may never
  // propagate out of a UI tap handler.
  @override
  Future<void> save(AppSettings settings) => throw StateError('disk full');
}

class _AsyncFailingPersistence implements SettingsPersistence {
  @override
  Future<AppSettings?> load() async => null;

  @override
  Future<void> save(AppSettings settings) async {
    throw StateError('late write failure');
  }
}

/// Lets all pending microtasks/zero-duration futures settle.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('SettingsNotifier restore (restart round-trip)', () {
    test('stored settings are restored on start, not overridden by defaults', () async {
      // Simulates a restart: the previous session saved dark theme, a 6h
      // cadence, auto-scan off and Wi-Fi-only OCR. A notifier built over the
      // same store must come up with THOSE values, not the const defaults.
      final fake = FakeSettingsPersistence(
        stored: const AppSettings(
          autoScanEnabled: false,
          ocrOnWifiOnly: true,
          scanIntervalHours: 6,
          themeMode: ThemeMode.dark,
        ),
      );

      final notifier = SettingsNotifier(persistence: fake);
      await _flush();

      expect(notifier.state.autoScanEnabled, isFalse);
      expect(notifier.state.ocrOnWifiOnly, isTrue);
      expect(notifier.state.scanIntervalHours, 6);
      expect(notifier.state.themeMode, ThemeMode.dark);
    });

    test('round-trip preserves exact types and units (hours stay int hours)', () async {
      final store = FakeSettingsPersistence();
      final first = SettingsNotifier(persistence: store);
      await _flush();
      first.setThemeMode(ThemeMode.dark);
      first.setScanInterval(48);
      first.toggleAutoScan();
      await _flush();

      // What landed in the store must be value-identical to the live state —
      // no int<->string or minutes<->hours rewriting on the way in or out.
      expect(store.stored, const AppSettings(
        autoScanEnabled: false,
        scanIntervalHours: 48,
        themeMode: ThemeMode.dark,
      ));

      final restarted = SettingsNotifier(persistence: store);
      await _flush();
      expect(restarted.state, store.stored);
      expect(restarted.state.scanIntervalHours, 48);
      expect(restarted.state.themeMode, ThemeMode.dark);
    });

    test('a user change made while a restore is in flight wins', () async {
      // The stored snapshot must not clobber a mutation the user performed
      // before the (slow) load resolved.
      final fake = FakeSettingsPersistence(
        stored: const AppSettings(themeMode: ThemeMode.dark),
      );
      fake.loadGate = Completer<void>();

      final notifier = SettingsNotifier(persistence: fake);
      notifier.setThemeMode(ThemeMode.light);
      fake.loadGate!.complete();
      await _flush();

      expect(notifier.state.themeMode, ThemeMode.light);
      // And the winning value was persisted, not just held in memory.
      expect(fake.stored!.themeMode, ThemeMode.light);
    });

    test('explicit load() after the auto-restore is a harmless no-op', () async {
      final fake = FakeSettingsPersistence(
        stored: const AppSettings(themeMode: ThemeMode.dark),
      );
      final notifier = SettingsNotifier(persistence: fake);
      await _flush();

      notifier.setThemeMode(ThemeMode.light);
      await notifier.load();

      // A reload must never resurrect the stale snapshot over a real change.
      expect(notifier.state.themeMode, ThemeMode.light);
    });

    test('an empty store leaves the defaults untouched', () async {
      final fake = FakeSettingsPersistence();
      final notifier = SettingsNotifier(persistence: fake);
      await _flush();

      expect(notifier.state, const AppSettings());
    });
  });

  group('SettingsNotifier commit + validation (correct code guard)', () {
    test('setScanInterval clamps out-of-range values instead of accepting them', () {
      final notifier = SettingsNotifier(persistence: FakeSettingsPersistence());

      notifier.setScanInterval(0);
      expect(notifier.state.scanIntervalHours, 1);
      notifier.setScanInterval(-10);
      expect(notifier.state.scanIntervalHours, 1);
      notifier.setScanInterval(1000);
      expect(notifier.state.scanIntervalHours, 24 * 7);
      notifier.setScanInterval(12);
      expect(notifier.state.scanIntervalHours, 12);
    });

    test('every mutation persists an identical value-based snapshot', () async {
      final fake = FakeSettingsPersistence();
      final notifier = SettingsNotifier(persistence: fake);
      await _flush();

      notifier.toggleOcrWifiOnly();
      await _flush();

      expect(fake.saves, hasLength(1));
      expect(fake.saves.single, notifier.state);
      expect(fake.saves.single.ocrOnWifiOnly, isTrue);
    });

    test('a redundant set does not rewrite the store or notify', () async {
      final fake = FakeSettingsPersistence();
      final notifier = SettingsNotifier(persistence: fake);
      await _flush();

      final seen = <AppSettings>[];
      // fireImmediately=false: we only want REAL changes, not the initial
      // state handoff that StateNotifier.addListener does by default.
      notifier.addListener(seen.add, fireImmediately: false);
      notifier.setScanInterval(notifier.state.scanIntervalHours);
      await _flush();

      expect(seen, isEmpty);
      expect(fake.saves, isEmpty);
    });

    test('a synchronous save failure never breaks the live state', () async {
      final notifier = SettingsNotifier(persistence: _ThrowingPersistence());
      await _flush();

      notifier.toggleAutoScan();
      await _flush();

      expect(notifier.state.autoScanEnabled, isFalse);
    });

    test('a deferred (Future) save failure is swallowed too', () async {
      final notifier = SettingsNotifier(
        persistence: _AsyncFailingPersistence(),
      );
      await _flush();

      notifier.toggleOcrWifiOnly();
      await _flush();

      expect(notifier.state.ocrOnWifiOnly, isTrue);
    });

    test('theme mode is stored as the enum itself, not an index or key', () async {
      final fake = FakeSettingsPersistence();
      final notifier = SettingsNotifier(persistence: fake);
      await _flush();

      notifier.setThemeMode(ThemeMode.dark);
      await _flush();

      expect(fake.stored!.themeMode, ThemeMode.dark);
      // The same enum value the app reads (themeModeProvider) — a restart
      // over this store yields dark, never a silent fallback to system.
      final restarted = SettingsNotifier(persistence: fake);
      await _flush();
      expect(restarted.state.themeMode, ThemeMode.dark);
    });
  });
}
