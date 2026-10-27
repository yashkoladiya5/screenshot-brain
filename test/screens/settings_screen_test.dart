import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/theme/app_theme.dart';
import 'package:screenshot_brain/features/permissions/screens/permission_screen.dart';
import 'package:screenshot_brain/features/settings/providers/settings_provider.dart';
import 'package:screenshot_brain/features/settings/screens/settings_screen.dart';
import 'package:screenshot_brain/services/permission_service.dart';

/// Minimal in-memory fake behind the [SettingsPersistence] seam (no plugins,
/// no filesystem) shared by the screen tests below.
class _FakeSettingsPersistence implements SettingsPersistence {
  _FakeSettingsPersistence({this.stored});

  AppSettings? stored;
  final List<AppSettings> saves = [];

  @override
  Future<AppSettings?> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    saves.add(settings);
    stored = settings;
  }
}

/// Settles async restore/save microtasks inside the widget tree.
Future<void> _settle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 800));

Widget _wrapSettings(Widget child, List<Override> overrides) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: ScreenshotBrainTheme.light, home: child),
    );

/// Selected value of the theme radios currently rendered: the ancestor
/// RadioGroup holds the group value, and a tile is selected when its own
/// value equals it.
ThemeMode? _selectedTheme(WidgetTester tester) {
  final group = tester.widget<RadioGroup<ThemeMode>>(
    find
        .ancestor(
          of: find.byType(RadioListTile<ThemeMode>),
          matching: find.byType(RadioGroup<ThemeMode>),
        )
        .first,
  );
  final selected = group.groupValue;
  if (selected == null) return null;
  final tileSelected = find.byWidgetPredicate(
    (w) => w is RadioListTile<ThemeMode> && w.value == selected,
  );
  return tileSelected.evaluate().isNotEmpty ? selected : null;
}

