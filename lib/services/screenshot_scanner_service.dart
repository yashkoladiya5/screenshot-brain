import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class ScreenshotScannerService {
  static Future<List<File>> scanScreenshots() async {
    final files = <File>[];
    try {
      debugPrint('[ScannerService] === Starting scan via photo_manager ===');

      if (Platform.isAndroid) {
        debugPrint('[ScannerService] Platform is Android');
      } else if (Platform.isIOS) {
        debugPrint('[ScannerService] Platform is iOS');
      }

      // Request permission through photo_manager
      final permission = await PhotoManager.requestPermissionExtend();
      debugPrint('[ScannerService] photo_manager permission: $permission (hasAccess=${permission.hasAccess})');
      if (!permission.hasAccess) {
        debugPrint('[ScannerService] Permission denied — cannot scan');
        return files;
      }

      // Get all image albums from the device
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
      );
      debugPrint('[ScannerService] Found ${paths.length} image albums on device');

      // Filter for albums that contain "Screenshot" in their name
      final screenshotAlbums = <AssetPathEntity>[];
      for (final path in paths) {
        final name = path.name.toLowerCase();
        final relPath = (await path.relativePathAsync)?.toLowerCase() ?? '';
        final isScreenshot = name.contains('screenshot') ||
            relPath.contains('screenshot') ||
            relPath.contains('dcim/screenshots') ||
            relPath.contains('pictures/screenshots');
        if (isScreenshot) {
          final count = await path.assetCountAsync;
          debugPrint('[ScannerService]   MATCH: "${path.name}" relativePath="$relPath" assets=$count');
          screenshotAlbums.add(path);
        }
      }

      debugPrint('[ScannerService] Found ${screenshotAlbums.length} screenshot albums');

      for (final album in screenshotAlbums) {
        final count = await album.assetCountAsync;
        debugPrint('[ScannerService] Processing album: "${album.name}" ($count assets)');
        final assets = await album.getAssetListPaged(
          page: 0,
          size: count,
        );
        debugPrint('[ScannerService]   Fetched ${assets.length} assets from album');

        for (final asset in assets) {
          debugPrint('[ScannerService]   Asset: id=${asset.id} title="${asset.title}" relativePath="${asset.relativePath}"');
          final file = await asset.file;
          if (file != null) {
            files.add(file);
            debugPrint('[ScannerService]     File: ${file.path}');
          } else {
            final originFile = await asset.originFile;
            if (originFile != null) {
              files.add(originFile);
              debugPrint('[ScannerService]     OriginFile: ${originFile.path}');
            } else {
              debugPrint('[ScannerService]     No accessible file for asset ${asset.id}');
            }
          }
        }
      }

      debugPrint('[ScannerService] === Scan complete: ${files.length} screenshot files found ===');
    } catch (e, stack) {
      debugPrint('[ScannerService] scanScreenshots error: $e');
      debugPrint('[ScannerService] stack: $stack');
    }
    return files;
  }
}
