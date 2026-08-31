import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbWaterRippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final int maxRipples;
  final Duration rippleDuration;

  const SbWaterRippleEffect({
    super.key,
    required this.child,
    this.rippleColor = Colors.cyanAccent,
    this.maxRipples = 5,
    this.rippleDuration = const Duration(seconds: 2),
  });

  @override
  State<SbWaterRippleEffect> createState() => _SbWaterRippleEffectState();
}

class _SbWaterRippleEffectState extends State<SbWaterRippleEffect> with TickerProviderStateMixin {
  final List<_RippleData> _ripples = [];

  void _handleTap(TapUpDetails details) {
    if (!mounted) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    final double maxRadius = math.sqrt(
      math.pow(math.max(localPosition.dx, size.width - localPosition.dx), 2) +
      math.pow(math.max(localPosition.dy, size.height - localPosition.dy), 2)
    );

    final controller = AnimationController(
      vsync: this,
      duration: widget.rippleDuration,
    );

    final ripple = _RippleData(
      position: localPosition,
      controller: controller,
      maxRadius: maxRadius,
    );

    setState(() {
      _ripples.add(ripple);
      if (_ripples.length > widget.maxRipples) {
        final oldRipple = _ripples.removeAt(0);
        oldRipple.controller.dispose();
      }
    });

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _ripples.remove(ripple);
        });
        controller.dispose();
      }
    });
  }

  @override
  void dispose() {
    for (var ripple in _ripples) {
      ripple.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var ripple in _ripples)
            AnimatedBuilder(
              animation: ripple.controller,
              builder: (context, child) {
                final double progress = Curves.easeOutCubic.transform(ripple.controller.value);
                final double opacity = 1.0 - Curves.easeInQuint.transform(ripple.controller.value);
                final double currentRadius = ripple.maxRadius * progress;

                return Positioned(
                  left: ripple.position.dx - currentRadius,
                  top: ripple.position.dy - currentRadius,
                  child: Container(
                    width: currentRadius * 2,
                    height: currentRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.rippleColor.withValues(alpha: opacity * 0.8),
                        width: 2.0,
                      ),
                      color: widget.rippleColor.withValues(alpha: opacity * 0.2),
                    ),
                  ),
                );
              },
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _RippleData {
  final Offset position;
  final AnimationController controller;
  final double maxRadius;

  _RippleData({
    required this.position,
    required this.controller,
    required this.maxRadius,
  });
}
