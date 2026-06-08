import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/permission_service.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/app_colors.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with SingleTickerProviderStateMixin {
  bool _isRequesting = false;
  bool _isPermanentlyDenied = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    final hasPermission = await PermissionService.hasGalleryPermission();
    if (!mounted) return;
    if (hasPermission) {
      context.go('/home');
      return;
    }
    // Check if permanently denied without requesting
    final photosStatus = await Permission.photos.status;
    if (!mounted) return;
    if (photosStatus.isPermanentlyDenied) {
      setState(() => _isPermanentlyDenied = true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final granted = await PermissionService.requestGalleryPermission();
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _isPermanentlyDenied = !granted;
    });
    if (granted) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPermanentlyDenied
                ? 'Permission permanently denied. Please enable from Settings.'
                : 'Permission denied. Please grant access in settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => PermissionService.openSettings(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.all(SBSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(SBSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SBRadius.xxl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    _isPermanentlyDenied ? Icons.lock_outline_rounded : Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: SBSpacing.xxxl),
                Text(
                  _isPermanentlyDenied ? 'Permission Required' : 'Access Your Screenshots',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SBSpacing.lg),
                Text(
                  _isPermanentlyDenied
                      ? 'Gallery permission was permanently denied. Tap "Open Settings" to enable it manually.'
                      : 'Screenshot Brain needs access to your photo gallery to scan and organize your screenshots. All processing happens on your device.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SBSpacing.massive),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isRequesting ? null : _requestPermission,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: SBSpacing.lg),
                    ),
                    child: _isRequesting
                        ? SizedBox(
                            width: SBSizes.iconMd,
                            height: SBSizes.iconMd,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            _isPermanentlyDenied ? 'Grant Permission' : 'Grant Permission',
                            style: theme.textTheme.titleSmall?.copyWith(color: AppColors.onPrimary),
                          ),
                  ),
                ),
                const SizedBox(height: SBSpacing.md),
                TextButton(
                  onPressed: () => PermissionService.openSettings(),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
