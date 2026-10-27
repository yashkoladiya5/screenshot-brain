import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../services/permission_service.dart';

/// Seam types so the screen can be driven by fakes in tests without ever
/// touching the `permission_handler` plugin. Defaults wire to the real
/// [PermissionService] statics; the service itself is untouched.
typedef GalleryPermissionCheck = Future<GalleryPermissionResult> Function();
typedef GalleryPermissionRequest = Future<GalleryPermissionResult> Function();
typedef GallerySettingsOpener = Future<bool> Function();
typedef PermissionPurposeExplainer =
    String Function(GalleryPermissionStatus status);

/// Gallery-permission onboarding built on the [GalleryPermissionStatus]
/// state machine.
///
/// Contract with the state machine:
/// * First paint only *checks* the current status — it never fires a request,
///   so the system dialog cannot prompt twice on entry.
/// * A user-initiated grant goes through [PermissionService
///   .requestGalleryPermissionDetailed], which itself refuses to re-prompt
///   when the system would not show a dialog (permanent denial/restriction).
/// * After the request (and after returning from system settings) the status
///   is re-checked and the UI re-renders from the fresh state.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({
    super.key,
    this.checkPermission,
    this.requestPermission,
    this.openSettingsAction,
    this.purposeExplainer,
    this.onPermissionGranted,
  });

  /// Check-only seam (no dialog). Defaults to
  /// `PermissionService.checkGalleryPermission`.
  final GalleryPermissionCheck? checkPermission;

  /// Request seam. Defaults to
  /// `PermissionService.requestGalleryPermissionDetailed`.
  final GalleryPermissionRequest? requestPermission;

  /// Open-app-settings seam. Defaults to `PermissionService.openSettings`.
  final GallerySettingsOpener? openSettingsAction;

  /// Purpose-copy seam. Defaults to
  /// `PermissionService.purposeExplanationFor`.
  final PermissionPurposeExplainer? purposeExplainer;

  /// Navigation seam invoked whenever gallery reading is available.
  /// Defaults to `context.go('/home')`.
  final void Function(BuildContext context)? onPermissionGranted;

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  GalleryPermissionStatus? _status;
  bool _isChecking = true;
  bool _isBusy = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  GalleryPermissionCheck get _check =>
      widget.checkPermission ?? PermissionService.checkGalleryPermission;
  GalleryPermissionRequest get _request =>
      widget.requestPermission ??
      PermissionService.requestGalleryPermissionDetailed;
  GallerySettingsOpener get _openSettings =>
      widget.openSettingsAction ?? PermissionService.openSettings;
  PermissionPurposeExplainer get _explain =>
      widget.purposeExplainer ?? PermissionService.purposeExplanationFor;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    // First paint: CHECK only. Never request here — that is what would
    // double-prompt the system dialog on entry.
    _recheck(navigateWhenReadable: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateOnGranted() {
    final onGranted = widget.onPermissionGranted;
    if (onGranted != null) {
      onGranted(context);
    } else {
      context.go('/home');
    }
  }

  /// Re-reads the status without prompting and repaints. When
  /// [navigateWhenReadable] is true, full access leaves the screen; limited
  /// access still shows the partial-access note so the user can act on it.
  Future<void> _recheck({bool navigateWhenReadable = false}) async {
    final result = await _check();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _isChecking = false;
      _isBusy = false;
    });
    if (result.status == GalleryPermissionStatus.granted &&
        navigateWhenReadable) {
      _navigateOnGranted();
    }
  }

  Future<void> _requestPermission() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final result = await _request();
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _isChecking = false;
      _isBusy = false;
    });
    if (result.status == GalleryPermissionStatus.granted) {
      _navigateOnGranted();
      return;
    }
    if (!result.canReadPhotos) {
      _showFeedback(_messageFor(result.status));
    }
  }

  /// Settings round-trip: open settings, then re-check on return so the UI
  /// catches up with whatever the user changed manually.
  Future<void> _openSettingsAndRecheck() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final opened = await _openSettings();
    if (!mounted) return;
    if (!opened) {
      setState(() => _isBusy = false);
      _showFeedback('Could not open system settings.');
      return;
    }
    await _recheck(navigateWhenReadable: true);
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  static String _titleFor(GalleryPermissionStatus status) {
    switch (status) {
      case GalleryPermissionStatus.granted:
        return 'Access Granted';
      case GalleryPermissionStatus.limited:
        return 'Limited Photo Access';
      case GalleryPermissionStatus.denied:
      case GalleryPermissionStatus.unsupported:
        return 'Access Your Screenshots';
      case GalleryPermissionStatus.permanentlyDenied:
        return 'Permission Required';
      case GalleryPermissionStatus.restricted:
        return 'Access Restricted';
    }
  }

  static String _messageFor(GalleryPermissionStatus status) {
    switch (status) {
      case GalleryPermissionStatus.limited:
        return 'You selected only some photos. You can change that in '
            'settings to scan everything.';
      case GalleryPermissionStatus.permanentlyDenied:
        return 'Permission is permanently denied. Enable photo access in '
            'system settings.';
      case GalleryPermissionStatus.restricted:
        return 'Access is restricted by a system policy and cannot be '
            'changed from the app.';
      case GalleryPermissionStatus.denied:
      case GalleryPermissionStatus.unsupported:
      case GalleryPermissionStatus.granted:
        return 'Access is still denied. You can try again.';
    }
  }

  /// Primary action label implied by the current state machine.
  String get _primaryLabel {
    switch (_status) {
      case GalleryPermissionStatus.granted:
        // Access already exists: the only sane action is to continue.
        // Falling through to 'Grant Access' here is what would re-fire the
        // request seam while already granted (double prompt).
        return 'Continue';
      case GalleryPermissionStatus.limited:
        return 'Continue with Limited Access';
      case GalleryPermissionStatus.permanentlyDenied:
        return 'Open Settings';
      case GalleryPermissionStatus.restricted:
        return 'Re-check Access';
      default:
        return 'Grant Access';
    }
  }

  Future<void> _onPrimaryPressed() {
    switch (_status) {
      case GalleryPermissionStatus.granted:
        // Already readable: re-navigate instead of re-running the request
        // seam — the screen must never prompt again in this state.
        _navigateOnGranted();
        return Future.value();
      case GalleryPermissionStatus.limited:
        _navigateOnGranted();
        return Future.value();
      case GalleryPermissionStatus.permanentlyDenied:
        return _openSettingsAndRecheck();
      case GalleryPermissionStatus.restricted:
        return _recheck(navigateWhenReadable: true);
      default:
        // denied / unsupported: the only states where a system dialog exists.
        return _requestPermission();
    }
  }

  bool get _showSecondarySettings {
    final status = _status;
    return status != null &&
        status != GalleryPermissionStatus.restricted &&
        status != GalleryPermissionStatus.permanentlyDenied &&
        status != GalleryPermissionStatus.granted;
  }

  IconData get _icon {
    final status = _status;
    if (status == null) return Icons.photo_library_outlined;
    switch (status) {
      case GalleryPermissionStatus.permanentlyDenied:
      case GalleryPermissionStatus.restricted:
        return Icons.lock_outline_rounded;
      case GalleryPermissionStatus.limited:
        return Icons.photo_library_outlined;
      default:
        return Icons.photo_library_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: _isChecking
              ? const LoadingWidget(message: 'Checking photo access...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(SBSpacing.xxxl),
                  child: Column(
                    children: [
                      const SizedBox(height: SBSpacing.massive),
                      Container(
                        padding: const EdgeInsets.all(SBSpacing.xxl),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(SBRadius.xxl),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(_icon, size: 64, color: AppColors.primary),
                      ),
                      const SizedBox(height: SBSpacing.xxxl),
                      Text(
                        _titleFor(_status ?? GalleryPermissionStatus.denied),
                        key: const Key('permissionTitle'),
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SBSpacing.lg),
                      Text(
                        _explain(_status ?? GalleryPermissionStatus.denied),
                        key: const Key('permissionPurpose'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SBSpacing.massive),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('permissionPrimaryButton'),
                          onPressed: _isBusy ? null : _onPrimaryPressed,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: SBSpacing.lg,
                            ),
                          ),
                          child: _isBusy
                              ? SizedBox(
                                  width: SBSizes.iconMd,
                                  height: SBSizes.iconMd,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : Text(
                                  _primaryLabel,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                        ),
                      ),
                      if (_showSecondarySettings) ...[
                        const SizedBox(height: SBSpacing.md),
                        TextButton(
                          key: const Key('permissionOpenSettings'),
                          onPressed: _isBusy ? null : _openSettingsAndRecheck,
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
