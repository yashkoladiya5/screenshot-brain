import 'package:flutter/material.dart';

class ColorUtils {
  /// Darkens a given color by the given percentage (0.0 to 1.0)
  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    
    // In newer flutter versions, HSLColor is standard for this
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    
    return hslDark.toColor();
  }

  /// Lightens a given color by the given percentage (0.0 to 1.0)
  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    
    return hslLight.toColor();
  }

  /// Creates a random color with full opacity
  static Color randomColor() {
    return Color((0xFFFFFFFF & DateTime.now().microsecondsSinceEpoch) | 0xFF000000);
  }
}
