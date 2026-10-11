import 'package:flutter/material.dart';

class ColorUtils {
  /// Parses a hex color string into a [Color].
  ///
  /// Accepts `#RGB`, `#RRGGBB` and `#AARRGGBB` (Flutter's ARGB order), with
  /// or without the leading `#`. A 3-digit shorthand is expanded per CSS
  /// (`#abc` -> `#aabbcc`) and gets full alpha; a 6-digit value gets `FF`
  /// alpha so hex colors never silently turn translucent.
  ///
  /// Throws a [FormatException] for anything else (wrong length, non-hex
  /// digits, empty input).
  static Color fromHex(String hex) {
    var value = hex.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }

    String digits;
    switch (value.length) {
      case 3:
        // #RGB shorthand: duplicate each nibble and add full alpha.
        digits =
            'FF${value[0]}${value[0]}${value[1]}${value[1]}${value[2]}${value[2]}';
      case 6:
        // #RRGGBB: opaque by default.
        digits = 'FF$value';
      case 8:
        // #AARRGGBB: alpha channel is explicit.
        digits = value;
      default:
        throw FormatException('Invalid hex color', hex);
    }

    final parsed = int.tryParse(digits, radix: 16);
    if (parsed == null) {
      throw FormatException('Invalid hex color', hex);
    }
    return Color(parsed);
  }

  /// Serializes a [Color] back to `#AARRGGBB` uppercase hex.
  static String toHex(Color color, {bool includeAlpha = true}) {
    final value = color.toARGB32();
    if (includeAlpha) {
      return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

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
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );

    return hslLight.toColor();
  }

  /// Creates a random color with full opacity
  static Color randomColor() {
    return Color(
      (0xFFFFFFFF & DateTime.now().microsecondsSinceEpoch) | 0xFF000000,
    );
  }
}
