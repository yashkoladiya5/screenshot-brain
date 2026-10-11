import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot_brain/features/permissions/screens/permission_screen.dart';
import 'package:screenshot_brain/services/permission_service.dart';

/// Drives [PermissionScreen] through fake seams so no test ever touches the
/// real `permission_handler` plugin.
class _Harness {
  int checkCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;
  int grantedNavigations = 0;

  /// Statuses returned by successive `check` calls (last value repeats).
  List<GalleryPermissionStatus> checkQueue;

  /// Status returned by the (single) `request` call.
  GalleryPermissionStatus requestResult;

  bool settingsOpen = true;

  _Harness({
    required GalleryPermissionStatus initialStatus,
    List<GalleryPermissionStatus>? moreStatuses,
    this.requestResult = GalleryPermissionStatus.granted,
  }) : checkQueue = [initialStatus, ...?moreStatuses];

  GalleryPermissionStatus _nextCheck() {
    final status = checkQueue.first;
    if (checkQueue.length > 1) checkQueue = checkQueue.sublist(1);
    return status;
  }

  Future<GalleryPermissionResult> _check() async {
    checkCalls++;
    return GalleryPermissionResult(_nextCheck());
  }

  Future<GalleryPermissionResult> _request() async {
    requestCalls++;
    return GalleryPermissionResult(requestResult);
  }

  Future<bool> _openSettings() async {
    openSettingsCalls++;
    return settingsOpen;
  }

  void _onGranted(BuildContext _) => grantedNavigations++;

  Widget build() => MaterialApp(
    home: PermissionScreen(
      checkPermission: _check,
      requestPermission: _request,
      openSettingsAction: _openSettings,
      purposeExplainer: PermissionService.purposeExplanationFor,
      onPermissionGranted: _onGranted,
    ),
  );
}

void main() {
  group('PermissionScreen state machine', () {
    testWidgets('first paint only CHECKS; granted status navigates and '
        'never fires a request (no double prompt)', (tester) async {
      final h = _Harness(initialStatus: GalleryPermissionStatus.granted);
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      expect(h.checkCalls, 1);
      expect(h.requestCalls, 0);
      expect(h.grantedNavigations, 1);
    });

    testWidgets('denied: shows denied-purpose copy and grants after one '
        'user-initiated request', (tester) async {
      final h = _Harness(initialStatus: GalleryPermissionStatus.denied);
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      // No auto-request on entry.
      expect(h.requestCalls, 0);
      expect(
        find.textContaining('Access was denied; you will be asked again'),
        findsOneWidget,
      );
      expect(find.text('Grant Access'), findsOneWidget);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await tester.pumpAndSettle();

      expect(h.requestCalls, 1);
      expect(h.grantedNavigations, 1);
    });

    testWidgets('denied request that stays denied re-renders the denied '
        'state with feedback instead of navigating', (tester) async {
      final h = _Harness(
        initialStatus: GalleryPermissionStatus.denied,
        requestResult: GalleryPermissionStatus.denied,
      );
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await tester.pumpAndSettle();

      expect(h.grantedNavigations, 0);
      expect(find.textContaining('Access was denied'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('permanentlyDenied: primary action opens settings and '
        're-checks; the system dialog is never re-triggered', (tester) async {
      final h = _Harness(
        initialStatus: GalleryPermissionStatus.permanentlyDenied,
      );
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      expect(find.text('Permission Required'), findsOneWidget);
      expect(find.textContaining('not show the dialog again'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      // Retryable secondary button must NOT be offered in this state.
      expect(find.text('Grant Access'), findsNothing);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await tester.pumpAndSettle();

      expect(h.openSettingsCalls, 1);
      // Settings opened but status unchanged: re-check happened, no nav.
      expect(h.checkCalls, 2);
      expect(h.requestCalls, 0);
      expect(h.grantedNavigations, 0);
    });

    testWidgets('permanentlyDenied -> user enables in settings -> post-'
        'request re-check grants and navigates', (tester) async {
      final h = _Harness(
        initialStatus: GalleryPermissionStatus.permanentlyDenied,
        moreStatuses: [GalleryPermissionStatus.granted],
      );
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await tester.pumpAndSettle();

      expect(h.grantedNavigations, 1);
      expect(h.requestCalls, 0);
    });

    testWidgets('limited: partial-access copy, continue navigates, no '
        'pointless request', (tester) async {
      final h = _Harness(initialStatus: GalleryPermissionStatus.limited);
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      expect(find.text('Limited Photo Access'), findsOneWidget);
      expect(find.textContaining('partial selection'), findsOneWidget);
      expect(find.text('Continue with Limited Access'), findsOneWidget);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await tester.pumpAndSettle();

      expect(h.grantedNavigations, 1);
      expect(h.requestCalls, 0);
    });

    testWidgets('restricted: policy copy, re-check-only action, settings '
        'button hidden, request never fires', (tester) async {
      final h = _Harness(initialStatus: GalleryPermissionStatus.restricted);
      await tester.pumpWidget(h.build());
      await tester.pumpAndSettle();

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.textContaining('system policy'), findsOneWidget);
      expect(find.text('Re-check Access'), findsOneWidget);
      expect(find.byKey(const Key('permissionOpenSettings')), findsNothing);

      await tester.tap(find.byKey(const Key('permissionPrimaryButton')));
      await tester.pumpAndSettle();

      expect(h.checkCalls, 2);
      expect(h.requestCalls, 0);
      expect(h.grantedNavigations, 0);
    });
  });
}
