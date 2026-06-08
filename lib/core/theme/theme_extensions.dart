import 'package:flutter/material.dart';

class ScreenshotBrainThemeExtension extends ThemeExtension<ScreenshotBrainThemeExtension> {
  final Color background;
  final Color surface;
  final Color card;
  final Color elevated;
  final Color border;
  final Color borderLight;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color primaryDim;
  final Color secondaryDim;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const ScreenshotBrainThemeExtension({
    required this.background,
    required this.surface,
    required this.card,
    required this.elevated,
    required this.border,
    required this.borderLight,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.primaryDim,
    required this.secondaryDim,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  @override
  ThemeExtension<ScreenshotBrainThemeExtension> copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? elevated,
    Color? border,
    Color? borderLight,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? primaryDim,
    Color? secondaryDim,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return ScreenshotBrainThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      primaryDim: primaryDim ?? this.primaryDim,
      secondaryDim: secondaryDim ?? this.secondaryDim,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  ThemeExtension<ScreenshotBrainThemeExtension> lerp(
    ThemeExtension<ScreenshotBrainThemeExtension>? other,
    double t,
  ) {
    if (other is! ScreenshotBrainThemeExtension) return this;
    return ScreenshotBrainThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t)!,
      secondaryDim: Color.lerp(secondaryDim, other.secondaryDim, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

extension SbTheme on BuildContext {
  ScreenshotBrainThemeExtension get sb => Theme.of(this).extension<ScreenshotBrainThemeExtension>()!;
}
