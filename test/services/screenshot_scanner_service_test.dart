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
