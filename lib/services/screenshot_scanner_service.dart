import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// Plain-data snapshot of a screenshot candidate discovered during a scan.
///
/// Deliberately plugin-free so that the scanning decision logic
/// (new-file diffing, date-window filtering, dedupe/sort) can be unit tested
/// without any native photo_manager bindings.
class ScannedAsset {
  const ScannedAsset({
    required this.id,
    required this.path,
    required this.modified,
  });

  /// photo_manager asset id (stable across albums).
  final String id;

  /// Resolved filesystem path of the asset.
  final String path;

  /// Last-known modification time (asset create date).
  final DateTime modified;

  @override
  String toString() =>
      'ScannedAsset(id: $id, path: $path, modified: $modified)';
}

class ScreenshotScannerService {
  /// Number of assets requested from photo_manager per page.
  ///
  /// The scan walks albums in fixed-size pages instead of materializing every
  /// asset entity at once, so memory stays bounded on large libraries.
  static const int assetPageSize = 100;

  /// Scans the device for screenshot images.
  ///
  /// [knownPaths] are paths already persisted by the caller; they are excluded
  /// from the result. [notBefore] drops assets created before that instant
  /// (e.g. derived from `AppSettings.scanIntervalHours`).
  ///
  /// Results are deduplicated by asset id and path and sorted newest first.
  /// Failures of individual albums are isolated and logged; unexpected
  /// top-level errors propagate to the caller instead of being swallowed.
  static Future<List<File>> scanScreenshots({
    Set<String> knownPaths = const {},
    DateTime? notBefore,
  }) async {
    debugPrint('[ScannerService] === Starting scan via photo_manager ===');

    final permission = await PhotoManager.requestPermissionExtend();
    debugPrint(
      '[ScannerService] photo_manager permission: $permission '
      '(hasAccess=${permission.hasAccess})',
    );
    if (!permission.hasAccess) {
      debugPrint('[ScannerService] Permission denied — cannot scan');
      return const [];
    }

    // hasAll: true guarantees the "All" entity is present; it is used as a
    // fallback source when no album is explicitly named like a screenshot
    // album (some OEM galleries only expose screenshots through "All").
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    debugPrint('[ScannerService] Found ${paths.length} image albums on device');

    final screenshotAlbums = <AssetPathEntity>[];
    AssetPathEntity? allAlbum;
    for (final path in paths) {
      final relPath = (await path.relativePathAsync) ?? '';
      if (isScreenshotAlbumName(path.name, relativePath: relPath)) {
        final count = await path.assetCountAsync;
        debugPrint(
          '[ScannerService]   MATCH: "${path.name}" '
          'relativePath="$relPath" assets=$count',
        );
        screenshotAlbums.add(path);
      } else if (path.isAll) {
        allAlbum = path;
      }
    }

    var targetAlbums = screenshotAlbums;
    var fallbackToAll = false;
    if (targetAlbums.isEmpty && allAlbum != null) {
      // No dedicated screenshot album: scan "All" but keep only assets whose
      // title/relative path looks like a screenshot.
      debugPrint('[ScannerService] No screenshot album — falling back to All');
      targetAlbums = [allAlbum];
      fallbackToAll = true;
    }

    debugPrint(
      '[ScannerService] Processing ${targetAlbums.length} album(s) '
      '(fallbackTitleFilter=$fallbackToAll)',
    );

    final discovered = <ScannedAsset>[];
    final seenIds = <String>{};
    final failedAlbums = <String>[];

    for (final album in targetAlbums) {
      try {
        final count = await album.assetCountAsync;
        debugPrint('[ScannerService] Album "${album.name}": $count assets');
        if (count == 0) continue;

        var processed = 0;
        for (var page = 0; processed < count; page++) {
          final assets = await album.getAssetListPaged(
            page: page,
            size: assetPageSize,
          );
          if (assets.isEmpty) break;
          processed += assets.length;

          for (final asset in assets) {
            // The same asset can appear in several albums; resolve each id
            // exactly once.
            if (!seenIds.add(asset.id)) continue;
            if (fallbackToAll &&
                !looksLikeScreenshot(
                  asset.title ?? '',
                  asset.relativePath ?? '',
                )) {
              continue;
            }
            // Cheap date filter before touching the filesystem. Assets whose
            // creation time is unknown are kept unless a window is set.
            final created = asset.createDateSecond == null
                ? null
                : asset.createDateTime;
            if (created != null &&
                !isWithinWindow(created, notBefore: notBefore)) {
              continue;
            }
            final file = await _fileFor(asset);
            if (file == null) {
              debugPrint(
                '[ScannerService]   No accessible file for asset ${asset.id}',
              );
              continue;
            }
            // When the media store reports no creation time, fall back to the
            // timestamp encoded in the file name (screenshot formats carry it
            // almost universally) so ordering is not arbitrary epoch-0.
            final modified =
                created ??
                timestampFromFilename(asset.title ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            discovered.add(
              ScannedAsset(id: asset.id, path: file.path, modified: modified),
            );
          }

          if (assets.length < assetPageSize) break; // final page reached
        }
      } catch (e, stack) {
        // Isolate one corrupt album; other albums still contribute results.
        failedAlbums.add(album.name);
        debugPrint('[ScannerService] Album "${album.name}" failed: $e');
        debugPrint('[ScannerService] stack: $stack');
      }
    }

    final fresh = selectNewAssets(assets: discovered, knownPaths: knownPaths);
    if (failedAlbums.isNotEmpty) {
      debugPrint(
        '[ScannerService] ${failedAlbums.length} album(s) failed: '
        '${failedAlbums.join(', ')}',
      );
    }
    debugPrint(
      '[ScannerService] === Scan complete: ${fresh.length} new screenshot '
      'files (of ${discovered.length} discovered) ===',
    );
    return fresh.map((a) => File(a.path)).toList(growable: false);
  }

  // --------------------------------------------------------------------------
  // Pure helpers — no plugins, no filesystem, fully unit-testable.
  // --------------------------------------------------------------------------

  /// Lower-cased name fragments that mark a file/album as screenshot material
  /// across the locales this app ships in (AOSP localises the default
  /// screenshot file name, iOS/macOS use "Screen Shot", OEM galleries use
  /// singular/plural "Screenshot(s)" folders).
  static const List<String> screenshotHintTokens = [
    'screenshot', // Android OEMs, English
    'screen shot', // iOS Simulator / macOS
    '截图', // zh-CN
    '截圖', // zh-TW (also matches 螢幕截圖)
    'スクリーンショット', // ja-JP
    '스크린샷', // ko-KR
    'bildschirmfoto', // de-DE
    'capture d’écran', // fr-FR (typographic apostrophe)
    "capture d'ecran", // fr-FR (ASCII apostrophe)
    'captura de pantalla', // es-ES / es-419
    'captura de tela', // pt-BR / pt-PT
    'снимок экрана', // ru-RU
  ];

  /// English month names mapped to month numbers, used by the filename
  /// timestamp parser (screenshot file names carry English month names in
  /// practice; localised ones are matched as screenshot hints instead).
  ///
  /// Insertion order matters when building the regex: full names are listed
  /// before their abbreviations so "December" can never be consumed as "Dec".
  static const Map<String, int> _monthNames = {
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static final RegExp _monthNameBeforeDay = RegExp(
    '\\b(${_monthNames.keys.toList().join('|')})'
    r'\.?[, ]?(\d{1,2})(?:st|nd|rd|th)?[, ]+((?:19|20)\d{2})(?!\d)',
  );

  static final RegExp _dayBeforeMonthName = RegExp(
    r'(?<!\d)(\d{1,2})(?:st|nd|rd|th)?[ ,]('
    '${_monthNames.keys.toList().join('|')})'
    r'\.?[, ]+((?:19|20)\d{2})(?!\d)',
  );

  static final RegExp _compactDate = RegExp(
    r'(?<!\d)((?:19|20)\d{2})(\d{2})(\d{2})(?:[-_](\d{2})(\d{2})(\d{2}))?(?!\d)',
  );

  static final RegExp _isoDate = RegExp(
    r'(?<!\d)((?:19|20)\d{2})[-./](\d{1,2})[-./](\d{1,2})(?!\d)'
    r'(?:\s*(?:at\s+)?(\d{1,2})[:.](\d{1,2})(?:[:.](\d{1,2}))?)?',
  );

  static const Set<String> _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'heic',
    'heif',
    'gif',
    'bmp',
    'tif',
    'tiff',
  };

  static bool _hasScreenshotHint(String lowerCased) =>
      screenshotHintTokens.any(lowerCased.contains);

  /// True when an album name or relative path marks it as a screenshots album.
  static bool isScreenshotAlbumName(
    String albumName, {
    String relativePath = '',
  }) {
    return _hasScreenshotHint(albumName.toLowerCase()) ||
        _hasScreenshotHint(relativePath.toLowerCase());
  }

  /// True when an asset's title or relative path looks like a screenshot.
  ///
  /// A title match must also pass the image-extension gate (a missing
  /// extension is accepted: iOS display titles sometimes omit it and the
  /// assets fed here already come from an image-only query), so plain text
  /// files that merely contain the word "screenshot" are not indexed.
  static bool looksLikeScreenshot(String title, String relativePath) {
    final t = title.toLowerCase();
    if (_hasScreenshotHint(t) && hasImageExtension(title)) return true;
    return _hasScreenshotHint(relativePath.toLowerCase());
  }

  /// Lower-cased extension (without the dot) of the trailing name component,
  /// or '' when there is none. Uses the LAST dot of the basename, so dotted
  /// names ('a.b.c.heic'), hidden files ('.hidden.png') and paths with
  /// multiple dots are handled — splitting on '.' and taking the last token
  /// would not be, because it ignores path separators.
  static String extensionOf(String name) {
    final basename = name.split(RegExp(r'[/\\]')).last;
    final dot = basename.lastIndexOf('.');
    if (dot < 0) return '';
    return basename.substring(dot + 1).toLowerCase();
  }

  /// True when [name] has a known image extension or no extension at all
  /// (unknown is treated as image, since callers filter by image type first).
  static bool hasImageExtension(String name) {
    final ext = extensionOf(name);
    return ext.isEmpty || _imageExtensions.contains(ext);
  }

  /// Case-insensitive, backslash-normalised identity key for a device path.
  ///
  /// The storages this app scans (Android volumes, iOS, case-insensitive
  /// APFS) treat case variants as the same file; keying dedupe on the raw
  /// path caused the same screenshot to be indexed twice under paths like
  /// '/p/A.png' and '/p/a.png'.
  static String pathDedupeKey(String path) =>
      path.trim().replaceAll('\\', '/').toLowerCase();

  /// Natural (numeric-aware) string comparison: 'IMG_9.png' sorts BEFORE
  /// 'IMG_10.png', unlike plain lexicographic comparison. Case-insensitive;
  /// digit runs are compared by value, leading zeros are insignificant.
  static int compareNatural(String a, String b) {
    final x = a.toLowerCase();
    final y = b.toLowerCase();
    var i = 0;
    var j = 0;
    while (i < x.length && j < y.length) {
      final cx = x.codeUnitAt(i);
      final cy = y.codeUnitAt(j);
      final dx = _isDigit(cx);
      final dy = _isDigit(cy);
      if (dx && dy) {
        var xe = i;
        while (xe < x.length && _isDigit(x.codeUnitAt(xe))) {
          xe++;
        }
        var ye = j;
        while (ye < y.length && _isDigit(y.codeUnitAt(ye))) {
          ye++;
        }
        final sx = _stripLeadingZeros(x.substring(i, xe));
        final sy = _stripLeadingZeros(y.substring(j, ye));
        if (sx.length != sy.length) return sx.length - sy.length;
        final cmp = sx.compareTo(sy);
        if (cmp != 0) return cmp;
        i = xe;
        j = ye;
      } else {
        if (cx != cy) return cx - cy;
        i++;
        j++;
      }
    }
    final restX = x.length - i;
    final restY = y.length - j;
    return restX - restY;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

  static String _stripLeadingZeros(String digits) {
    var start = 0;
    while (start < digits.length - 1 && digits.codeUnitAt(start) == 0x30) {
      start++;
    }
    return digits.substring(start);
  }

  /// Extracts the capture timestamp encoded in a screenshot file name, or
  /// null when the name carries none / carries an impossible date.
  ///
  /// Supported: compact 'Screenshot_20240101-120000' (Android OEMs),
  /// ISO '2024-01-31[ at 12.00.00 / 07:05:09]' (iOS/macOS), and English
  /// month-name dates in either order ('Dec 31 2024', '5 January 2024').
  /// Month 13, day 32, non-leap Feb 29 etc. are rejected rather than
  /// silently rolled over into a garbage date. Month-name alternatives list
  /// full names before abbreviations so 'December' is never consumed as 'Dec'.
  static DateTime? timestampFromFilename(String name) {
    if (name.isEmpty) return null;
    final lower = name.toLowerCase();

    final compact = _compactDate.firstMatch(lower);
    if (compact != null) {
      return _validated(
        int.parse(compact.group(1)!),
        int.parse(compact.group(2)!),
        int.parse(compact.group(3)!),
        hour: compact.group(4) == null ? 0 : int.parse(compact.group(4)!),
        minute: compact.group(5) == null ? 0 : int.parse(compact.group(5)!),
        second: compact.group(6) == null ? 0 : int.parse(compact.group(6)!),
      );
    }

    final iso = _isoDate.firstMatch(lower);
    if (iso != null) {
      return _validated(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
        hour: iso.group(4) == null ? 0 : int.parse(iso.group(4)!),
        minute: iso.group(5) == null ? 0 : int.parse(iso.group(5)!),
        second: iso.group(6) == null ? 0 : int.parse(iso.group(6)!),
      );
    }

    final monthFirst = _monthNameBeforeDay.firstMatch(lower);
    if (monthFirst != null) {
      final month = _monthNames[monthFirst.group(1)!.substring(0, 3)];
      if (month != null) {
        return _validated(
          int.parse(monthFirst.group(3)!),
          month,
          int.parse(monthFirst.group(2)!),
        );
      }
      return null;
    }

    final dayFirst = _dayBeforeMonthName.firstMatch(lower);
    if (dayFirst != null) {
      final month = _monthNames[dayFirst.group(2)!.substring(0, 3)];
      if (month != null) {
        return _validated(
          int.parse(dayFirst.group(3)!),
          month,
          int.parse(dayFirst.group(1)!),
        );
      }
    }
    return null;
  }

  static DateTime? _validated(
    int year,
    int month,
    int day, {
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > _daysInMonth(year, month)) return null;
    if (hour > 23 || minute > 59 || second > 59) return null;
    return DateTime(year, month, day, hour, minute, second);
  }

  static int _daysInMonth(int year, int month) {
    const common = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month != 2) return common[month - 1];
    final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    return isLeap ? 29 : 28;
  }

  /// Half-open-safe window check: [notBefore] <= value <= [notAfter].
  static bool isWithinWindow(
    DateTime value, {
    DateTime? notBefore,
    DateTime? notAfter,
  }) {
    if (notBefore != null && value.isBefore(notBefore)) return false;
    if (notAfter != null && value.isAfter(notAfter)) return false;
    return true;
  }

  /// Drops assets outside the given date window.
  static List<ScannedAsset> filterDateWindow(
    Iterable<ScannedAsset> assets, {
    DateTime? notBefore,
    DateTime? notAfter,
  }) {
    return assets
        .where(
          (a) => isWithinWindow(
            a.modified,
            notBefore: notBefore,
            notAfter: notAfter,
          ),
        )
        .toList(growable: false);
  }

  /// Returns assets that are not already known, deduplicated by id and by
  /// case-insensitive path identity ([pathDedupeKey]), sorted newest-modified
  /// first. Equal timestamps are ordered by natural path comparison so the
  /// result never depends on the album enumeration order.
  static List<ScannedAsset> selectNewAssets({
    required Iterable<ScannedAsset> assets,
    required Set<String> knownPaths,
  }) {
    final knownKeys = knownPaths.map(pathDedupeKey).toSet();
    final seenIds = <String>{};
    final byPathKey = <String, ScannedAsset>{};
    for (final asset in assets) {
      if (!seenIds.add(asset.id)) continue;
      final key = pathDedupeKey(asset.path);
      if (knownKeys.contains(key)) continue;
      // First occurrence of a path wins; identical paths from different asset
      // ids (e.g. duplicates across albums) are collapsed.
      byPathKey.putIfAbsent(key, () => asset);
    }
    final result = byPathKey.values.toList()
      ..sort((a, b) {
        final byTime = b.modified.compareTo(a.modified);
        if (byTime != 0) return byTime;
        final byName = compareNatural(a.path, b.path);
        if (byName != 0) return byName;
        return a.path.compareTo(b.path);
      });
    return result;
  }

  static Future<File?> _fileFor(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file != null) return file;
      return await asset.originFile;
    } catch (e) {
      debugPrint('[ScannerService]   file lookup failed for ${asset.id}: $e');
      return null;
    }
  }
}
