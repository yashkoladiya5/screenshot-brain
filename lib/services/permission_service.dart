import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final _log = <String>[];

  static void _debug(String msg) {
    debugPrint('[PermissionService] $msg');
    _log.add(msg);
  }

  static List<String> get logs => List.unmodifiable(_log);

  static Future<bool> requestGalleryPermission() async {
    _debug('requestGalleryPermission() called');
    _debug('Platform: ${Platform.operatingSystem}');

    if (Platform.isIOS) {
      _debug('iOS: requesting Permission.photos');
      final status = await Permission.photos.request();
      _debug('iOS photos status: ${status.name} (isGranted: ${status.isGranted}, isLimited: ${status.isLimited})');
      return status.isGranted || status.isLimited;
    }

    // Android: use Permission.photos which maps to READ_MEDIA_IMAGES (API 33+)
    // or READ_EXTERNAL_STORAGE (older) automatically via permission_handler
    _debug('Android: requesting Permission.photos (handles all API levels)');
    final photosStatus = await Permission.photos.request();
    _debug('Android photos status: ${photosStatus.name} (isGranted: ${photosStatus.isGranted})');

    if (photosStatus.isGranted) return true;

    if (photosStatus.isLimited) {
      _debug('Android photos isLimited = true');
      return true;
    }

    if (photosStatus.isPermanentlyDenied) {
      _debug('Android photos permanently denied');
      return false;
    }

    // If photos was denied, try storage as fallback for older API levels
    _debug('Photos denied, trying Permission.storage as fallback');
    final storageStatus = await Permission.storage.request();
    _debug('Android storage fallback status: ${storageStatus.name}');
    return storageStatus.isGranted;
  }

  static Future<bool> hasGalleryPermission() async {
    _debug('hasGalleryPermission() called');

    if (Platform.isIOS) {
      final granted = await Permission.photos.isGranted;
      final limited = await Permission.photos.isLimited;
      _debug('iOS hasGalleryPermission: granted=$granted, limited=$limited');
      return granted || limited;
    }

    // Android: check photos first (API 33+), fallback to storage
    final photosGranted = await Permission.photos.isGranted;
    _debug('Android photos.isGranted: $photosGranted');
    if (photosGranted) return true;

    final storageGranted = await Permission.storage.isGranted;
    _debug('Android storage.isGranted: $storageGranted');
    return storageGranted;
  }

  static Future<bool> openSettings() async {
    _debug('openSettings() called');
    final opened = await openAppSettings();
    _debug('openAppSettings() returned: $opened');
    return opened;
  }
}
