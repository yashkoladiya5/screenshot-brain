import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbGlowCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color baseColor;
  final Color glowColor;
  final double borderRadius;

  const SbGlowCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = 200.0,
    this.baseColor = const Color(0xFF1E1E1E),
    this.glowColor = Colors.cyanAccent,
    this.borderRadius = SBRadius.lg,
  });

  @override
  State<SbGlowCard> createState() => _SbGlowCardState();
}

class _SbGlowCardState extends State<SbGlowCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _mousePosition = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    // Continuous idle animation for the ambient border glow
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    if (!mounted) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);
    
    setState(() {
      _mousePosition = localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onHover: _onHover,
      onExit: (_) => setState(() => _isHovering = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. The animating gradient border (Back layer)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius + 2), // Slightly larger to form a border
                    gradient: SweepGradient(
                      center: Alignment.center,
                      startAngle: 0.0,
                      endAngle: math.pi * 2,
                      colors: [
                        widget.glowColor.withValues(alpha: 0.1),
                        widget.glowColor,
                        widget.glowColor.withValues(alpha: 0.1),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: GradientRotation(_controller.value * math.pi * 2), // Rotate the gradient
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                );
              },
            ),

            // 2. The main physical card (Middle layer, slightly smaller to reveal border)
            Padding(
              padding: const EdgeInsets.all(2.0), // Thickness of the glowing border
              child: Container(
                decoration: BoxDecoration(
                  color: widget.baseColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                clipBehavior: Clip.antiAlias, // So the inner glow doesn't bleed out
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 3. The interactive cursor tracking radial glow (Inner layer)
                    if (_isHovering)
                      Positioned(
                        left: _mousePosition.dx - 150, // Center the radial gradient on cursor
                        top: _mousePosition.dy - 150,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                widget.glowColor.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                    // 4. The actual content (Top layer)
                    widget.child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
