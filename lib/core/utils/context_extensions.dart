import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  /// Quick access to the Theme.
  ThemeData get theme => Theme.of(this);

  /// Quick access to the ColorScheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to TextTheme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to MediaQuery sizing.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Quick access to MediaQuery screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Quick access to MediaQuery screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Quick access to view padding (e.g. for safe area insets).
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Checks if the keyboard is currently open by checking bottom view insets.
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Removes current focus (closes keyboard).
  void unfocus() => FocusScope.of(this).unfocus();
}
