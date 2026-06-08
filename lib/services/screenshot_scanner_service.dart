import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotScannerService {
  static Future<List<File>> scanScreenshots() async {
    final screenshots = <File>[];
    try {
      final directories = await _getScreenshotDirectories();
      debugPrint('[ScannerService] Checking ${directories.length} directories for screenshots...');
      for (final dir in directories) {
        final exists = await dir.exists();
        debugPrint('[ScannerService]   Dir: ${dir.path}  exists=$exists');
        if (exists) {
          try {
            await for (final entity in dir.list(recursive: true)) {
              if (entity is File && _isImageFile(entity.path)) {
                screenshots.add(entity);
              }
            }
          } catch (e) {
            debugPrint('[ScannerService]   Error listing dir ${dir.path}: $e');
          }
        }
      }
      debugPrint('[ScannerService] Total screenshots found: ${screenshots.length}');
    } catch (e) {
      debugPrint('[ScannerService] scanScreenshots error: $e');
    }
    return screenshots;
  }

  static Future<List<Directory>> _getScreenshotDirectories() async {
    final dirs = <Directory>[];
    try {
      if (Platform.isAndroid) {
        debugPrint('[ScannerService] Platform is Android');
        final extDir = await getExternalStorageDirectory();
        debugPrint('[ScannerService] getExternalStorageDirectory: ${extDir?.path}');
        if (extDir != null) {
          final base = extDir.parent.parent.parent.parent.path;
          debugPrint('[ScannerService] Base path from extDir parents: $base');
          dirs.add(Directory('$base/DCIM/Screenshots'));
          dirs.add(Directory('$base/Pictures/Screenshots'));
          dirs.add(Directory('$base/Screenshots'));
        } else {
          debugPrint('[ScannerService] getExternalStorageDirectory returned null!');
        }
        dirs.add(Directory('/storage/emulated/0/DCIM/Screenshots'));
        dirs.add(Directory('/storage/emulated/0/Pictures/Screenshots'));
        dirs.add(Directory('/storage/emulated/0/Screenshots'));
      } else if (Platform.isIOS) {
        final appDir = await getApplicationDocumentsDirectory();
        dirs.add(Directory('${appDir.path}/Screenshots'));
      }
    } catch (e) {
      debugPrint('[ScannerService] _getScreenshotDirectories error: $e');
    }
    return dirs;
  }

  static bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.webp');
  }
}
