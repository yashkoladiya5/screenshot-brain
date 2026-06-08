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

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final granted = await PermissionService.requestGalleryPermission();
    if (!mounted) return;
    setState(() => _isRequesting = false);
    if (granted) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Please grant access in settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Icons.photo_library_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Access Your Screenshots',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Screenshot Brain needs access to your photo gallery to scan and organize your screenshots. All processing happens on your device.',
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
                      : const Text('Grant Permission'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
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
