import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/extensions.dart';

void main() {
  group('barrel StringExtension', () {
    test('capitalized uppercases only the first character', () {
      expect('hello'.capitalized, 'Hello');
      expect(''.capitalized, '');
    });

    group('isEmail delegates to the canonical validator', () {
      test('accepts real addresses', () {
        expect('user@example.com'.isEmail, isTrue);
        expect('user+tag@sub.domain.co'.isEmail, isTrue);
        expect('a_b@x.com'.isEmail, isTrue);
      });

      // Regression: the getter was `contains('@')`, so any string with an
      // '@' passed — junk that forms accepted as a real address.
      test('rejects strings that merely contain @', () {
        expect('@'.isEmail, isFalse);
        expect('a@'.isEmail, isFalse);
        expect('@b.com'.isEmail, isFalse);
        expect('a@@b.com'.isEmail, isFalse);
        expect('user@domain'.isEmail, isFalse);
        expect('us er@example.com'.isEmail, isFalse);
        expect(''.isEmail, isFalse);
      });

      test('agrees with StringValidators.isValidEmail', () {
        for (final candidate in [
          'a@b.co',
          'x:y@z.com',
          'a@b.c',
          'ok.name+tag@example-mission.org',
          ' user@example.com ',
        ]) {
          expect(
            candidate.isEmail,
            candidate.trim().isValidEmail,
            reason: candidate,
          );
        }
      });
    });

    group('truncated never splits a surrogate pair', () {
      test('short strings pass through, long ones gain the ellipsis', () {
        expect('short'.truncated, 'short');
        expect(('y' * 101).truncated, '${'y' * 100}...');
      });

      test('backs off a cut landing between lead and trail unit', () {
        // 99 ASCII units, then an emoji (lead at index 99, trail at 100):
        // cutting at 100 would leave a lone lead surrogate in the output.
        final text = '${'a' * 99}😀tail';
        final cut = text.truncated;
        expect(cut, '${'a' * 99}...');
        // No dangling half-surrogate survives anywhere in the result.
        for (var i = 0; i < cut.length; i++) {
          final unit = cut.codeUnitAt(i);
          if ((unit & 0xFC00) == 0xD800) {
            expect(
              i + 1 < cut.length && (cut.codeUnitAt(i + 1) & 0xFC00) == 0xDC00,
              isTrue,
              reason: 'lead surrogate at $i has no trail unit',
            );
          }
        }
      });

      test('keeps a pair that ends exactly at the boundary', () {
        final text = '${'a' * 98}😀tail'; // pair occupies units 98 and 99
        final cut = text.truncated;
        expect(cut, '${'a' * 98}😀...');
      });
    });
  });
}
