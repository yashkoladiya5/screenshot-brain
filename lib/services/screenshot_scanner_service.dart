import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ScreenshotScannerService {
  static Future<List<File>> scanScreenshots() async {
    final screenshots = <File>[];
    try {
      final directories = await _getScreenshotDirectories();
      for (final dir in directories) {
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File && _isImageFile(entity.path)) {
              screenshots.add(entity);
            }
          }
        }
      }
    } catch (_) {}
    return screenshots;
  }

  static Future<List<Directory>> _getScreenshotDirectories() async {
    final dirs = <Directory>[];
    try {
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          dirs.add(Directory('${extDir.parent.parent.parent.parent.path}/DCIM/Screenshots'));
          dirs.add(Directory('${extDir.parent.parent.parent.parent.path}/Pictures/Screenshots'));
          dirs.add(Directory('${extDir.parent.parent.parent.parent.path}/Screenshots'));
        }
        dirs.add(Directory('/storage/emulated/0/DCIM/Screenshots'));
        dirs.add(Directory('/storage/emulated/0/Pictures/Screenshots'));
        dirs.add(Directory('/storage/emulated/0/Screenshots'));
      } else if (Platform.isIOS) {
        final appDir = await getApplicationDocumentsDirectory();
        dirs.add(Directory('${appDir.path}/Screenshots'));
      }
    } catch (_) {}
    return dirs;
  }

  static bool _isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.webp');
  }
}
