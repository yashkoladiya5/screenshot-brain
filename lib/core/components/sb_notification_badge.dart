import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbNotificationBadge extends StatefulWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final bool showZero;
  final Offset offset;

  const SbNotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.showZero = false,
    this.offset = const Offset(6, -6),
  });

  @override
  State<SbNotificationBadge> createState() => _SbNotificationBadgeState();
}

class _SbNotificationBadgeState extends State<SbNotificationBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(SbNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      if (widget.count > _previousCount) {
        _controller.forward(from: 0.0);
      }
      _previousCount = widget.count;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = widget.badgeColor ?? colorScheme.error;
    final fg = widget.textColor ?? colorScheme.onError;

    final bool shouldShow = widget.count > 0 || widget.showZero;
    final String displayCount = widget.count > 99 ? '99+' : widget.count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (shouldShow)
          Positioned(
            right: widget.offset.dx,
            top: widget.offset.dy,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(SBRadius.full),
                  border: Border.all(color: colorScheme.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    displayCount,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
