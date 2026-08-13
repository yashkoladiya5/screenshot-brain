import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;

  const SbLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: colorScheme.surface.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(SBSpacing.xl),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(SBRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      if (loadingText != null) ...[
                        const SizedBox(height: SBSpacing.md),
                        Text(
                          loadingText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
