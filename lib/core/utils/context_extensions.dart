import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  /// Quick access to the Theme.
  ThemeData get theme => Theme.of(this);

  /// Quick access to the ColorScheme.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to TextTheme.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// The brightness the app is currently rendering with (after the user's
  /// [ThemeMode] selection has been resolved by [MaterialApp]).
  Brightness get brightness => Theme.of(this).brightness;

  /// Whether the rendered theme is dark — mirrors the inline
  /// `Theme.of(context).brightness == Brightness.dark` checks screens use.
  bool get isDark => brightness == Brightness.dark;

  /// The rendered brightness expressed as a [ThemeMode] (useful when feeding
  /// APIs that expect a mode rather than a resolved brightness).
  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

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