void main() {
  group('SettingsScreen persistence', () {
    testWidgets('auto-scan switch persists through the notifier seam', (
      tester,
    ) async {
      final fake = _FakeSettingsPersistence();
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
      await tester.tap(find.byType(Switch).first);
      await _settle(tester);

      // The switch wrote through the notifier (and thus persistence), not
      // just local widget state.
      expect(fake.saves, hasLength(1));
      expect(fake.saves.single.autoScanEnabled, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    });

    testWidgets('Wi-Fi-only switch persists the flipped bool', (tester) async {
      final fake = _FakeSettingsPersistence();
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      await tester.tap(find.byType(Switch).last);
      await _settle(tester);

      expect(fake.saves.single.ocrOnWifiOnly, isTrue);
    });

    testWidgets('theme radio writes the ThemeMode enum, kept across navigation', (
      tester,
    ) async {
      final fake = _FakeSettingsPersistence();
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      final darkTile = find.byWidgetPredicate(
        (w) => w is RadioListTile<ThemeMode> && w.value == ThemeMode.dark,
      );
      await tester.ensureVisible(darkTile);
      await tester.tap(darkTile);
      await _settle(tester);

      expect(fake.stored!.themeMode, ThemeMode.dark);

      // Navigate away and back: the selection is still dark (same store),
      // i.e. the change really persisted, not just repainted.
      await tester.pumpWidget(
        _wrapSettings(const Scaffold(body: Text('elsewhere')), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      // The Appearance radios live below the fold in the lazy ListView.
      final darkAgain = find.byWidgetPredicate(
        (w) => w is RadioListTile<ThemeMode> && w.value == ThemeMode.dark,
      );
      await tester.scrollUntilVisible(darkAgain, 300,
          scrollable: find.byType(Scrollable).first);
      expect(_selectedTheme(tester), ThemeMode.dark);
    });

    testWidgets('interval picker writes whole hours that reach the store', (
      tester,
    ) async {
      final fake = _FakeSettingsPersistence();
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      await tester.tap(find.text('Scan Interval'));
      await _settle(tester);
      await tester.tap(find.text('48 hours'));
      await _settle(tester);

      // Same unit on both sides of the seam: the picker writes hours and the
      // store holds hours (the scanner gate consumes Duration(hours: ...)).
      expect(fake.stored!.scanIntervalHours, 48);
      expect(find.text('Every 48 hours'), findsOneWidget);
    });

    testWidgets('restart over a seeded store shows the stored settings, not defaults', (
      tester,
    ) async {
      // A previous session saved dark theme, 6h cadence, auto-scan off.
      // The screen must render THAT state after a restart.
      final fake = _FakeSettingsPersistence(
        stored: const AppSettings(
          autoScanEnabled: false,
          scanIntervalHours: 6,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
      expect(find.text('Every 6 hours'), findsOneWidget);
      await tester.ensureVisible(find.text('Always use the dark theme'));
      expect(_selectedTheme(tester), ThemeMode.dark);
    });

    testWidgets('rescan dialog dismisses without mutating settings', (
      tester,
    ) async {
      final fake = _FakeSettingsPersistence();
      await tester.pumpWidget(
        _wrapSettings(const SettingsScreen(), [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(persistence: fake),
          ),
        ]),
      );
      await _settle(tester);

      final rescanTile = find.text('Rescan All Screenshots');
      await tester.scrollUntilVisible(rescanTile, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(rescanTile);
      await _settle(tester);
      expect(find.text('Rescan All?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await _settle(tester);
      expect(find.text('Rescan All?'), findsNothing);
      expect(fake.saves, isEmpty);
    });
  });

  group('PermissionScreen granted-state guard (double-prompt defect)', () {
    testWidgets('a re-check that lands on granted shows Continue and never '
        'fires the request seam', (tester) async {
      // Real trigger: user is in the 'restricted' state and presses 'Re-check
      // Access'; the check comes back GRANTED. Navigation is requested but
      // the screen stays interactive for a moment (async route change / a
      // no-op navigation seam). From there the button must NOT offer
      // 'Grant Access' nor invoke the request seam — that is the double
      // prompt the screen's own contract forbids.
      var checkCalls = 0;
      var requestCalls = 0;
      var navigations = 0;
      final checkQueue = <GalleryPermissionStatus>[
        GalleryPermissionStatus.restricted,
        GalleryPermissionStatus.granted,
      ];

      Widget build() => MaterialApp(
        home: PermissionScreen(
          checkPermission: () async {
            final status = checkQueue.first;
            if (checkQueue.length > 1) {
              checkQueue.removeAt(0);
            }
            checkCalls++;
            return GalleryPermissionResult(status);
          },
          requestPermission: () async {
            requestCalls++;
            return const GalleryPermissionResult(
              GalleryPermissionStatus.granted,
            );
          },
          purposeExplainer: PermissionService.purposeExplanationFor,
          onPermissionGranted: (_) => navigations++,
        ),
      );

      await tester.pumpWidget(build());
      await _settle(tester);
      expect(find.text('Re-check Access'), findsOneWidget);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await _settle(tester);
      expect(checkCalls, 2);
      expect(navigations, 1);

      // Granted UI: the primary action must be 'Continue', never a new
      // permission request.
      expect(find.text('Grant Access'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await _settle(tester);
      expect(requestCalls, 0);
      expect(navigations, 2);
    });

    testWidgets('denied state still requests exactly once (fix must not '
        'break the normal path)', (tester) async {
      var requestCalls = 0;
      var navigations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionScreen(
            checkPermission: () async =>
                const GalleryPermissionResult(GalleryPermissionStatus.denied),
            requestPermission: () async {
              requestCalls++;
              return const GalleryPermissionResult(
                GalleryPermissionStatus.granted,
              );
            },
            purposeExplainer: PermissionService.purposeExplanationFor,
            onPermissionGranted: (_) => navigations++,
          ),
        ),
      );
      await _settle(tester);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await _settle(tester);
      expect(requestCalls, 1);
      expect(navigations, 1);
      // After the request lands granted, the screen (still visible until the
      // route swap completes) must already show the safe 'Continue' label.
      expect(find.text('Grant Access'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
