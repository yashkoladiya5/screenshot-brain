import 'package:flutter/material.dart';

class ThemeUtils {
  /// Checks if the current app theme is dark.
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// The resolved brightness of the current app theme.
  static Brightness brightnessOf(BuildContext context) {
    return Theme.of(context).brightness;
  }

  /// Returns a specific color based on the current theme mode.
  static Color dynamicColor(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) {
    return isDarkMode(context) ? dark : light;
  }
}
