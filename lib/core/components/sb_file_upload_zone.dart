import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';
import 'dart:math' as math;

class SbFileUploadZone extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isUploading;
  final double uploadProgress; // 0.0 to 1.0

  const SbFileUploadZone({
    super.key,
    this.title = 'Upload File',
    this.subtitle = 'Tap to select a file from your device',
    required this.onTap,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<SbFileUploadZone> createState() => _SbFileUploadZoneState();
}

class _SbFileUploadZoneState extends State<SbFileUploadZone> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isUploading) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SbFileUploadZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUploading != oldWidget.isUploading) {
      if (widget.isUploading) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: widget.isUploading ? null : () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.02);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SBSpacing.xxl),
              decoration: BoxDecoration(
                color: widget.isUploading 
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5) 
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(SBRadius.xl),
                border: Border.all(
                  color: widget.isUploading 
                      ? colorScheme.primary 
                      : colorScheme.outlineVariant,
                  width: 2.0,
                  style: BorderStyle.solid,
                ),
                boxShadow: widget.isUploading
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15 * _pulseController.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Area
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.isUploading)
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: widget.uploadProgress,
                            strokeWidth: 4,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                            color: colorScheme.primary,
                          ),
                        ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isUploading ? Icons.cloud_upload_rounded : Icons.folder_open_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SBSpacing.lg),
                  // Text Area
                  Text(
                    widget.isUploading ? 'Uploading...' : widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: SBSpacing.xs),
                  Text(
                    widget.isUploading 
                        ? '${(widget.uploadProgress * 100).toInt()}% complete'
                        : widget.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
