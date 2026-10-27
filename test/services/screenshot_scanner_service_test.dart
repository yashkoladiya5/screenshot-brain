import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/services/screenshot_scanner_service.dart';

ScannedAsset asset(String id, String path, String modifiedIso) =>
    ScannedAsset(id: id, path: path, modified: DateTime.parse(modifiedIso));

void main() {
  group('isScreenshotAlbumName', () {
    test('matches album name case-insensitively', () {
      expect(
        ScreenshotScannerService.isScreenshotAlbumName('Screenshots'),
        isTrue,
      );
      expect(
        ScreenshotScannerService.isScreenshotAlbumName('SCREENSHOT'),
        isTrue,
      );
      expect(
        ScreenshotScannerService.isScreenshotAlbumName(
          'Camera',
          relativePath: 'Pictures/Screenshot_2024',
        ),
        isTrue,
      );
    });

    test('matches known screenshot relative paths', () {
      expect(
        ScreenshotScannerService.isScreenshotAlbumName(
          'All',
          relativePath: 'DCIM/Screenshots',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.isScreenshotAlbumName(
          'Gallery',
          relativePath: 'Pictures/Screenshots',
        ),
        isTrue,
      );
    });

    test('does not match unrelated albums', () {
      expect(ScreenshotScannerService.isScreenshotAlbumName('Camera'), isFalse);
      expect(
        ScreenshotScannerService.isScreenshotAlbumName(
          'WhatsApp',
          relativePath: 'Media/WhatsApp Images',
        ),
        isFalse,
      );
    });
  });

  group('looksLikeScreenshot', () {
    test('matches screenshot titles regardless of case', () {
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'Screenshot_20240101-120000.png',
          '',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot('MY SCREENSHOT', ''),
        isTrue,
      );
    });

    test('matches assets stored under a Screenshots folder', () {
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'IMG_0001.png',
          'Pictures/Screenshots',
        ),
        isTrue,
      );
    });

    test('rejects ordinary photos', () {
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'IMG_0001.jpg',
          'DCIM/Camera',
        ),
        isFalse,
      );
    });

    test('rejects screenshot-substring names that are not images', () {
      // The old substring rule accepted any title containing "screenshot",
      // so "screenshots-are-cool.txt" and "Screenshot.pdf" were indexed.
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'screenshots-are-cool.txt',
          '',
        ),
        isFalse,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot('Screenshot.pdf', ''),
        isFalse,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'screenshot_notes.md',
          'DCIM/Camera',
        ),
        isFalse,
      );
    });

    test('matches assets in a singular-name Screenshot folder', () {
      // ColorOS/OxygenOS and several OEM galleries store screenshots under
      // "DCIM/Screenshot" (singular); the old plural-only folder rule missed
      // every one of them in the All-album fallback.
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'IMG_0002.png',
          'DCIM/Screenshot',
        ),
        isTrue,
      );
    });

    test('matches locale-specific screenshot file names', () {
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          '截图_20240101-120000.png',
          '',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'Screen Shot 2024-01-01 at 12.00.00.png',
          'DCIM/Camera',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'Bildschirmfoto 2024-01-01.at 12.00.00.png',
          '',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'Captura de pantalla 2024-01-01.png',
          '',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'Снимок экрана 2024-01-01.png',
          '',
        ),
        isTrue,
      );
      expect(
        ScreenshotScannerService.looksLikeScreenshot(
          'スクリーンショット 2024-01-01.png',
          '',
        ),
        isTrue,
      );
      // A localized token with a non-image extension is still rejected.
      expect(
        ScreenshotScannerService.looksLikeScreenshot('截图说明.docx', ''),
        isFalse,
      );
    });
  });

  group('extensionOf / hasImageExtension', () {
    test('parses the trailing extension of dotted names correctly', () {
      // split('.').last breaks on dotted or hidden names; the trailing
      // substring after the LAST dot is the extension.
      expect(ScreenshotScannerService.extensionOf('Photo.2024.TAR.PNG'), 'png');
      expect(ScreenshotScannerService.extensionOf('a.b.c.heic'), 'heic');
      expect(ScreenshotScannerService.extensionOf('.hidden.png'), 'png');
      expect(ScreenshotScannerService.extensionOf('noextension'), '');
      expect(ScreenshotScannerService.extensionOf('archive.tar.gz'), 'gz');
    });

    test('recognises image extensions case-insensitively', () {
      expect(ScreenshotScannerService.hasImageExtension('IMG_9.PNG'), isTrue);
      expect(ScreenshotScannerService.hasImageExtension('IMG_9.Jpg'), isTrue);
      expect(ScreenshotScannerService.hasImageExtension('IMG.jpeg'), isTrue);
      expect(ScreenshotScannerService.hasImageExtension('x.heif'), isTrue);
      expect(ScreenshotScannerService.hasImageExtension('x.jpg2'), isFalse);
      expect(ScreenshotScannerService.hasImageExtension('x.txt'), isFalse);
      // No extension at all is treated as unknown-but-image (photo_manager
      // titles on iOS sometimes omit it), so it must not be rejected.
      expect(ScreenshotScannerService.hasImageExtension('MY SCREENSHOT'),
          isTrue);
    });
  });

  group('compareNatural', () {
    test('orders embedded numbers numerically, not lexically', () {
      expect(ScreenshotScannerService.compareNatural('IMG_9.png', 'IMG_10.png'),
          lessThan(0));
      expect(
        ScreenshotScannerService.compareNatural('a2', 'a10'),
        lessThan(0),
      );
      expect(
        ScreenshotScannerService.compareNatural('IMG_007.png', 'IMG_7.png'),
        0,
      );
      expect(
        ScreenshotScannerService.compareNatural('IMG_10.png', 'IMG_9.png'),
        greaterThan(0),
      );
    });

    test('is case-insensitive and deterministic', () {
      expect(ScreenshotScannerService.compareNatural('ABC', 'abc'), 0);
      expect(ScreenshotScannerService.compareNatural('abc', 'abc'), 0);
    });
  });

  group('selectNewAssets deterministic ordering', () {
    test('ties are broken by natural path order, not discovery order', () {
      // Assets captured in the same second (burst screenshots) previously
      // inherited arbitrary album-enumeration order.
      final items = [
        asset('a', '/p/IMG_10.png', '2026-05-01T00:00:00Z'),
        asset('b', '/p/IMG_9.png', '2026-05-01T00:00:00Z'),
        asset('c', '/p/IMG_100.png', '2026-05-01T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {},
      );
      expect(fresh.map((a) => a.path), [
        '/p/IMG_9.png',
        '/p/IMG_10.png',
        '/p/IMG_100.png',
      ]);

      // Same discovery order shuffled must yield the same result.
      final shuffled = ScreenshotScannerService.selectNewAssets(
        assets: items.reversed,
        knownPaths: {},
      );
      expect(shuffled.map((a) => a.path), fresh.map((a) => a.path).toList());
    });
  });

  group('pathDedupeKey / case-insensitive dedupe', () {
    test('normalises separators and case', () {
      expect(
        ScreenshotScannerService.pathDedupeKey('/Storage/Emulated/0/A.PNG'),
        '/storage/emulated/0/a.png',
      );
      expect(
        ScreenshotScannerService.pathDedupeKey(r'C:\P\A.png'),
        'c:/p/a.png',
      );
    });

    test('collapses case-variant paths to one entry', () {
      // Device storage (Android volume manager, iOS, case-insensitive HFS+/
      // APFS) treats these as the SAME file; keying dedupe on the raw path
      // indexed it twice.
      final items = [
        asset('a', '/p/A.png', '2026-05-10T00:00:00Z'),
        asset('b', '/p/a.PNG', '2026-05-10T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {},
      );
      expect(fresh.length, 1);
    });

    test('drops assets already known under a case-variant path', () {
      final items = [
        asset('a', '/P/A.PNG', '2026-05-10T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {'/p/a.png'},
      );
      expect(fresh, isEmpty);
    });
  });

  group('timestampFromFilename', () {
    DateTime? ts(String name) =>
        ScreenshotScannerService.timestampFromFilename(name);

    test('parses Android compact timestamps', () {
      expect(ts('Screenshot_20240101-120000.png'), DateTime(2024, 1, 1, 12));
      expect(ts('IMG_20240101_120000.jpg'), DateTime(2024, 1, 1, 12));
      expect(ts('Screenshot_20240101'), DateTime(2024, 1, 1));
    });

    test('parses ISO dates with optional time (iOS/macOS style)', () {
      expect(
        ts('Screen Shot 2024-01-31 at 12.00.00.png'),
        DateTime(2024, 1, 31, 12),
      );
      expect(ts('2024-1-5.png'), DateTime(2024, 1, 5));
      expect(ts('shot 2024-01-31 07:05:09.png'), DateTime(2024, 1, 31, 7, 5, 9));
    });

    test('parses month names without early-matching abbreviations', () {
      // "December" must be consumed whole: an alternation that matches
      // "Dec" first and then requires a digit would drop this file.
      expect(ts('December 1, 2024.png'), DateTime(2024, 12, 1));
      expect(ts('Dec 31 2024.png'), DateTime(2024, 12, 31));
      expect(ts('5 January 2024.png'), DateTime(2024, 1, 5));
      expect(ts('1 Dec 2024.png'), DateTime(2024, 12, 1));
      expect(ts('Jan. 5, 2024.png'), DateTime(2024, 1, 5));
      expect(ts('January 1st 2024.png'), DateTime(2024, 1, 1));
    });

    test('rejects invalid dates instead of producing garbage', () {
      expect(ts('Screenshot_20241301-120000.png'), isNull); // month 13
      expect(ts('Screenshot_20240132-120000.png'), isNull); // day 32
      expect(ts('Screenshot_20230229-120000.png'), isNull); // non-leap Feb 29
      expect(ts('Screenshot_20240229-120000.png'), DateTime(2024, 2, 29, 12));
      expect(ts('2024-13-01.png'), isNull);
      expect(ts('Dec 32 2024.png'), isNull);
      expect(ts('Screenshot_20240101-256061.png'), isNull); // hour 25
    });

    test('returns null when the name carries no timestamp', () {
      expect(ts('IMG_0001.png'), isNull);
      expect(ts('notes.old.png'), isNull);
      expect(ts(''), isNull);
      expect(ts('call_12345678.png'), isNull); // 8 digits, not a date
    });
  });

  group('isWithinWindow / filterDateWindow', () {
    final base = DateTime.utc(2026, 5, 10, 12);

    test('boundary is inclusive', () {
      expect(
        ScreenshotScannerService.isWithinWindow(base, notBefore: base),
        isTrue,
      );
      expect(
        ScreenshotScannerService.isWithinWindow(base, notAfter: base),
        isTrue,
      );
      expect(
        ScreenshotScannerService.isWithinWindow(
          base.subtract(const Duration(seconds: 1)),
          notBefore: base,
        ),
        isFalse,
      );
      expect(
        ScreenshotScannerService.isWithinWindow(
          base.add(const Duration(seconds: 1)),
          notAfter: base,
        ),
        isFalse,
      );
    });

    test('null bounds never filter', () {
      expect(ScreenshotScannerService.isWithinWindow(base), isTrue);
    });

    test('filterDateWindow keeps only in-window assets', () {
      final items = [
        asset('a', '/p/a.png', '2026-05-01T00:00:00Z'),
        asset('b', '/p/b.png', '2026-05-09T00:00:00Z'),
        asset('c', '/p/c.png', '2026-05-15T00:00:00Z'),
      ];
      final filtered = ScreenshotScannerService.filterDateWindow(
        items,
        notBefore: DateTime.utc(2026, 5, 8),
        notAfter: DateTime.utc(2026, 5, 12),
      );
      expect(filtered.map((a) => a.id), ['b']);
    });
  });

  group('selectNewAssets', () {
    test('drops paths already known', () {
      final items = [
        asset('a', '/p/a.png', '2026-05-10T00:00:00Z'),
        asset('b', '/p/b.png', '2026-05-09T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {'/p/a.png'},
      );
      expect(fresh.map((a) => a.id), ['b']);
    });

    test('deduplicates repeated asset ids and repeated paths', () {
      final items = [
        asset('a', '/p/a.png', '2026-05-10T00:00:00Z'),
        asset('a', '/p/a-copy.png', '2026-05-10T00:00:00Z'),
        asset('b', '/p/a.png', '2026-05-08T00:00:00Z'),
        asset('c', '/p/c.png', '2026-05-07T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {},
      );
      // 'a' second occurrence dropped by id; 'b' dropped by duplicate path.
      expect(fresh.map((a) => a.id), ['a', 'c']);
    });

    test('sorts newest modified first', () {
      final items = [
        asset('old', '/p/old.png', '2026-01-01T00:00:00Z'),
        asset('new', '/p/new.png', '2026-05-20T00:00:00Z'),
        asset('mid', '/p/mid.png', '2026-03-01T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {},
      );
      expect(fresh.map((a) => a.id), ['new', 'mid', 'old']);
    });

    test('returns empty list when everything is known', () {
      final items = [asset('a', '/p/a.png', '2026-05-10T00:00:00Z')];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {'/p/a.png'},
      );
      expect(fresh, isEmpty);
    });

    test('keeps newest occurrence when two ids share a path', () {
      final items = [
        asset('old-id', '/p/x.png', '2026-01-01T00:00:00Z'),
        asset('new-id', '/p/x.png', '2026-05-01T00:00:00Z'),
      ];
      final fresh = ScreenshotScannerService.selectNewAssets(
        assets: items,
        knownPaths: {},
      );
      // First path occurrence wins (stable de-dup), result has one entry.
      expect(fresh.length, 1);
      expect(fresh.single.path, '/p/x.png');
    });
  });

  test('assetPageSize is a positive page size for bounded pagination', () {
    expect(ScreenshotScannerService.assetPageSize, greaterThan(0));
  });
}
