import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbFilePickerButton extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isUploading;

  const SbFilePickerButton({
    super.key,
    this.label = 'Select a file',
    this.description = 'Tap to browse your device',
    this.icon = Icons.cloud_upload_outlined,
    required this.onTap,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(SBRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SBSpacing.xl),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(SBRadius.md),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid, // Note: Flutter doesn't natively support dashed borders without custom painters.
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isUploading)
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            else
              Container(
                padding: const EdgeInsets.all(SBSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: colorScheme.primary),
              ),
            const SizedBox(height: SBSpacing.lg),
            Text(
              isUploading ? 'Uploading...' : label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            if (description != null && !isUploading) ...[
              const SizedBox(height: SBSpacing.xs),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
