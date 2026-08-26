import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbPulsingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double pulseSpread;
  final Duration duration;

  const SbPulsingButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.borderRadius = SBRadius.full,
    this.padding = const EdgeInsets.symmetric(horizontal: SBSpacing.xl, vertical: SBSpacing.md),
    this.pulseSpread = 20.0,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SbPulsingButton> createState() => _SbPulsingButtonState();
}

class _SbPulsingButtonState extends State<SbPulsingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0 + (widget.pulseSpread / 20.0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = widget.color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse Ring 1
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                    // We need to size this based on the child, so we use a trick:
                    // Paint a copy of the button layout but invisible
                    child: Padding(
                      padding: widget.padding,
                      child: Opacity(opacity: 0.0, child: widget.child),
                    ),
                  ),
                ),
              ),
              
              // Pulse Ring 2 (delayed)
              Transform.scale(
                scale: 1.0 + ((_scaleAnimation.value - 1.0) * 0.5),
                child: Opacity(
                  opacity: (_opacityAnimation.value * 1.5).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                    child: Padding(
                      padding: widget.padding,
                      child: Opacity(opacity: 0.0, child: widget.child),
                    ),
                  ),
                ),
              ),

              // Actual Button
              Container(
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Padding(
                      padding: widget.padding,
                      child: DefaultTextStyle(
                        style: theme.textTheme.labelLarge!.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
