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
}

class SBRadius {
  SBRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
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
}

class SBAnimations {
  SBAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
}
