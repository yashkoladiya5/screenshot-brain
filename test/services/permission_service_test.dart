import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot_brain/services/permission_service.dart';

void main() {
  group('statusFrom (pure state-machine mapping)', () {
    test('maps granted and provisional to granted', () {
      expect(
        PermissionService.statusFrom(
          permissionStatus: PermissionStatus.granted,
          isIos: true,
        ),
        GalleryPermissionStatus.granted,
      );
      expect(
        PermissionService.statusFrom(
          permissionStatus: PermissionStatus.provisional,
          isIos: false,
        ),
        GalleryPermissionStatus.granted,
      );
    });

    test('maps limited to limited (iOS partial access)', () {
      expect(
        PermissionService.statusFrom(
          permissionStatus: PermissionStatus.limited,
          isIos: true,
        ),
        GalleryPermissionStatus.limited,
      );
    });

    test('maps denied and permanentlyDenied straight through', () {
      expect(
        PermissionService.statusFrom(
          permissionStatus: PermissionStatus.denied,
          isIos: true,
        ),
        GalleryPermissionStatus.denied,
      );
      expect(
        PermissionService.statusFrom(
          permissionStatus: PermissionStatus.permanentlyDenied,
          isIos: false,
        ),
        GalleryPermissionStatus.permanentlyDenied,
      );
    });

    test(
      'restricted stays restricted on iOS but degrades to denied on Android',
      () {
        expect(
          PermissionService.statusFrom(
            permissionStatus: PermissionStatus.restricted,
            isIos: true,
          ),
          GalleryPermissionStatus.restricted,
        );
        expect(
          PermissionService.statusFrom(
            permissionStatus: PermissionStatus.restricted,
            isIos: false,
          ),
          GalleryPermissionStatus.denied,
        );
      },
    );
  });

  group('GalleryPermissionResult state machine', () {
    test('granted: readable, no settings redirect, no re-request', () {
      const r = GalleryPermissionResult(GalleryPermissionStatus.granted);
      expect(r.canReadPhotos, isTrue);
      expect(r.shouldOpenSettings, isFalse);
      expect(r.canRetryRequest, isFalse);
    });

    test('limited counts as readable without needing another request', () {
      const r = GalleryPermissionResult(GalleryPermissionStatus.limited);
      expect(r.canReadPhotos, isTrue);
      expect(r.canRetryRequest, isFalse);
      expect(r.shouldOpenSettings, isFalse);
    });

    test(
      'denied: not readable, exactly the state where a dialog can appear',
      () {
        const r = GalleryPermissionResult(GalleryPermissionStatus.denied);
        expect(r.canReadPhotos, isFalse);
        expect(r.canRetryRequest, isTrue);
        expect(r.shouldOpenSettings, isFalse);
      },
    );

    test('permanentlyDenied: settings redirect, never re-prompt', () {
      const r = GalleryPermissionResult(
        GalleryPermissionStatus.permanentlyDenied,
      );
      expect(r.canReadPhotos, isFalse);
      expect(r.canRetryRequest, isFalse);
      expect(r.shouldOpenSettings, isTrue);
    });

    test('restricted: nothing the app can do', () {
      const r = GalleryPermissionResult(GalleryPermissionStatus.restricted);
      expect(r.canReadPhotos, isFalse);
      expect(r.canRetryRequest, isFalse);
      expect(r.shouldOpenSettings, isFalse);
    });

    test('result equality is value-based', () {
      expect(
        const GalleryPermissionResult(GalleryPermissionStatus.granted),
        const GalleryPermissionResult(GalleryPermissionStatus.granted),
      );
      expect(
        const GalleryPermissionResult(GalleryPermissionStatus.granted),
        isNot(const GalleryPermissionResult(GalleryPermissionStatus.limited)),
      );
    });
  });

  group('purposeExplanationFor', () {
    test('every state produces a non-empty explanation mentioning the app '
        'purpose', () {
      for (final status in GalleryPermissionStatus.values) {
        final text = PermissionService.purposeExplanationFor(status);
        expect(text, isNotEmpty, reason: status.name);
        expect(text.toLowerCase(), contains('screenshot'));
      }
    });

    test('permanentlyDenied explanation points to system settings', () {
      final text = PermissionService.purposeExplanationFor(
        GalleryPermissionStatus.permanentlyDenied,
      );
      expect(text.toLowerCase(), contains('settings'));
    });

    test('limited explanation warns about partial visibility', () {
      final text = PermissionService.purposeExplanationFor(
        GalleryPermissionStatus.limited,
      );
      expect(text.toLowerCase(), contains('partial'));
    });

    test('restricted explanation mentions system policy', () {
      final text = PermissionService.purposeExplanationFor(
        GalleryPermissionStatus.restricted,
      );
      expect(text.toLowerCase(), contains('restricted'));
    });
  });
}
