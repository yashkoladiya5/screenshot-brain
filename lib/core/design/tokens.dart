import 'package:flutter/material.dart';

class SBSpacing {
  SBSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  /// Completes the scale past [massive] for section-level gaps on the
  /// dashboard and category grids.
  static const double colossal = 64;
}

class SBRadius {
  SBRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;

  /// Continues the radius scale past [xxl] (24) for larger sheets/cards.
  static const double xxxl = 24;
  static const double full = 999;
}

class SBSizes {
  SBSizes._();

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 28;
  static const double iconXxl = 32;

  static const double avatarSm = 28;
  static const double avatarMd = 36;
  static const double avatarLg = 44;

  static const double chipHeight = 32;
  static const double buttonHeight = 48;
  static const double inputHeight = 48;
  static const double minTouchTarget = 44;

  static const double dividerThickness = 1;
  static const double borderWidth = 1;
}

/// Typographic scale consumed by [ScreenshotBrainTheme] when building the
/// [TextTheme], and available to dashboard/category screens for one-off
/// styles (stat values, section labels, captions).
class SBTypography {
  SBTypography._();

  static const double displayLarge = 34;
  static const double displayMedium = 28;
  static const double displaySmall = 24;

  static const double headlineLarge = 22;
  static const double headlineMedium = 20;
  static const double headlineSmall = 18;

  static const double titleLarge = 17;
  static const double titleMedium = 15;
  static const double titleSmall = 14;

  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 13;

  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;

  /// Larger numeric emphasis used by dashboard stat tiles.
  static const double statValue = 28;
  static const double caption = 11;

  static const FontWeight weightBold = FontWeight.w700;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightRegular = FontWeight.w400;

  static const double heightTight = 1.2;
  static const double heightNormal = 1.3;
  static const double heightRelaxed = 1.5;
}

class SBAnimations {
  SBAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  /// Page/sheet transitions that need more weight than [slow].
  static const Duration deliberate = Duration(milliseconds: 450);

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  /// Material 3 emphasized easing for shared-axis style transitions.
  static const Curve emphasized = Curves.fastOutSlowIn;

  static const double staggerDelay = 40;
}
