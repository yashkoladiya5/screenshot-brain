import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/core/utils/file_extensions.dart';

void main() {
  group('toReadableFileSize (existing API)', () {
    test('zero and negatives render as 0 B', () {
      expect(0.toReadableFileSize(), '0 B');
      expect((-42).toReadableFileSize(), '0 B');
    });

    test('binary thresholds with one decimal', () {
      expect(1024.toReadableFileSize(), '1.0 KB');
      expect((1536).toReadableFileSize(), '1.5 KB');
      expect((5 * 1024 * 1024).toReadableFileSize(), '5.0 MB');
      expect((3 * 1024 * 1024 * 1024).toReadableFileSize(), '3.0 GB');
      expect(512.toReadableFileSize(), '512.0 B');
    });

    test('decimals parameter and rounding', () {
      expect(1023.toReadableFileSize(), '1023.0 B');
      // Regression: 1048575 B is under 1 MiB but rounded to "1024.00 KB"
      // (and 1048570 to "1024.0 KB"), a full 1024 of the smaller unit shown
      // in the detail screen. Rounded values that reach 1024 promote to the
      // next suffix.
      expect((1024 * 1024 - 1).toReadableFileSize(decimals: 2), '1.00 MB');
      expect((1024 * 1024 - 6).toReadableFileSize(), '1.0 MB');
      expect((1024 * 1024 - 52).toReadableFileSize(), '1023.9 KB');
      expect(1073741823.toReadableFileSize(), '1.0 GB');
      expect(
        (1024 * 1024 * 1024 - 1).toReadableFileSize(decimals: 2),
        '1.00 GB',
      );
      // Promotion must not corrupt the plain cases.
      expect((5 * 1024 * 1024).toReadableFileSize(), '5.0 MB');
      expect((1 << 62).toReadableFileSize(), '4.0 EB');
    });

    test('huge sizes clamp to a suffix instead of crashing', () {
      final huge = 1 << 62; // 4 EiB-scale
      expect(huge.toReadableFileSize(), endsWith('EB'));
      final absurd = 1 << 62;
      expect(absurd.toReadableFileSize(decimals: 0), '4 EB');
    });
  });

  group('toReadableFileSizeCompact (Indian K/M style)', () {
    test('short suffixes', () {
      expect(1024.toReadableFileSizeCompact(), '1.0 K');
      expect((2 * 1024 * 1024).toReadableFileSizeCompact(), '2.0 M');
      expect(900.toReadableFileSizeCompact(), '900.0 B');
      expect(0.toReadableFileSizeCompact(), '0 B');
      // Same rounding promotion as toReadableFileSize: never "1024.0".
      expect((1024 * 1024 - 6).toReadableFileSizeCompact(), '1.0 M');
      expect((1024 * 1024 - 52).toReadableFileSizeCompact(), '1023.9 K');
    });
  });

  group('fileExtension / isAllowedImageExtension', () {
    test('extracts lowercase extension from paths', () {
      expect('Photo.PNG'.fileExtension, 'png');
      expect('/a/b/img.jpeg'.fileExtension, 'jpeg');
      expect(r'C:\shots\IMG.heic'.fileExtension, 'heic');
      expect('noext'.fileExtension, '');
      expect('archive.tar.gz'.fileExtension, 'gz');
      expect('.gitignore'.fileExtension, ''); // leading dot = no extension
      expect('ends_with_dot.'.fileExtension, '');
    });

    test('whitelist accepts screenshot formats only', () {
      expect('shot.png'.isAllowedImageExtension, isTrue);
      expect('shot.JPG'.isAllowedImageExtension, isTrue);
      expect('shot.HEIF'.isAllowedImageExtension, isTrue);
      expect('notes.pdf'.isAllowedImageExtension, isFalse);
      expect('script.sh'.isAllowedImageExtension, isFalse);
      expect('noext'.isAllowedImageExtension, isFalse);
    });
  });

  group('sanitizedFileName (path-traversal proof)', () {
    test('classic traversal payloads collapse to basename', () {
      expect('../../../etc/passwd'.sanitizedFileName, 'passwd');
      expect('../../../../tmp/evil.png'.sanitizedFileName, 'evil.png');
      expect('/absolute/path/shot.png'.sanitizedFileName, 'shot.png');
      expect('....//....//etc/passwd'.sanitizedFileName, 'passwd');
      expect(r'..\..\Windows\system32\app.exe'.sanitizedFileName, 'app.exe');
      expect(r'C:\Users\victim\.ssh\id_rsa'.sanitizedFileName, 'id_rsa');
    });

    test('null bytes and control chars are stripped', () {
      expect('evil\u0000.png'.sanitizedFileName, 'evil.png');
      expect('bad\u0000name\u0001'.sanitizedFileName, 'badname');
      expect('a\u0000/b\u0000c'.sanitizedFileName, 'bc');
    });

    test('reserved characters and spacing normalized', () {
      expect('a:b*c?d".png'.sanitizedFileName, 'a_b_c_d_.png');
      expect('two   spaces.png'.sanitizedFileName, 'two spaces.png');
      expect(
        '...leading and trailing...'.sanitizedFileName,
        'leading and trailing',
      );
    });

    test('empty and separator-only inputs fall back to file', () {
      expect(''.sanitizedFileName, 'file');
      expect('///'.sanitizedFileName, 'file');
      expect('...'.sanitizedFileName, 'file');
      expect('\u0000\u0000'.sanitizedFileName, 'file');
    });

    test('normal names pass through untouched', () {
      expect(
        'Screenshot 2025-06-04 at 14.32.10.png'.sanitizedFileName,
        'Screenshot 2025-06-04 at 14.32.10.png',
      );
      expect('IMG_0042.HEIC'.sanitizedFileName, 'IMG_0042.HEIC');
    });
  });

  group('nextUniqueName', () {
    test('first collision becomes (2)', () {
      expect('img.png'.nextUniqueName, 'img (2).png');
      expect('photo'.nextUniqueName, 'photo (2)');
      expect('shot.heic'.nextUniqueName, 'shot (2).heic');
    });

    test('existing counters increment', () {
      expect('img (2).png'.nextUniqueName, 'img (3).png');
      expect('img (9).png'.nextUniqueName, 'img (10).png');
      expect('dup (42).jpeg'.nextUniqueName, 'dup (43).jpeg');
    });

    test('non-numeric parens are not treated as counters', () {
      expect('final (draft).png'.nextUniqueName, 'final (draft) (2).png');
    });

    test('applies sanitization before suffixing', () {
      expect('../../../etc/passwd'.nextUniqueName, 'passwd (2)');
    });

    test('hidden-style and multi-dot names', () {
      // leading dot is stripped by the sanitizer, so no counter is found
      expect('.bashrc'.nextUniqueName, 'bashrc (2)');
      expect('archive.tar.gz'.nextUniqueName, 'archive.tar (2).gz');
    });
  });
}
