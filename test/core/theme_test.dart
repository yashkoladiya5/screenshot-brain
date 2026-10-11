import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/design/tokens.dart';
import 'package:screenshot_brain/core/theme/app_colors.dart';
import 'package:screenshot_brain/core/theme/app_theme.dart';
import 'package:screenshot_brain/core/theme/theme_extensions.dart';

/// WCAG relative luminance for sRGB colors.
double _luminance(Color color) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.7).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.x contrast ratio between two opaque colors (1.0 .. 21.0).
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lightest = math.max(la, lb);
  final darkest = math.min(la, lb);
  return (lightest + 0.05) / (darkest + 0.05);
}

void main() {
  final light = ScreenshotBrainTheme.light;
  final dark = ScreenshotBrainTheme.dark;

  group('ThemeData builds for both brightnesses', () {
    test('light and dark expose the matching brightness', () {
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
    });

    test('light theme is a real theme, not a copy of dark', () {
      expect(
        light.scaffoldBackgroundColor,
        isNot(dark.scaffoldBackgroundColor),
      );
      expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
      expect(
        light.textTheme.bodyLarge!.color,
        isNot(dark.textTheme.bodyLarge!.color),
      );
      expect(light.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(light.colorScheme.surface, Colors.white);
    });

    test('both themes carry the custom ThemeExtension', () {
      final lightExt = light.extension<ScreenshotBrainThemeExtension>()!;
      final darkExt = dark.extension<ScreenshotBrainThemeExtension>()!;
      expect(lightExt.card, AppColors.lightCard);
      expect(lightExt.textPrimary, AppColors.lightTextPrimary);
      expect(lightExt.shimmerBase, AppColors.lightShimmerBase);
      expect(darkExt.card, AppColors.card);
      expect(darkExt.textPrimary, AppColors.textPrimary);
      expect(darkExt.primaryDim, AppColors.primaryDim);
    });

    test('extension copyWith/lerp remain functional', () {
      final ext = dark.extension<ScreenshotBrainThemeExtension>()!;
      final copy =
          ext.copyWith(card: Colors.red) as ScreenshotBrainThemeExtension;
      expect(copy.card, Colors.red);
      final same = ext.copyWith() as ScreenshotBrainThemeExtension;
      expect(same.card, ext.card);
      final lerped = ext.lerp(
        light.extension<ScreenshotBrainThemeExtension>(),
        0,
      );
      expect(lerped, isA<ScreenshotBrainThemeExtension>());
    });
  });

  group('ColorScheme parity with AppColors', () {
    test('dark scheme derives from the dark AppColors', () {
      final s = dark.colorScheme;
      expect(s.primary, AppColors.primary);
      expect(s.onPrimary, AppColors.onPrimary);
      expect(s.primaryContainer, AppColors.primaryContainer);
      expect(s.secondary, AppColors.secondary);
      expect(s.error, AppColors.error);
      expect(s.errorContainer, AppColors.errorContainer);
      expect(s.onErrorContainer, AppColors.onErrorContainer);
      expect(s.surface, AppColors.surface);
      expect(s.onSurface, AppColors.textPrimary);
      expect(s.surfaceContainerHighest, AppColors.card);
      expect(s.onSurfaceVariant, AppColors.textSecondary);
      expect(s.outline, AppColors.border);
      expect(s.inverseSurface, AppColors.elevated);
    });

    test('light scheme derives from the light AppColors', () {
      final s = light.colorScheme;
      expect(s.primary, AppColors.lightPrimary);
      expect(s.primaryContainer, AppColors.lightPrimaryContainer);
      expect(s.onPrimaryContainer, AppColors.lightOnPrimaryContainer);
      expect(s.secondary, AppColors.lightSecondary);
      expect(s.error, AppColors.lightError);
      expect(s.errorContainer, AppColors.lightErrorContainer);
      expect(s.onErrorContainer, AppColors.lightOnErrorContainer);
      expect(s.surface, AppColors.lightSurface);
      expect(s.onSurface, AppColors.lightTextPrimary);
    });

    test('onErrorContainer is not the container color itself', () {
      // Regression: the old light/dark schemes set onErrorContainer equal to
      // errorContainer, making error foreground invisible.
      expect(
        dark.colorScheme.onErrorContainer,
        isNot(dark.colorScheme.errorContainer),
      );
      expect(
        light.colorScheme.onErrorContainer,
        isNot(light.colorScheme.errorContainer),
      );
    });
  });

  group('Contrast sanity (WCAG)', () {
    void checkPair(
      ThemeData theme,
      String label,
      Color fg,
      Color bg, {
      double min = 4.5,
    }) {
      final ratio = contrastRatio(fg, bg);
      expect(
        ratio >= min,
        isTrue,
        reason: '$label contrast ${ratio.toStringAsFixed(2)} < $min',
      );
    }

    for (final theme in [light, dark]) {
      final name = theme.brightness == Brightness.dark ? 'dark' : 'light';
      final s = theme.colorScheme;

      test('$name: body text on surface meets 4.5:1', () {
        checkPair(theme, 'onSurface/surface', s.onSurface, s.surface);
        checkPair(
          theme,
          'onSurfaceVariant/card',
          s.onSurfaceVariant,
          s.surfaceContainerHighest,
        );
      });

      test('$name: button + appbar foregrounds meet large-text 3:1', () {
        checkPair(theme, 'onPrimary/primary', s.onPrimary, s.primary, min: 3.0);
      });

      test('$name: error foreground on error container is visible', () {
        checkPair(
          theme,
          'onErrorContainer/errorContainer',
          s.onErrorContainer,
          s.errorContainer,
        );
      });

      test('$name: textTheme colors match the scheme surfaces', () {
        checkPair(
          theme,
          'bodyLarge on scaffold',
          theme.textTheme.bodyLarge!.color!,
          theme.scaffoldBackgroundColor,
        );
        checkPair(
          theme,
          'titleMedium on card',
          theme.textTheme.titleMedium!.color!,
          s.surfaceContainerHighest,
        );
      });
    }
  });

  group('Theme derives shapes and type scale from design tokens', () {
    test('card / FAB / input radii map onto SBRadius steps', () {
      final cardShape = light.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(SBRadius.xl));
      final inputShape =
          light.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      expect(inputShape.borderRadius, BorderRadius.circular(SBRadius.lg));
      final fabShape =
          light.floatingActionButtonTheme.shape! as RoundedRectangleBorder;
      expect(fabShape.borderRadius, BorderRadius.circular(SBRadius.xl));
    });

    test('textTheme font sizes are exactly the SBTypography scale', () {
      for (final theme in [light, dark]) {
        final t = theme.textTheme;
        expect(t.displayLarge!.fontSize, SBTypography.displayLarge);
        expect(t.displaySmall!.fontSize, SBTypography.displaySmall);
        expect(t.headlineMedium!.fontSize, SBTypography.headlineMedium);
        expect(t.titleLarge!.fontSize, SBTypography.titleLarge);
        expect(t.bodyLarge!.fontSize, SBTypography.bodyLarge);
        expect(t.bodySmall!.fontSize, SBTypography.bodySmall);
        expect(t.labelSmall!.fontSize, SBTypography.labelSmall);
      }
    });

    test('divider color tracks the per-theme border token', () {
      expect(light.dividerTheme.color, AppColors.lightBorderLight);
      expect(dark.dividerTheme.color, AppColors.borderLight);
    });

    test('new token steps exist and extend the scales monotonically', () {
      expect(SBRadius.xxxl, greaterThan(SBRadius.xxl));
      expect(SBSpacing.colossal, greaterThan(SBSpacing.massive));
      expect(SBTypography.statValue, SBTypography.displayMedium);
      expect(SBAnimations.deliberate, greaterThan(SBAnimations.slow));
    });
  });
}
