import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbNeonButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color neonColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isPulsing;

  const SbNeonButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.neonColor = Colors.cyanAccent,
    this.borderRadius = SBRadius.md,
    this.padding = const EdgeInsets.symmetric(horizontal: SBSpacing.xl, vertical: SBSpacing.md),
    this.isPulsing = true,
  });

  @override
  State<SbNeonButton> createState() => _SbNeonButtonState();
}

class _SbNeonButtonState extends State<SbNeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(SbNeonButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.6;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = _isPressed 
            ? 1.5 
            : (_isHovered ? 1.2 : _glowAnimation.value);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: Colors.transparent, // Neon is usually hollow or dark inside
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.neonColor.withValues(alpha: 0.8),
                  width: 2.0,
                ),
                boxShadow: [
                  // Outer Glow
                  BoxShadow(
                    color: widget.neonColor.withValues(alpha: 0.4 * glowIntensity),
                    blurRadius: 15.0 * glowIntensity,
                    spreadRadius: 2.0 * glowIntensity,
                  ),
                  BoxShadow(
                    color: widget.neonColor.withValues(alpha: 0.2 * glowIntensity),
                    blurRadius: 30.0 * glowIntensity,
                    spreadRadius: 5.0 * glowIntensity,
                  ),
                  // Inner Glow
                  BoxShadow(
                    color: widget.neonColor.withValues(alpha: 0.3 * glowIntensity),
                    blurRadius: 10.0,
                    inset: true,
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: widget.neonColor, // Match text to neon color
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: widget.neonColor.withValues(alpha: 0.8),
                      blurRadius: 8.0,
                    )
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper extension to add inset to BoxShadow which Flutter lacks by default for inner shadows
extension _InnerShadow on BoxShadow {
  BoxShadow copyWith({
    Color? color,
    Offset? offset,
    double? blurRadius,
    double? spreadRadius,
    BlurStyle? blurStyle,
    bool? inset,
  }) {
    // Note: True inner shadow requires CustomPainter, but for the neon effect
    // a tight blur with no offset simulates it well enough inside a bordered box
    return BoxShadow(
      color: color ?? this.color,
      offset: offset ?? this.offset,
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
      blurStyle: inset == true ? BlurStyle.inner : (blurStyle ?? this.blurStyle),
    );
  }
}
