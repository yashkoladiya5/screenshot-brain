import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/extensions.dart';

// Imported *in addition to* the barrel on purpose: this file only compiles if
// `DateTime` has exactly one non-ambiguous extension behind the barrel (a
// second `DateTimeExtensions`-style library would make every member below an
// "ambiguous extension member" error).
// ignore: unnecessary_import
import 'package:screenshot_brain/core/utils/date_extensions.dart';

void main() {
  group('utils barrel', () {
    test(
      'resolves DateTime members through the single canonical extension',
      () {
        final date = DateTime.utc(2023, 10, 24, 16, 30);
        expect(date.formatted, '24 Oct 2023');
        expect(date.formattedWithTime, '24 Oct 2023 16:30');
        expect(date.monthYear, 'Oct 2023');
        expect(date.toStandardFormat(), 'Oct 24, 2023');
        expect(
          date.toRelativeString(reference: DateTime.utc(2023, 10, 24, 9)),
          'Today at 4:30 PM',
        );
      },
    );

    test('re-exports the file-size and path helpers', () {
      expect((1024 * 1024 * 3).toReadableFileSize(), '3.0 MB');
      expect((0).toReadableFileSize(), '0 B');
      expect('/Pictures/Screenshot_2025.png'.fileExtension, 'png');
      expect('/Pictures/Screenshot_2025.png'.isAllowedImageExtension, isTrue);
      expect('/etc/passwd'.isAllowedImageExtension, isFalse);
    });

    test('re-exports the string helpers alongside the barrel-local ones', () {
      expect('screenshot brain'.capitalizeWords(), 'Screenshot Brain');
      expect('a@b.co'.isValidEmail, isTrue);
      expect('hello'.capitalized, 'Hello');
      expect('hello'.toCapitalized(), 'Hello');
      expect('HELLO'.toTitleCase(), 'Hello');
    });
  });
}
