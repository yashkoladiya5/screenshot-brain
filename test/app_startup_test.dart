import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:screenshot_brain/app.dart';
import 'package:screenshot_brain/features/screenshots/providers/screenshot_provider.dart';
import 'package:screenshot_brain/features/settings/providers/settings_provider.dart';
import 'package:screenshot_brain/services/database_service.dart';

/// Interface fake for the abstract [Isar] class: the native database cannot
/// be opened in unit tests, so the DatabaseService seams are fed a fake that
/// only tracks how often it was opened/closed. Unimplemented members route
/// through `noSuchMethod` and are never touched by the service logic.
class _FakeIsar implements Isar {
  int closeCount = 0;

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    closeCount++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// In-memory fake of the [SettingsPersistence] seam for scheduler tests.
class _FakeSettingsStore implements SettingsPersistence {
  _FakeSettingsStore(this.stored);

  AppSettings? stored;
  int saveCount = 0;

  @override
  Future<AppSettings?> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
    saveCount++;
  }
}

/// Fake store whose restore completes only after [delay] — stands in for the
/// real asynchronous disk read so startup ordering against the cadence gate
/// is deterministic under the fake-async test zone.
class _SlowSettingsStore implements SettingsPersistence {
  _SlowSettingsStore(this.stored, this.delay);

  final AppSettings? stored;
  final Duration delay;

  @override
  Future<AppSettings?> load() =>
      Future<AppSettings?>.delayed(delay, () => stored);

  @override
  Future<void> save(AppSettings settings) async {}
}

/// Production [ScanScreenshotsNotifier] with the heavy scan sink replaced by
/// a counter: the cadence gate (`scanIfDue` + settings) stays the real one
/// from lib/, while `scan()` records passes without touching Isar/ML Kit.
/// `fakeNow` acts as the fake clock handed to the real gate.
class _RecordingScanNotifier extends ScanScreenshotsNotifier {
  _RecordingScanNotifier(this.fakeNow);

  DateTime? fakeNow;
  int scanIfDueCalls = 0;
  int scanRuns = 0;

  @override
  Future<bool> scanIfDue({DateTime? now}) {
    scanIfDueCalls++;
    return super.scanIfDue(now: now ?? fakeNow);
  }

  @override
  Future<void> scan() async {
    scanRuns++;
  }
}

