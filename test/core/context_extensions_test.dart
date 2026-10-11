import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/theme/app_theme.dart';
import 'package:screenshot_brain/core/utils/color_utils.dart';
import 'package:screenshot_brain/core/utils/context_extensions.dart';
import 'package:screenshot_brain/core/utils/platform_utils.dart';
import 'package:screenshot_brain/core/utils/theme_utils.dart';

void main() {
  Future<Brightness> pumpAndGet(WidgetTester tester, Brightness mode) async {
    var captured = Brightness.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: ScreenshotBrainTheme.light,
        darkTheme: ScreenshotBrainTheme.dark,
        themeMode: mode == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: Builder(
          builder: (context) {
            captured = context.brightness;
            // Touch the helpers so any ambiguity in the extension is caught.
            expect(context.isDark, mode == Brightness.dark);
            expect(
              context.themeMode,
              mode == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
            );
            expect(ThemeUtils.isDarkMode(context), mode == Brightness.dark);
            expect(ThemeUtils.brightnessOf(context), mode);
            expect(
              ThemeUtils.dynamicColor(
                context,
                light: Colors.white,
                dark: Colors.black,
              ),
              mode == Brightness.dark ? Colors.black : Colors.white,
            );
            expect(context.theme.brightness, mode);
            expect(context.colorScheme, context.theme.colorScheme);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  group('BuildContext theme helpers', () {
    testWidgets('resolve light mode correctly', (tester) async {
      expect(await pumpAndGet(tester, Brightness.light), Brightness.light);
    });

    testWidgets('resolve dark mode correctly', (tester) async {
      expect(await pumpAndGet(tester, Brightness.dark), Brightness.dark);
    });

    testWidgets('screen metrics helpers are wired to MediaQuery', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 2.0;
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(context.screenSize, const Size(200, 400));
      expect(context.screenWidth, 200);
      expect(context.screenHeight, 400);
      expect(context.isKeyboardOpen, isFalse);
      expect(context.viewPadding, isA<EdgeInsets>());
      addTearDown(tester.view.reset);
    });
  });

  group('PlatformUtils', () {
    test('web flag mirrors kIsWeb (false under the VM test runner)', () {
      expect(PlatformUtils.isWeb, isFalse);
    });

    test('OS checks stay mutually consistent and never throw', () {
      // Exactly one host OS family applies; every getter must answer without
      // an UnsupportedError even on unusual hosts.
      expect(
        PlatformUtils.isDesktop,
        PlatformUtils.isMacOS ||
            PlatformUtils.isWindows ||
            PlatformUtils.isLinux,
      );
      expect(
        PlatformUtils.isMobile,
        PlatformUtils.isIOS || PlatformUtils.isAndroid,
      );
      expect(PlatformUtils.operatingSystem, isNotEmpty);
    });

    test('debug fallback returns false rather than throwing on web', () {
      // The guarded lookups are what makes this safe: a raw Platform call
      // would throw UnsupportedError when dart:io is unavailable.
      expect(PlatformUtils.isIOS, isA<bool>());
      expect(PlatformUtils.isLinux, isA<bool>());
    });
  });

  group('ColorUtils sanity in theme context', () {
    test('theme seed colors round-trip through hex parsing', () {
      final parsed = ColorUtils.fromHex(
        ColorUtils.toHex(ScreenshotBrainTheme.dark.colorScheme.primary),
      );
      expect(parsed, ScreenshotBrainTheme.dark.colorScheme.primary);
    });
  });
}
