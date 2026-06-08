import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestGalleryPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    } else {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
  }

  static Future<bool> hasGalleryPermission() async {
    if (Platform.isIOS) {
      return await Permission.photos.isGranted || await Permission.photos.isLimited;
    }
    return await Permission.storage.isGranted;
  }

  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
