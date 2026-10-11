import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/color_utils.dart';

void main() {
  group('ColorUtils.fromHex', () {
    test('parses #RRGGBB with full alpha', () {
      expect(ColorUtils.fromHex('#FF8800'), const Color(0xFFFF8800));
      expect(ColorUtils.fromHex('0F172A'), const Color(0xFF0F172A));
    });

    test('parses #RGB shorthand by expanding each nibble', () {
      expect(ColorUtils.fromHex('#F00'), const Color(0xFFFF0000));
      expect(ColorUtils.fromHex('#abc'), const Color(0xFFAABBCC));
      expect(ColorUtils.fromHex('#fff'), const Color(0xFFFFFFFF));
    });

    test('parses #AARRGGBB keeping explicit alpha', () {
      expect(ColorUtils.fromHex('#80FF0000'), const Color(0x80FF0000));
      expect(ColorUtils.fromHex('#00112233'), const Color(0x00112233));
    });

    test('is case-insensitive and tolerates whitespace', () {
      expect(ColorUtils.fromHex(' #ff8800 '), const Color(0xFFFF8800));
      expect(ColorUtils.fromHex('#fF8800'), ColorUtils.fromHex('#FF8800'));
    });

    test('rejects malformed input with FormatException', () {
      expect(() => ColorUtils.fromHex(''), throwsFormatException);
      expect(() => ColorUtils.fromHex('#'), throwsFormatException);
      expect(() => ColorUtils.fromHex('#12'), throwsFormatException);
      expect(() => ColorUtils.fromHex('#1234'), throwsFormatException);
      expect(() => ColorUtils.fromHex('#12345'), throwsFormatException);
      expect(() => ColorUtils.fromHex('#1234567'), throwsFormatException);
      expect(() => ColorUtils.fromHex('#GGHHII'), throwsFormatException);
      expect(() => ColorUtils.fromHex('#-ABC01'), throwsFormatException);
    });

    test('round-trips through toHex', () {
      const color = Color(0x80FF8800);
      expect(ColorUtils.fromHex(ColorUtils.toHex(color)), color);
      expect(ColorUtils.toHex(color, includeAlpha: false), '#FF8800');
    });
  });

  group('ColorUtils darken / lighten', () {
    test('darken reduces lightness and clamps at black', () {
      final darkened = ColorUtils.darken(const Color(0xFF808080), 0.5);
      final hsl = HSLColor.fromColor(darkened);
      expect(hsl.lightness, lessThan(0.501));
      // Already-black stays black (clamped).
      final black = ColorUtils.darken(const Color(0xFF000000), 1.0);
      expect(HSLColor.fromColor(black).lightness, 0.0);
    });

    test('lighten raises lightness and clamps at white', () {
      final lightened = ColorUtils.lighten(const Color(0xFF808080), 0.5);
      expect(HSLColor.fromColor(lightened).lightness, greaterThan(0.499));
      final white = ColorUtils.lighten(const Color(0xFFFFFFFF), 1.0);
      expect(HSLColor.fromColor(white).lightness, 1.0);
    });

    test('preserve hue/saturation, randomColor is opaque', () {
      final original = HSLColor.fromColor(const Color(0xFFFF8800));
      final darkened = HSLColor.fromColor(
        ColorUtils.darken(const Color(0xFFFF8800), 0.2),
      );
      expect(darkened.hue, closeTo(original.hue, 1.0));
      expect(ColorUtils.randomColor().a, 1.0);
    });
  });
}
