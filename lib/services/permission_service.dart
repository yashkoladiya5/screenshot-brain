import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Coarse-grained, app-level view of gallery (photo) access.
///
/// This is the state-machine state for the gallery permission, replacing the
/// earlier "bool soup": every platform nuance (iOS limited/partial access,
/// permanently denied, OS restrictions) maps onto exactly one state.
enum GalleryPermissionStatus {
  /// Full read access to the photo library.
  granted,

  /// Partial access (iOS "Selected Photos" / Android limited media).
  /// The app can read the visible subset only.
  limited,

  /// Denied, but a fresh request will show the system dialog again.
  denied,

  /// Denied and the system will no longer show a dialog; the user must go
  /// through system settings.
  permanentlyDenied,

  /// Denied by an OS-level policy the user cannot change (e.g. parental
  /// controls on iOS). Requesting again is pointless and settings won't help.
  restricted,

  /// The current platform/OS version does not support this permission axis.
  unsupported,
}

/// Immutable result of a gallery-permission check or request.
class GalleryPermissionResult {
  const GalleryPermissionResult(this.status);

  final GalleryPermissionStatus status;

  /// Whether the app can read (at least part of) the photo library now.
  bool get canReadPhotos =>
      status == GalleryPermissionStatus.granted ||
      status == GalleryPermissionStatus.limited;

  /// Whether showing the system-settings prompt is the right next step.
  bool get shouldOpenSettings =>
      status == GalleryPermissionStatus.permanentlyDenied;

  /// Whether asking the system for permission again would surface a dialog.
  /// False for permanent denial/restriction — this is what prevents the
  /// double-prompt loop.
  bool get canRetryRequest =>
      status == GalleryPermissionStatus.denied ||
      status == GalleryPermissionStatus.unsupported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryPermissionResult && other.status == status;

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() => 'GalleryPermissionResult(${status.name})';
}

class PermissionService {
  static final _log = <String>[];
  static const int _maxLogEntries = 200;

  static void _debug(String msg) {
    debugPrint('[PermissionService] $msg');
    _log.add(msg);
    // Bound memory: drop oldest entries beyond the cap.
    if (_log.length > _maxLogEntries) {
      _log.removeRange(0, _log.length - _maxLogEntries);
    }
  }

  static List<String> get logs => List.unmodifiable(_log);

  /// Pure mapping from a permission_handler status (plus platform context)
  /// onto the app-level state machine. No plugin calls — unit-testable.
  static GalleryPermissionStatus statusFrom({
    required PermissionStatus permissionStatus,
    required bool isIos,
  }) {
    switch (permissionStatus) {
      case PermissionStatus.granted:
      // Provisional notifications-style access still allows reading.
      case PermissionStatus.provisional:
        return GalleryPermissionStatus.granted;
      case PermissionStatus.limited:
        return GalleryPermissionStatus.limited;
      case PermissionStatus.denied:
        return GalleryPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        // On iOS a plain "denied" is permanent until the user revisits
        // Settings; permission_handler already reports it as
        // permanentlyDenied, so no platform split is needed here.
        return GalleryPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return isIos
            ? GalleryPermissionStatus.restricted
            : GalleryPermissionStatus.denied;
    }
  }

  /// Checks the current gallery access WITHOUT triggering a system dialog.
  static Future<GalleryPermissionResult> checkGalleryPermission() async {
    _debug('checkGalleryPermission() called');
    final status = await _currentStatus();
    _debug('current gallery status: ${status.name}');
    return GalleryPermissionResult(status);
  }

