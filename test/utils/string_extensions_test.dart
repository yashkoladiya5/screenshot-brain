import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/string_casing_extensions.dart';
import 'package:screenshot_brain/core/utils/string_extensions.dart';

void main() {
  group('StringExtensions basics', () {
    test('capitalizeFirst preserves the rest of the casing', () {
      expect('hELLO world'.capitalizeFirst(), 'HELLO world');
      expect('already'.capitalizeFirst(), 'Already');
      expect(''.capitalizeFirst(), '');
    });

    test('capitalizeWords handles repeated spaces', () {
      expect('foo bar'.capitalizeWords(), 'Foo Bar');
      expect('a  b'.capitalizeWords(), 'A  B');
      expect(''.capitalizeWords(), '');
    });

    test('isValidEmail accepts plausible addresses', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('nope'.isValidEmail, isFalse);
    });

    test('truncate (legacy) appends three dots', () {
      expect('hello world'.truncate(5), 'hello...');
      expect('short'.truncate(10), 'short');
    });
  });

  group('collapseWhitespace', () {
    test('collapses runs and trims the ends', () {
      expect('  hello \t\n world '.collapseWhitespace(), 'hello world');
      expect('single'.collapseWhitespace(), 'single');
      expect('   '.collapseWhitespace(), '');
    });
  });

  group('truncateWithEllipsis', () {
    test('cuts at the rune budget and appends the ellipsis', () {
      expect('hello world'.truncateWithEllipsis(5), 'hello…');
      expect('hello'.truncateWithEllipsis(5), 'hello');
      expect('hi'.truncateWithEllipsis(10), 'hi');
    });

    test('never splits a surrogate pair', () {
      expect('a👍b'.truncateWithEllipsis(1), 'a…');
      // Rune-based budget: the emoji counts as one even though it is two
      // UTF-16 code units.
      expect('a👍'.truncateWithEllipsis(2), 'a👍');
    });

    test(
      'documented caveat: multi-code-point clusters count per code point',
      () {
        // thumbs up + skin tone modifier are two runes, kept together here;
        // a budget of one would keep only the base emoji.
        expect('👍🏽 OK'.truncateWithEllipsis(2), '👍🏽…');
        expect(() => 'abc'.truncateWithEllipsis(0), throwsAssertionError);
      },
    );

    test('custom ellipsis string', () {
      expect(
        'screenshotocr'.truncateWithEllipsis(4, ellipsis: ' (...)'),
        'scre (...)',
      );
    });
  });

  group('maskMiddle', () {
    test('masks card numbers keeping the last four', () {
      expect('4111111111111234'.maskMiddle(), '************1234');
      expect('1234'.maskMiddle(), '1234');
      expect('12'.maskMiddle(), '12');
      expect('123456789'.maskMiddle(visibleSuffix: 0), '*********');
      expect('8888001234'.maskMiddle(maskChar: '•'), '••••••1234');
      expect(() => '1234'.maskMiddle(visibleSuffix: -1), throwsAssertionError);
    });
  });

  group('initials', () {
    test('takes one letter per word, uppercased', () {
      expect('yash kumar'.initials(), 'YK');
      expect('solo'.initials(), 'S');
      expect(''.initials(), '');
    });

    test('skips words without letters and respects maxLength', () {
      expect('Rahul 123 Das'.initials(), 'RD');
      expect('123 456'.initials(), '');
      expect('a b c d'.initials(maxLength: 3), 'ABC');
      expect('yash kumar'.initials(separator: '.'), 'Y.K');
    });
  });

  group('slugify', () {
    test('lowercases and joins with the separator', () {
      expect('Hello, World!'.slugify(), 'hello-world');
      expect('  Multiple   spaces  '.slugify(), 'multiple-spaces');
      expect('already-slug'.slugify(), 'already-slug');
    });

    test('trims stray separators and strips non-ASCII', () {
      expect('--foo--'.slugify(), 'foo');
      expect('***'.slugify(), '');
      // Caveat: accents are dropped, not transliterated.
      expect('Café'.slugify(), 'caf');
      expect('grocery 2024'.slugify(separator: '__'), 'grocery__2024');
    });
  });

  group('StringCasingExtensions existing behavior', () {
    test('toCapitalized lowercases the tail', () {
      expect('hElLo'.toCapitalized(), 'Hello');
      expect(''.toCapitalized(), '');
    });

    test('toTitleCase capitalizes each space-separated word', () {
      expect('hello world'.toTitleCase(), 'Hello World');
      expect('two  words'.toTitleCase(), 'Two Words');
      expect(
        'iPhone'.toTitleCase(),
        'Iphone',
        reason: 'existing spec lowercases the rest of each word',
      );
    });
  });

  group('toSnakeCase', () {
    test('splits camel, acronyms, digits and separators', () {
      expect('userID'.toSnakeCase(), 'user_id');
      expect('HTMLParser'.toSnakeCase(), 'html_parser');
      expect('Foo2Bar'.toSnakeCase(), 'foo2_bar');
      expect('version2beta'.toSnakeCase(), 'version2beta');
      expect('kebab-case'.toSnakeCase(), 'kebab_case');
      expect('Hello World'.toSnakeCase(), 'hello_world');
      expect('user_name'.toSnakeCase(), 'user_name');
      expect(''.toSnakeCase(), '');
    });
  });

  group('toKebabCase', () {
    test('mirrors snake_case with dashes', () {
      expect('userID'.toKebabCase(), 'user-id');
      expect('HTMLParser'.toKebabCase(), 'html-parser');
      expect('snake_case'.toKebabCase(), 'snake-case');
    });
  });

  group('toCamelCase / toPascalCase', () {
    test('toCamelCase lower-caps the first word', () {
      expect('user_name'.toCamelCase(), 'userName');
      expect('UserName'.toCamelCase(), 'userName');
      expect('kebab-case-name'.toCamelCase(), 'kebabCaseName');
      expect('hello'.toCamelCase(), 'hello');
      expect(''.toCamelCase(), '');
      // Acronym runs are title-cased inside, per the documented contract.
      expect('USER_ID'.toCamelCase(), 'userId');
      expect('userID'.toCamelCase(), 'userId');
    });

    test('toPascalCase capitalizes every word', () {
      expect('http server'.toPascalCase(), 'HttpServer');
      expect('user_name'.toPascalCase(), 'UserName');
      expect('HTMLParser'.toPascalCase(), 'HtmlParser');
      expect(''.toPascalCase(), '');
    });
  });
}
