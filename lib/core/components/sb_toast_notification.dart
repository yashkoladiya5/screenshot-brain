import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'dart:async';

enum SbToastType { success, error, warning, info }

class SbToastNotification extends StatefulWidget {
  final String title;
  final String? message;
  final SbToastType type;
  final Duration duration;
  final VoidCallback? onDismissed;

  const SbToastNotification({
    super.key,
    required this.title,
    this.message,
    this.type = SbToastType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismissed,
  });

  /// Helper to easily show a toast via Overlay
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    SbToastType type = SbToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SbToastNotification(
            title: title,
            message: message,
            type: type,
            duration: duration,
            onDismissed: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<SbToastNotification> createState() => _SbToastNotificationState();
}

class _SbToastNotificationState extends State<SbToastNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward().then((_) {
      _timer = Timer(widget.duration, () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onDismissed?.call();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (widget.type) {
      case SbToastType.success:
        return Colors.green.shade800;
      case SbToastType.error:
        return theme.colorScheme.error;
      case SbToastType.warning:
        return Colors.orange.shade800;
      case SbToastType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case SbToastType.success:
        return Icons.check_circle_outline_rounded;
      case SbToastType.error:
        return Icons.error_outline_rounded;
      case SbToastType.warning:
        return Icons.warning_amber_rounded;
      case SbToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _getBackgroundColor(theme);

    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(SBRadius.md),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getIcon(),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                _timer?.cancel();
                _controller.reverse().then((_) {
                  widget.onDismissed?.call();
                });
              },
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