/// Polls until [file] decodes to [expected] — the deterministic stand-in for
/// the notifier's fire-and-forget save in real-async tests (a mid-write read
/// simply fails to match and is retried).
Future<void> _waitUntilSettles(File file, AppSettings expected) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (file.existsSync()) {
      try {
        if (decodeAppSettings(file.readAsStringSync()) == expected) return;
      } catch (_) {
        // File busy mid-write; retry.
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('settings file never settled at $expected');
}

void main() {
  // ------------------------------------------------------------------
  // (a) disk-backed settings store wired behind the persistence seam
  // ------------------------------------------------------------------

  group('AppSettings JSON codec', () {
    test('round-trips every field', () {
      const settings = AppSettings(
        autoScanEnabled: false,
        ocrOnWifiOnly: true,
        scanIntervalHours: 6,
        themeMode: ThemeMode.dark,
      );
      expect(decodeAppSettings(encodeAppSettings(settings)), settings);
    });

    test('garbage input decodes to null (treated as an empty store)', () {
      expect(decodeAppSettings('not json at all'), isNull);
      expect(decodeAppSettings(jsonEncode([1, 2, 3])), isNull);
    });

    test('missing or invalid fields fall back to defaults, not corruption', () {
      final partial = decodeAppSettings(
        jsonEncode({'themeMode': 'light', 'scanIntervalHours': 'oops'}),
      );
      expect(partial, isNotNull);
      expect(partial!.themeMode, ThemeMode.light);
      expect(partial.scanIntervalHours, 24);
      expect(partial.autoScanEnabled, isTrue);
      expect(partial.ocrOnWifiOnly, isFalse);

      final invalidTheme = decodeAppSettings(
        jsonEncode({'themeMode': 'sepia'}),
      );
      expect(invalidTheme!.themeMode, ThemeMode.system);
    });
  });

  group('startup settings store', () {
    late Directory docsDir;

    setUp(() {
      docsDir = Directory.systemTemp.createTempSync('sb-startup-test');
    });
    tearDown(() {
      if (docsDir.existsSync()) docsDir.deleteSync(recursive: true);
    });

    test('settings file lives in the documents directory', () {
      final file = settingsFileFor(docsDir);
      expect(file.path, '${docsDir.path}/$kSettingsFileName');
    });

    test('a saved preference survives a simulated restart', () async {
      // Session 1: the production override wires the file store, the user
      // changes settings, and the notifier's unawaited save hits the disk.
      final overrides = await buildStartupOverrides(
        documentsDirectory: () async => docsDir,
      );
      final containerA = ProviderContainer(overrides: overrides);
      addTearDown(containerA.dispose);
      final notifierA = containerA.read(settingsProvider.notifier);
      notifierA.setThemeMode(ThemeMode.dark);
      notifierA.setScanInterval(6);
      notifierA.toggleAutoScan();
      // Saves are fire-and-forget behind the seam; wait until the last
      // snapshot actually landed so the "restart" reads a settled file.
      await _waitUntilSettles(
        settingsFileFor(docsDir),
        const AppSettings(
          autoScanEnabled: false,
          scanIntervalHours: 6,
          themeMode: ThemeMode.dark,
        ),
      );
      // Double toggle = back to the enabled default; proves later mutations
      // reached the disk too, not just the first.
      notifierA.toggleAutoScan();
      await _waitUntilSettles(settingsFileFor(docsDir), notifierA.state);

      // Session 2 (restart): a brand-new override list, store instance and
      // container — exactly what a fresh process builds. Nothing is shared
      // in memory; only the file is.
      final restartOverrides = await buildStartupOverrides(
        documentsDirectory: () async => docsDir,
      );
      final containerB = ProviderContainer(overrides: restartOverrides);
      addTearDown(containerB.dispose);
      final notifierB = containerB.read(settingsProvider.notifier);
      await notifierB.load();

      expect(notifierB.state.themeMode, ThemeMode.dark);
      expect(notifierB.state.scanIntervalHours, 6);
      expect(notifierB.state.autoScanEnabled, isTrue);
    });

    test('unreadable settings file behaves like an empty store', () async {
      settingsFileFor(docsDir).writeAsStringSync('{ broken');
      final overrides = await buildStartupOverrides(
        documentsDirectory: () async => docsDir,
      );
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      final notifier = container.read(settingsProvider.notifier);
      await notifier.load();
      expect(notifier.state, const AppSettings());
    });

    test(
      'store without a readable path never throws through the seam',
      () async {
        final store = FileSettingsPersistence(
          File('${docsDir.path}/missing/nested/app_settings.json'),
        );
        expect(await store.load(), isNull);
        await expectLater(store.save(const AppSettings()), completes);
      },
    );

    test('override building degrades to the in-memory default store', () async {
      final overrides = await buildStartupOverrides(
        documentsDirectory: () async =>
            throw UnsupportedError('path_provider unavailable'),
      );
      expect(overrides, isEmpty);
    });
  });

  // ------------------------------------------------------------------
  // (b) the auto-scan cadence finally has a production caller
  // ------------------------------------------------------------------

  group('auto-scan scheduling from the app root', () {
    Future<void> disposeApp(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    // Dispatch a lifecycle state the way the engine does, through the
    // 'flutter/lifecycle' platform message channel (the pattern Flutter's
    // own app_lifecycle_listener_test uses).
    Future<void> setAppLifecycleState(
      WidgetTester tester,
      AppLifecycleState state,
    ) async {
      final ByteData? message = const StringCodec().encodeMessage(
        state.toString(),
      );
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        message,
        (_) {},
      );
      await tester.pump();
    }

    Future<void> sendResume(WidgetTester tester) async {
      await setAppLifecycleState(tester, AppLifecycleState.inactive);
      await setAppLifecycleState(tester, AppLifecycleState.resumed);
    }

    Widget buildApp(List<Override> overrides) =>
        ProviderScope(overrides: overrides, child: const ScreenshotBrainApp());

    testWidgets('app start runs the due auto-scan through the real gate', (
      tester,
    ) async {
      late _RecordingScanNotifier scan;
      await tester.pumpWidget(
        buildApp([
          scanScreenshotsProvider.overrideWith(
            () => scan = _RecordingScanNotifier(DateTime(2026, 10, 11, 9)),
          ),
        ]),
      );
      await tester.pump();

      expect(scan.scanIfDueCalls, 1);
      expect(scan.scanRuns, 1);
      expect(scan.lastAutoScanAt, DateTime(2026, 10, 11, 9));

      await disposeApp(tester);
    });

    testWidgets('resume re-checks the cadence: not due before the interval, '
        'due once it elapsed (fake clock)', (tester) async {
      final start = DateTime(2026, 10, 11, 9);
      late _RecordingScanNotifier scan;
      await tester.pumpWidget(
        buildApp([
          scanScreenshotsProvider.overrideWith(
            () => scan = _RecordingScanNotifier(start),
          ),
        ]),
      );
      await tester.pump();
      expect(scan.scanRuns, 1);

      // Resume immediately: inside the 24 h interval, cadence must hold.
      await sendResume(tester);
      expect(scan.scanIfDueCalls, 2);
      expect(scan.scanRuns, 1);
      expect(scan.lastAutoScanAt, start);

      // Resume after the interval elapsed on the fake clock: scan fires.
      scan.fakeNow = start.add(const Duration(hours: 24));
      await sendResume(tester);
      expect(scan.scanIfDueCalls, 3);
      expect(scan.scanRuns, 2);
      expect(scan.lastAutoScanAt, start.add(const Duration(hours: 24)));

      await disposeApp(tester);
    });

    testWidgets('disabled auto scan fires no scan on start or resume', (
      tester,
    ) async {
      late _RecordingScanNotifier scan;
      await tester.pumpWidget(
        buildApp([
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              persistence: _FakeSettingsStore(
                const AppSettings(autoScanEnabled: false),
              ),
            ),
          ),
          scanScreenshotsProvider.overrideWith(
            () => scan = _RecordingScanNotifier(DateTime(2026, 10, 11, 9)),
          ),
        ]),
      );
      await tester.pump();
      await sendResume(tester);

      // The scheduler ran on both triggers, the gate vetoed both times.
      expect(scan.scanIfDueCalls, 2);
      expect(scan.scanRuns, 0);
      expect(scan.lastAutoScanAt, isNull);

      await disposeApp(tester);
    });

    testWidgets('launch scan waits for the persisted settings before gating', (
      tester,
    ) async {
      // Regression guard: the restore is asynchronous behind the seam. If the
      // scheduler raced it, a disabled-on-disk auto scan would run once with
      // the enabled default on every cold start. The delayed load makes the
      // race observable: nothing may be gated on settings before it resolves.
      // Pre-create the notifier (instead of a `late` capture) so it can be
      // observed while the slow restore is still pending, before the scan
      // provider is first read.
      final scan = _RecordingScanNotifier(DateTime(2026, 10, 11, 9));
      await tester.pumpWidget(
        buildApp([
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              persistence: _SlowSettingsStore(
                const AppSettings(autoScanEnabled: false),
                const Duration(milliseconds: 50),
              ),
            ),
          ),
          scanScreenshotsProvider.overrideWith(() => scan),
        ]),
      );
      await tester.pump();

      // Restore still pending: the gate has not been consulted yet.
      expect(scan.scanIfDueCalls, 0);
      expect(scan.scanRuns, 0);

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // Restored value says disabled, so the launch pass must not scan.
      expect(scan.scanIfDueCalls, 1);
      expect(scan.scanRuns, 0);
      expect(scan.lastAutoScanAt, isNull);

      await disposeApp(tester);
    });

    testWidgets('lifecycle listener is disposed with the app widget', (
      tester,
    ) async {
      late _RecordingScanNotifier scan;
      await tester.pumpWidget(
        buildApp([
          scanScreenshotsProvider.overrideWith(
            () => scan = _RecordingScanNotifier(DateTime(2026, 10, 11, 9)),
          ),
        ]),
      );
      await tester.pump();
      await sendResume(tester);
      final callsBeforeUnmount = scan.scanIfDueCalls;
      expect(callsBeforeUnmount, greaterThan(1));

      await disposeApp(tester);
      await sendResume(tester);

      // No resume reaches the scheduler after the state object is disposed.
      expect(scan.scanIfDueCalls, callsBeforeUnmount);
    });
  });

  // ------------------------------------------------------------------
  // (c) DatabaseService boot-state invariants, exercised through fakes
  // ------------------------------------------------------------------

  group('DatabaseService open-once / close semantics', () {
    setUp(() {
      DatabaseService.testDocumentsDirectory = () async =>
          Directory('/virtual/screenshot-brain-docs');
    });
    tearDown(() async {
      DatabaseService.testOpener = null;
      DatabaseService.testDocumentsDirectory = null;
      await DatabaseService.close();
    });

    test(
      'uninitialized state: db throws, maybeDb null, isInitialized false',
      () {
        expect(DatabaseService.isInitialized, isFalse);
        expect(DatabaseService.maybeDb, isNull);
        expect(() => DatabaseService.db, throwsStateError);
        expect(() => DatabaseService.instance, throwsStateError);
      },
    );

    test('init() is a no-op on an already-open database', () async {
      var openCalls = 0;
      final fake = _FakeIsar();
      DatabaseService.testOpener = (schemas, directoryPath) {
        openCalls++;
        expect(directoryPath, '/virtual/screenshot-brain-docs');
        expect(schemas, DatabaseService.collectionSchemas);
        return Future.value(fake);
      };

      await DatabaseService.init();
      await DatabaseService.init();

      expect(openCalls, 1);
      expect(DatabaseService.isInitialized, isTrue);
      expect(DatabaseService.db, same(fake));
      expect(DatabaseService.instance, same(fake));
      expect(await DatabaseService.ready(), same(fake));
    });

    test(
      'concurrent init() calls share one open and all observe success',
      () async {
        var openCalls = 0;
        final fake = _FakeIsar();
        DatabaseService.testOpener = (_, _) async {
          openCalls++;
          await Future<void>.delayed(Duration.zero);
          return fake;
        };

        await Future.wait([DatabaseService.init(), DatabaseService.init()]);

        expect(openCalls, 1, reason: 'two Isar instances must never open');
        expect(DatabaseService.db, same(fake));
      },
    );

    test('a failed open rethrows, leaves no half-initialised singleton, '
        'and stays retryable', () async {
      var attempts = 0;
      late final _FakeIsar recovered;
      recovered = _FakeIsar();
      DatabaseService.testOpener = (_, _) {
        attempts++;
        if (attempts == 1) {
          return Future.error(StateError('native open failed'));
        }
        return Future.value(recovered);
      };

      // Both concurrent callers see the failure — errors must not surface
      // as a silent null.
      await expectLater(
        Future.wait([DatabaseService.init(), DatabaseService.init()]),
        throwsStateError,
      );
      expect(attempts, 1);
      expect(DatabaseService.isInitialized, isFalse);
      expect(DatabaseService.maybeDb, isNull);

      // The guard reset, so a later caller can retry — and succeeds.
      await DatabaseService.init();
      expect(attempts, 2);
      expect(DatabaseService.db, same(recovered));
    });

    test('close() during an in-flight open shuts the orphan down instead of '
        'resurrecting the singleton', () async {
      final completer = Completer<Isar>();
      final orphan = _FakeIsar();
      DatabaseService.testOpener = (_, _) => completer.future;

      final pending = DatabaseService.init();
      await DatabaseService.close();
      // The open lands after close(): it must not install itself.
      completer.complete(orphan);
      await pending;

      expect(orphan.closeCount, 1);
      expect(DatabaseService.isInitialized, isFalse);
      expect(DatabaseService.maybeDb, isNull);
      expect(() => DatabaseService.db, throwsStateError);

      // A fresh init() afterwards opens cleanly on the new generation.
      final fresh = _FakeIsar();
      DatabaseService.testOpener = (_, _) async => fresh;
      await DatabaseService.init();
      expect(DatabaseService.db, same(fresh));
    });

    test(
      'a failed open after close() does not clear a newer pending open',
      () async {
        var generation = 0;
        final first = Completer<Isar>();
        final second = Completer<Isar>();
        final secondFake = _FakeIsar();
        DatabaseService.testOpener = (_, _) {
          generation++;
          return generation == 1 ? first.future : second.future;
        };

        final pendingFirst = DatabaseService.init();
        await DatabaseService.close();
        final pendingSecond = DatabaseService.init();
        first.completeError(
          StateError('late failure must not clobber the retry'),
        );
        await expectLater(pendingFirst, throwsStateError);

        second.complete(secondFake);
        await pendingSecond;
        expect(DatabaseService.db, same(secondFake));
      },
    );

    test(
      'close() resets the singleton and is safe to call repeatedly',
      () async {
        final fake = _FakeIsar();
        DatabaseService.testOpener = (_, _) async => fake;
        await DatabaseService.init();

        await DatabaseService.close();
        await DatabaseService.close();

        expect(fake.closeCount, 1);
        expect(DatabaseService.isInitialized, isFalse);
        expect(() => DatabaseService.db, throwsStateError);
      },
    );

    test('path helper and collection options are pinned', () {
      expect(
        DatabaseService.databaseDirectoryPath(Directory('/some/docs')),
        '/some/docs',
      );
      expect(
        DatabaseService.collectionSchemas.map((s) => s.name),
        containsAll(<String>['ScreenshotModel', 'ExpenseModel']),
      );
    });
  });

  // ------------------------------------------------------------------
  // sanity: the wired store content actually written on disk
  // ------------------------------------------------------------------

  group('FileSettingsPersistence against the real filesystem', () {
    test(
      'writes valid JSON and reloads it through the production class',
      () async {
        final docsDir = Directory.systemTemp.createTempSync('sb-store-test');
        addTearDown(() => docsDir.deleteSync(recursive: true));
        final store = FileSettingsPersistence(settingsFileFor(docsDir));

        const settings = AppSettings(
          autoScanEnabled: false,
          ocrOnWifiOnly: true,
          scanIntervalHours: 3,
          themeMode: ThemeMode.light,
        );
        await store.save(settings);

        final raw = await settingsFileFor(docsDir).readAsString();
        expect(jsonDecode(raw), isA<Map<String, dynamic>>());
        expect(await store.load(), settings);
      },
    );
  });
}
