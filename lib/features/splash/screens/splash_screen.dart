import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/permission_service.dart';
import '../../../core/design/tokens.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
    _navigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final hasPermission = await PermissionService.hasGalleryPermission();
    if (!mounted) return;
    if (hasPermission) {
      context.go('/home');
    } else {
      context.go('/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SBRadius.xxl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: SBSpacing.xxl),
                Text(
                  'Screenshot Brain',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: SBSpacing.sm),
                Text(
                  'Your intelligent screenshot assistant',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: SBSpacing.massive),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
