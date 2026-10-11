import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/bool_extensions.dart';
import 'package:screenshot_brain/core/utils/double_extensions.dart';
import 'package:screenshot_brain/core/utils/int_extensions.dart';
import 'package:screenshot_brain/core/utils/num_extensions.dart';

void main() {
  group('IntExtensions', () {
    test('pluralize keeps singular for 1 and custom plural', () {
      expect(1.pluralize('item'), '1 item');
      expect(5.pluralize('item'), '5 items');
      expect(2.pluralize('person', 'people'), '2 people');
    });

    test('isBetween is inclusive on both ends', () {
      expect(5.isBetween(1, 10), isTrue);
      expect(1.isBetween(1, 10), isTrue);
      expect(10.isBetween(1, 10), isTrue);
      expect(11.isBetween(1, 10), isFalse);
    });

    test('coerceIn clamps into the range and keeps int type', () {
      expect(5.coerceIn(0, 10), 5);
      expect(15.coerceIn(0, 10), 10);
      expect((-3).coerceIn(0, 10), 0);
      expect(15.coerceIn(0, 10), isA<int>());
    });

    test('toIndianRupees groups lakhs and crores correctly', () {
      expect(129900.toIndianRupees(), '₹1,29,900');
      expect(999.toIndianRupees(), '₹999');
      expect(1000.toIndianRupees(), '₹1,000');
      expect(100000.toIndianRupees(), '₹1,00,000');
      expect(10000000.toIndianRupees(), '₹1,00,00,000');
      expect(100000000.toIndianRupees(), '₹10,00,00,000');
    });

    test('toIndianRupees supports decimals, symbol and negatives', () {
      expect(5000.toIndianRupees(decimals: 2), '₹5,000.00');
      expect(129900.toIndianRupees(symbol: 'Rs '), 'Rs 1,29,900');
      expect((-1500).toIndianRupees(), '-₹1,500');
      expect(0.toIndianRupees(), '₹0');
    });
  });

  group('NumExtensions math helpers', () {
    test('safeDiv divides normally and falls back on zero divisor', () {
      expect(10.safeDiv(4), 2.5);
      expect(10.safeDiv(0), 0.0);
      expect(10.safeDiv(0, orElse: -1), -1.0);
    });

    test('coerceIn clamps and asserts ordered bounds', () {
      expect(2.5.coerceIn(0, 1), 1);
      expect((-2).coerceIn(0, 1), 0);
      expect(0.5.coerceIn(0, 1), 0.5);
      expect(() => 5.coerceIn(1, 0), throwsAssertionError);
    });

    test('clampTo (existing) still behaves', () {
      expect(11.clampTo(0, 10), 10);
      expect(7.clampTo(0, 10), 7);
    });

    test('roundTo fixes the multiply-round drift and pins tie behavior', () {
      // The naive (x * 100).round() / 100 drifts upward for 2.675...
      expect((2.675 * 100).round() / 100, 2.68);
      // ...while roundTo matches the value actually stored (just below the tie).
      expect(2.675.roundTo(2), 2.67);
      expect(0.145.roundTo(2), 0.14); // toStringAsFixed rounds this tie down
      expect(8.835.roundTo(2), 8.84);
      expect(2.5.roundTo(0), 3.0); // half away from zero at the integer tie
      expect((-2.5).roundTo(0), -3.0);
      expect(7.roundTo(2), 7.0);
      expect(() => 1.0.roundTo(-1), throwsAssertionError);
    });

    test('lerp interpolates and overshoots outside 0..1 on purpose', () {
      expect(10.lerp(20, 0), 10.0);
      expect(10.lerp(20, 0.5), 15.0);
      expect(10.lerp(20, 1), 20.0);
      expect(10.lerp(20, 1.5), 25.0);
    });

    test('inverseLerp maps a range to 0..1', () {
      expect(15.inverseLerp(10, 20), 0.5);
      expect(10.inverseLerp(10, 20), 0.0);
      expect(25.inverseLerp(10, 20), 1.5);
      expect(() => 15.inverseLerp(10, 10), throwsAssertionError);
    });

    test('remap maps between two ranges', () {
      expect(5.remap(0, 10, 100, 200), 150.0);
      expect(0.remap(0, 10, 100, 200), 100.0);
      expect(20.remap(0, 10, 100, 200), 300.0);
    });

    test('percentOf is zero-total safe', () {
      expect(30.percentOf(120), 25.0);
      expect(50.percentOf(50), 100.0);
      expect(30.percentOf(0), 0.0);
      expect(30.percentOf(0, orElse: -1), -1.0);
    });

    test('toIndianRupees on non-int nums', () {
      // Static type num picks NumExtensions (decimals default 0);
      // a static double would pick DoubleExtensions (decimals default 2).
      final num big = 129900.0;
      final num half = 2.5;
      expect(big.toIndianRupees(), '₹1,29,900');
      expect(half.toIndianRupees(), '₹3');
      expect(1299.5.toIndianRupees(decimals: 2), '₹1,299.50');
    });

    test('existing currency helpers still format', () {
      expect(1234.5.toCurrency('\$'), contains('1,234.50'));
      expect(1234567.toCompact(), isNotEmpty);
    });
  });

  group('DoubleExtensions', () {
    test('orZero sanitizes NaN and infinity', () {
      expect(double.nan.orZero, 0.0);
      expect(double.infinity.orZero, 0.0);
      expect(12.5.orZero, 12.5);
    });

    test('isBetween is inclusive', () {
      expect(0.5.isBetween(0.0, 1.0), isTrue);
      expect(1.0.isBetween(0.0, 1.0), isTrue);
      expect(1.0001.isBetween(0.0, 1.0), isFalse);
    });

    test('toIndianRupees keeps two decimals by default', () {
      expect(1299.5.toIndianRupees(), '₹1,299.50');
      expect(1299.5.toIndianRupees(decimals: 0), '₹1,300');
      expect(0.0.toIndianRupees(), '₹0.00');
    });

    test('toMaxDecimals strips trailing zeros only after the dot', () {
      expect(1.5.toMaxDecimals(2), '1.5');
      expect(100.250.toMaxDecimals(2), '100.25');
      expect(100.0.toMaxDecimals(2), '100');
    });
  });

  group('BoolExtensions', () {
    test('existing helpers behave', () {
      expect(true.toInt(), 1);
      expect(false.toInt(), 0);
      expect(true.fold('on', 'off'), 'on');
      expect(false.toYesNo(), 'No');
      expect(true.toOnOff(), 'On');
      expect(true.toggle(), isFalse);
      expect((null as bool?).orFalse, isFalse);
      expect((null as bool?).orTrue, isTrue);
    });

    test('thenV returns value when true and orElse when false', () {
      expect(true.thenV(5), 5);
      expect(false.thenV(5, orElse: 6), 6);
      expect(false.thenV<String?>('a'), isNull);
    });

    test('thenV throws without a usable orElse', () {
      expect(() => false.thenV<int>(1), throwsStateError);
    });

    test('flipIf only toggles when the condition holds', () {
      expect(true.flipIf(true), isFalse);
      expect(true.flipIf(false), isTrue);
      expect(false.flipIf(true), isTrue);
      expect(false.flipIf(false), isFalse);
    });

    test('implies matches !a || b', () {
      expect(true.implies(true), isTrue);
      expect(true.implies(false), isFalse);
      expect(false.implies(false), isTrue);
    });
  });
}
