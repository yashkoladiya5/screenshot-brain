import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot_brain/app.dart';
import 'package:screenshot_brain/features/settings/providers/settings_provider.dart';
import 'package:screenshot_brain/features/splash/screens/splash_screen.dart';

void main() {
  // Tearing the tree down disposes the splash's cancelable navigation Timer
  // and its AnimationController, so the test ends without pending timers —
  // the regression that previously failed this suite ("A Timer is still
  // pending").
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('app root boots into the branded splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ScreenshotBrainApp()));
    await tester.pump();

    // The router starts at '/' and the splash renders its identity.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Screenshot Brain'), findsOneWidget);
    expect(find.text('Your intelligent screenshot assistant'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The entrance animation is running, so the brand starts faded in.
    // Scoped to the splash itself: the Navigator's route transition also
    // owns a (settled) FadeTransition elsewhere in the tree.
    final splashFade = find.descendant(
      of: find.byType(SplashScreen),
      matching: find.byType(FadeTransition),
    );
    expect(
      tester.widget<FadeTransition>(splashFade.first).opacity.value,
      lessThan(1.0),
    );

    await disposeApp(tester);
  });

  testWidgets('app root applies the theme mode from settings', (tester) async {
    final settings = SettingsNotifier();
    settings.setThemeMode(ThemeMode.dark);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsProvider.overrideWith((ref) => settings)],
        child: const ScreenshotBrainApp(),
      ),
    );
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(app.themeMode, ThemeMode.dark);
    expect(app.title, 'Screenshot Brain');

    await disposeApp(tester);
  });

  testWidgets('splash brand fades in over its entrance animation', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ScreenshotBrainApp()));
    await tester.pump();

    final splashFade = find.descendant(
      of: find.byType(SplashScreen),
      matching: find.byType(FadeTransition),
    );
    // Capture plain values: the Animation object mutates in place across
    // pumps, so holding the widget/reference would compare equal trivially.
    final startValue = tester
        .widget<FadeTransition>(splashFade.first)
        .opacity
        .value;
    expect(startValue, lessThan(1.0));

    // Let most of the 800 ms entrance animation run: opacity must climb.
    // (No pumpAndSettle: the splash spinner never settles.)
    await tester.pump(const Duration(milliseconds: 400));
    final progressedValue = tester
        .widget<FadeTransition>(splashFade.first)
        .opacity
        .value;
    expect(progressedValue, greaterThan(startValue));

    // Teardown cancels the 2 s navigation timer; the suite would otherwise
    // fail with "A Timer is still pending".
    await disposeApp(tester);
  });
}
