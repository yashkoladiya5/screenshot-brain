import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/string_validators.dart';
import 'package:screenshot_brain/core/utils/validator_utils.dart';

void main() {
  group('StringValidators.isValidEmail', () {
    test('accepts well-formed addresses', () {
      expect(StringValidators.isValidEmail('user@example.com'), isTrue);
      expect(StringValidators.isValidEmail('first.last@sub.domain.co'), isTrue);
      expect(StringValidators.isValidEmail("o'connor+tag@corp.io"), isTrue);
      expect(StringValidators.isValidEmail('a_b-c@x1.dev'), isTrue);
    });

    test('trims surrounding whitespace', () {
      expect(StringValidators.isValidEmail('  user@example.com '), isTrue);
    });

    test('rejects malformed addresses', () {
      expect(StringValidators.isValidEmail(''), isFalse);
      expect(StringValidators.isValidEmail('   '), isFalse);
      expect(StringValidators.isValidEmail('user'), isFalse);
      expect(StringValidators.isValidEmail('user@'), isFalse);
      expect(StringValidators.isValidEmail('@example.com'), isFalse);
      expect(StringValidators.isValidEmail('user@example'), isFalse); // no TLD
      expect(StringValidators.isValidEmail('user@@example.com'), isFalse);
      expect(StringValidators.isValidEmail('user@.example.com'), isFalse);
      expect(StringValidators.isValidEmail('user@exam..ple.com'), isFalse);
      expect(StringValidators.isValidEmail('us er@example.com'), isFalse);
      expect(StringValidators.isValidEmail('user@example.c'), isFalse);
      expect(StringValidators.isValidEmail('user@example.com.'), isFalse);
    });

    test('rejects overlong local part', () {
      final local = 'a' * 65;
      expect(StringValidators.isValidEmail('$local@example.com'), isFalse);
    });
  });

  group('ValidatorUtils.validateEmail', () {
    test('required message for null/empty', () {
      expect(ValidatorUtils.validateEmail(null), 'Email is required');
      expect(ValidatorUtils.validateEmail(''), 'Email is required');
      expect(ValidatorUtils.validateEmail('   '), 'Email is required');
    });

    test('invalid message for bad format', () {
      expect(
        ValidatorUtils.validateEmail('not-an-email'),
        'Enter a valid email address',
      );
    });

    test('null (valid) for good email', () {
      expect(ValidatorUtils.validateEmail('me@site.com'), isNull);
    });
  });

  group('StringValidators.isValidPhone', () {
    test('accepts E.164', () {
      expect(StringValidators.isValidPhone('+14155550123'), isTrue);
      expect(StringValidators.isValidPhone('+919876543210'), isTrue);
      expect(StringValidators.isValidPhone(' +919876543210 '), isTrue);
    });

    test('rejects malformed E.164', () {
      expect(StringValidators.isValidPhone('+0123456789'), isFalse); // 0 lead
      expect(StringValidators.isValidPhone('+123'), isFalse); // too short
      expect(StringValidators.isValidPhone('+${'1' * 16}'), isFalse); // >15
      expect(StringValidators.isValidPhone('919876543210'), isFalse); // no +
    });

    test('10-digit national fallback with separators', () {
      expect(StringValidators.isValidPhone('9876543210'), isTrue);
      expect(StringValidators.isValidPhone('987-654-3210'), isTrue);
      expect(StringValidators.isValidPhone('987 654 3210'), isTrue);
      expect(StringValidators.isValidPhone('987.654.3210'), isTrue);
    });

    test('separator placement is cosmetic, not part of the number', () {
      // Indian receipts and contacts group a mobile as '98765 43210', and a
      // stored E.164 value often carries spaces: both used to be rejected
      // because the national pattern demanded 3-3-4 grouping.
      expect(StringValidators.isValidPhone('98765 43210'), isTrue);
      expect(StringValidators.isValidPhone('98765-43210'), isTrue);
      expect(StringValidators.isValidPhone('98765.43210'), isTrue);
      expect(StringValidators.isValidPhone('+91 98765 43210'), isTrue);
      expect(StringValidators.isValidPhone('+91-98765-43210'), isTrue);
      expect(StringValidators.isValidPhone('+1 415 555 0123'), isTrue);
    });

    test('rejects wrong digit counts and junk', () {
      expect(StringValidators.isValidPhone('12345'), isFalse);
      expect(StringValidators.isValidPhone('123456789'), isFalse);
      expect(StringValidators.isValidPhone('12345678901'), isFalse);
      expect(StringValidators.isValidPhone('abc-def-gghi'), isFalse);
      expect(StringValidators.isValidPhone(''), isFalse);
      // Non-digit decoration is still not tolerated.
      expect(StringValidators.isValidPhone('(415) 555-0123'), isFalse);
      expect(StringValidators.isValidPhone('987 654 32 10 extra'), isFalse);
      expect(StringValidators.isValidPhone('+91 98765 43210x'), isFalse);
    });

    test('validatePhone wrapper', () {
      expect(ValidatorUtils.validatePhone(null), 'Phone number is required');
      expect(ValidatorUtils.validatePhone('12'), 'Enter a valid phone number');
      expect(ValidatorUtils.validatePhone('+919876543210'), isNull);
      expect(ValidatorUtils.validatePhone(null, required: false), isNull);
    });
  });

  group('StringValidators.isValidUrl', () {
    test('accepts common URLs', () {
      expect(StringValidators.isValidUrl('https://example.com'), isTrue);
      expect(
        StringValidators.isValidUrl('http://example.com/path/to/x'),
        isTrue,
      );
      expect(StringValidators.isValidUrl('example.com'), isTrue);
      expect(StringValidators.isValidUrl('sub.domain.co.in'), isTrue);
      expect(
        StringValidators.isValidUrl('https://example.com:8443/a?b=1#c'),
        isTrue,
      );
      expect(StringValidators.isValidUrl(' https://example.com '), isTrue);
    });

    test('rejects junk', () {
      expect(StringValidators.isValidUrl(''), isFalse);
      expect(StringValidators.isValidUrl('not a url'), isFalse);
      expect(StringValidators.isValidUrl('https://exam ple.com'), isFalse);
      expect(StringValidators.isValidUrl('ftp://example.com'), isFalse);
      expect(StringValidators.isValidUrl('example'), isFalse);
      expect(StringValidators.isValidUrl('://x.com'), isFalse);
    });

    test('is case-insensitive and allows long modern TLDs', () {
      // Hostnames are case-insensitive, and OCR/typed links come back as
      // 'HTTPS://Example.COM'; the old pattern also capped the TLD at 6
      // letters, so '.website' and '.technology' were rejected.
      expect(StringValidators.isValidUrl('HTTPS://Example.COM'), isTrue);
      expect(StringValidators.isValidUrl('Example.COM'), isTrue);
      expect(StringValidators.isValidUrl('https://Shop.Online/cart'), isTrue);
      expect(StringValidators.isValidUrl('example.website'), isTrue);
      expect(StringValidators.isValidUrl('studio.photography'), isTrue);
      expect(StringValidators.isValidUrl('https://a.technology'), isTrue);
      // Still needs a dot and an alphabetic TLD.
      expect(StringValidators.isValidUrl('HTTPS://EXAMPLE'), isFalse);
    });

    test('validateUrl wrapper', () {
      expect(ValidatorUtils.validateUrl(null), 'URL is required');
      expect(ValidatorUtils.validateUrl('bad url'), 'Enter a valid URL');
      expect(ValidatorUtils.validateUrl('https://ok.dev'), isNull);
      expect(ValidatorUtils.validateUrl('', required: false), isNull);
    });
  });

  group('required-with-maxlength', () {
    test('required first', () {
      expect(
        ValidatorUtils.validateRequiredWithMaxLength(null, 10),
        'This field is required',
      );
      expect(
        ValidatorUtils.validateRequiredWithMaxLength(
          '  ',
          10,
          fieldName: 'Note',
        ),
        'Note is required',
      );
    });

    test('length bound on trimmed value', () {
      expect(
        ValidatorUtils.validateRequiredWithMaxLength('a' * 11, 10),
        'This field must be at most 10 characters',
      );
      expect(
        ValidatorUtils.validateRequiredWithMaxLength('a' * 10, 10),
        isNull,
      );
      expect(
        ValidatorUtils.validateRequiredWithMaxLength('  abc  ', 3),
        isNull,
      );
    });
  });

  group('amount validation (expense-format aware)', () {
    test('accepts app-supported currency formats', () {
      expect(StringValidators.isValidAmount('₹1,29,900'), isTrue);
      expect(StringValidators.isValidAmount('₹ 1,29,900'), isTrue);
      expect(StringValidators.isValidAmount('Rs. 450'), isTrue);
      expect(StringValidators.isValidAmount('RS.450'), isTrue);
      expect(StringValidators.isValidAmount('INR 2,500'), isTrue);
      expect(StringValidators.isValidAmount('\$1,299.90'), isTrue);
      expect(StringValidators.isValidAmount('€1.299,90'), isTrue);
      expect(StringValidators.isValidAmount('£50'), isTrue);
      expect(StringValidators.isValidAmount('1299,90'), isTrue);
      expect(StringValidators.isValidAmount('1299.90'), isTrue);
      expect(StringValidators.isValidAmount('50'), isTrue);
      expect(StringValidators.isValidAmount('1,299'), isTrue);
      expect(StringValidators.isValidAmount('999 USD'), isTrue);
    });

    test('rejects malformed amounts', () {
      expect(StringValidators.isValidAmount(''), isFalse);
      expect(StringValidators.isValidAmount('₹'), isFalse);
      expect(
        StringValidators.isValidAmount('1,29990'),
        isFalse,
      ); // bad grouping
      expect(StringValidators.isValidAmount('1.2.3.4'), isFalse);
      expect(StringValidators.isValidAmount('12.999,999'), isFalse);
      expect(StringValidators.isValidAmount('123.4567'), isFalse); // 4dp
      expect(StringValidators.isValidAmount('-50'), isFalse);
      expect(StringValidators.isValidAmount('(100)'), isFalse);
      expect(StringValidators.isValidAmount('abc'), isFalse);
      expect(StringValidators.isValidAmount('₹1,29,900 USD'), isFalse);
    });

    test('parseAmount resolves grouping correctly', () {
      expect(StringValidators.parseAmount('₹1,29,900'), 129900.0);
      expect(StringValidators.parseAmount('1,29,900.50'), 129900.50);
      expect(StringValidators.parseAmount('\$1,299.90'), 1299.90);
      expect(StringValidators.parseAmount('€1.299,90'), 1299.90);
      expect(StringValidators.parseAmount('1299,90'), 1299.90);
      expect(StringValidators.parseAmount('Rs. 450'), 450.0);
      expect(StringValidators.parseAmount('junk'), isNull);
    });

    test('rejects digit runs too long to be money', () {
      // UTR / reference / card numbers are all-digit strings. The extraction
      // pipeline already rejects anything past 9 digits; the validator had no
      // such guard, so it called '4111111111111234' a valid amount and
      // `parseAmount` silently corrupted 19-digit input into 1.0e19.
      expect(StringValidators.isValidAmount('9999999999999999999'), isFalse);
      expect(
        StringValidators.parseAmount('9999999999999999999'),
        isNull,
        reason: 'must not silently return 1.0e19',
      );
      expect(StringValidators.isValidAmount('123456789012345678'), isFalse);
      expect(StringValidators.isValidAmount('4111111111111234'), isFalse);
      expect(StringValidators.parseAmount('1234567890'), isNull);
      expect(StringValidators.parseAmount('1,23,45,678.90'), isNull);
      // Nine digits stay exactly representable as a double.
      expect(StringValidators.parseAmount('123456789'), 123456789.0);
      expect(StringValidators.parseAmount('₹1,29,900.50'), 129900.50);
      expect(StringValidators.parseAmount('1,299.90'), 1299.90);
    });

    test('validateAmount wrapper', () {
      expect(ValidatorUtils.validateAmount(null), 'Amount is required');
      expect(ValidatorUtils.validateAmount('1,29990'), 'Enter a valid amount');
      expect(ValidatorUtils.validateAmount('₹1,29,900'), isNull);
      expect(ValidatorUtils.validateAmount('', required: false), isNull);
    });
  });

  group('character-class helpers (unchanged API)', () {
    test('hasUpperCase/hasLowerCase/hasDigit/hasSpecialCharacter', () {
      expect(StringValidators.hasUpperCase('aBc'), isTrue);
      expect(StringValidators.hasUpperCase('abc'), isFalse);
      expect(StringValidators.hasLowerCase('ABC'), isFalse);
      expect(StringValidators.hasDigit('ab5'), isTrue);
      expect(StringValidators.hasDigit('abc'), isFalse);
      expect(StringValidators.hasSpecialCharacter('ab!'), isTrue);
      expect(StringValidators.hasSpecialCharacter('ab1'), isFalse);
    });

    test('isStrongPassword', () {
      expect(StringValidators.isStrongPassword('Abcdef1'), isFalse); // short
      expect(StringValidators.isStrongPassword('abcdefg1'), isFalse); // no case
      expect(StringValidators.isStrongPassword('Abcdefg1'), isTrue);
    });
  });
}
