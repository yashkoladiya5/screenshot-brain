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
            discovered.add(
              ScannedAsset(
                id: asset.id,
                path: file.path,
                modified: created ?? DateTime.fromMillisecondsSinceEpoch(0),
              ),
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

  /// True when an album name or relative path marks it as a screenshots album.
  static bool isScreenshotAlbumName(
    String albumName, {
    String relativePath = '',
  }) {
    final name = albumName.toLowerCase();
    final relPath = relativePath.toLowerCase();
    return name.contains('screenshot') ||
        relPath.contains('screenshot') ||
        relPath.contains('dcim/screenshots') ||
        relPath.contains('pictures/screenshots');
  }

  /// True when an asset's title or relative path looks like a screenshot.
  static bool looksLikeScreenshot(String title, String relativePath) {
    final t = title.toLowerCase();
    final rp = relativePath.toLowerCase();
    return t.contains('screenshot') || rp.contains('screenshots');
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

  /// Returns assets that are not already known, deduplicated by id and path,
  /// sorted newest-modified first.
  static List<ScannedAsset> selectNewAssets({
    required Iterable<ScannedAsset> assets,
    required Set<String> knownPaths,
  }) {
    final seenIds = <String>{};
    final byPath = <String, ScannedAsset>{};
    for (final asset in assets) {
      if (!seenIds.add(asset.id)) continue;
      if (knownPaths.contains(asset.path)) continue;
      // First occurrence of a path wins; identical paths from different asset
      // ids (e.g. duplicates across albums) are collapsed.
      byPath.putIfAbsent(asset.path, () => asset);
    }
    final result = byPath.values.toList()
      ..sort((a, b) => b.modified.compareTo(a.modified));
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