  /// Requests gallery access following the state machine:
  ///
  /// 1. Read the current status first — if access already exists, or the
  ///    system will not show a dialog again (permanent denial / restriction),
  ///    return immediately. This is the double-prompt guard.
  /// 2. Otherwise fire exactly one request.
  /// 3. On Android, if `Permission.photos` is not the right axis for this OS
  ///    version (denied on API < 33 maps awkwardly), fall back once to
  ///    `Permission.storage`.
  static Future<GalleryPermissionResult>
  requestGalleryPermissionDetailed() async {
    _debug('requestGalleryPermissionDetailed() called');
    _debug('Platform: ${Platform.operatingSystem}');

    final current = await _currentStatus();
    final currentResult = GalleryPermissionResult(current);
    if (currentResult.canReadPhotos || !currentResult.canRetryRequest) {
      _debug('no request fired (state ${current.name} needs no/ no dialog)');
      return currentResult;
    }

    _debug('requesting Permission.photos');
    final requested = await Permission.photos.request();
    var status = statusFrom(permissionStatus: requested, isIos: Platform.isIOS);
    _debug('photos request result: ${requested.name} -> ${status.name}');

    // Android fallback: on API < 33 Permission.photos may never grant;
    // legacy storage is the equivalent axis. Request it exactly once.
    if (!Platform.isIOS &&
        (status == GalleryPermissionStatus.denied ||
            status == GalleryPermissionStatus.unsupported)) {
      _debug('photos did not grant on Android, trying storage fallback');
      final storage = await Permission.storage.request();
      final storageStatus = statusFrom(permissionStatus: storage, isIos: false);
      if (GalleryPermissionResult(storageStatus).canReadPhotos) {
        return GalleryPermissionResult(storageStatus);
      }
      // Keep the more actionable of the two states.
      if (storageStatus == GalleryPermissionStatus.permanentlyDenied) {
        status = storageStatus;
      }
    }

    return GalleryPermissionResult(status);
  }

  /// Legacy boolean API kept for existing callers (permission screen).
  static Future<bool> requestGalleryPermission() async {
    _debug('requestGalleryPermission() called');
    final result = await requestGalleryPermissionDetailed();
    return result.canReadPhotos;
  }

  /// Legacy boolean API kept for existing callers (splash, permission screen).
  static Future<bool> hasGalleryPermission() async {
    _debug('hasGalleryPermission() called');
    final result = await checkGalleryPermission();
    _debug('hasGalleryPermission => ${result.canReadPhotos}');
    return result.canReadPhotos;
  }

  /// Plain-language explanation of why the app asks for this permission,
  /// tailored to the current state. Consumed by the permission UI (W7).
  static String purposeExplanationFor(GalleryPermissionStatus status) {
    const purpose =
        'Screenshot Brain reads your screenshots so it can find payment '
        'receipts, tickets and other expense proofs, extract the text with '
        'OCR and let you search them later. Your photos are never uploaded.';

    switch (status) {
      case GalleryPermissionStatus.granted:
        return '$purpose Access is fully granted.';
      case GalleryPermissionStatus.limited:
        return '$purpose You granted access to a partial selection — '
            'screenshots outside that selection cannot be scanned. Open '
            'system settings and choose "Select app access to all photos" '
            'to scan everything.';
      case GalleryPermissionStatus.denied:
        return '$purpose Access was denied; you will be asked again.';
      case GalleryPermissionStatus.permanentlyDenied:
        return '$purpose Access was denied permanently, so the system will '
            'not show the dialog again. You must enable photo access in '
            'system settings.';
      case GalleryPermissionStatus.restricted:
        return '$purpose Access is restricted by a system policy (for '
            'example screen time or parental controls) and cannot be '
            'changed from within the app.';
      case GalleryPermissionStatus.unsupported:
        return '$purpose This device does not support the requested '
            'permission axis.';
    }
  }

  static Future<GalleryPermissionStatus> _currentStatus() async {
    final photos = await Permission.photos.status;
    var status = statusFrom(permissionStatus: photos, isIos: Platform.isIOS);
    if (status == GalleryPermissionStatus.granted ||
        status == GalleryPermissionStatus.limited) {
      return status;
    }
    if (Platform.isIOS) return status;

    // Android: photos may report denied on API < 33 while legacy storage is
    // granted.
    final storage = await Permission.storage.status;
    final storageStatus = statusFrom(permissionStatus: storage, isIos: false);
    if (GalleryPermissionResult(storageStatus).canReadPhotos) {
      return storageStatus;
    }
    // Preserve the more informative photos state when both are blocked.
    return status;
  }

  static Future<bool> openSettings() async {
    _debug('openSettings() called');
    final opened = await openAppSettings();
    _debug('openAppSettings() returned: $opened');
    return opened;
  }
}
