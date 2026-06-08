import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;
  bool _isPermanentlyDenied = false;

  Future<void> _requestPermission() async {
    debugPrint('[PermissionScreen] _requestPermission() called');
    setState(() => _isRequesting = true);
    final granted = await PermissionService.requestGalleryPermission();
    debugPrint('[PermissionScreen] permission result: granted=$granted');
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _isPermanentlyDenied = !granted;
    });
    if (granted) {
      debugPrint('[PermissionScreen] navigating to /home');
      context.go('/home');
    } else {
      debugPrint('[PermissionScreen] permission not granted, showing snackbar');
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
    debugPrint('[PermissionScreen] build() - _isPermanentlyDenied=$_isPermanentlyDenied');
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _isPermanentlyDenied ? Icons.lock_outline : Icons.photo_library_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isPermanentlyDenied ? 'Permission Required' : 'Access Your Screenshots',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isPermanentlyDenied
                    ? 'Gallery permission was permanently denied. Please tap "Open Settings" to enable it manually.'
                    : 'Screenshot Brain needs access to your photo gallery to scan and organize your screenshots. All processing happens on your device.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isRequesting ? null : _requestPermission,
                  child: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isPermanentlyDenied ? 'Try Again' : 'Grant Permission'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  debugPrint('[PermissionScreen] opening app settings');
                  PermissionService.openSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
