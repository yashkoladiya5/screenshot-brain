import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbTiltCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double maxTiltAngle; // Maximum tilt angle in radians (e.g., 0.15)
  final Color shadowColor;
  
  const SbTiltCard({
    super.key,
    required this.child,
    this.width = 300.0,
    this.height = 400.0,
    this.borderRadius = SBRadius.lg,
    this.maxTiltAngle = 0.2, // ~11 degrees
    this.shadowColor = Colors.black,
  });

  @override
  State<SbTiltCard> createState() => _SbTiltCardState();
}

class _SbTiltCardState extends State<SbTiltCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _tiltOffset = Offset.zero;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Spring back duration
    );
    _controller.addListener(() {
      if (!_isHovered) {
        // Linearly interpolate back to 0,0 when not hovered
        setState(() {
          _tiltOffset = Offset.lerp(_tiltOffset, Offset.zero, _controller.value) ?? Offset.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    if (!mounted) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPosition = renderBox.globalToLocal(event.position);

    // Normalize coordinates to -1.0 to 1.0 (center is 0,0)
    final double normalizedX = (localPosition.dx / size.width) * 2 - 1;
    final double normalizedY = (localPosition.dy / size.height) * 2 - 1;

    setState(() {
      _tiltOffset = Offset(normalizedX, normalizedY);
    });
  }

  void _onEnter(PointerEnterEvent event) {
    _controller.stop();
    setState(() {
      _isHovered = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Determine current tilt values based on state
    final double tiltX = _tiltOffset.dx * widget.maxTiltAngle;
    final double tiltY = -_tiltOffset.dy * widget.maxTiltAngle; // Invert Y for natural feel

    // Calculate light reflection based on tilt
    final double lightIntensity = ((_tiltOffset.dx + _tiltOffset.dy) / 2 + 1) / 2; // 0.0 to 1.0

    return MouseRegion(
      onEnter: _onEnter,
      onHover: _onHover,
      onExit: _onExit,
      // We can also support touch devices by mapping pan gestures
      child: GestureDetector(
        onPanDown: (details) {
          _onEnter(const PointerEnterEvent());
          _onHover(PointerHoverEvent(position: details.globalPosition));
        },
        onPanUpdate: (details) {
           _onHover(PointerHoverEvent(position: details.globalPosition));
        },
        onPanEnd: (_) => _onExit(const PointerExitEvent()),
        onPanCancel: () => _onExit(const PointerExitEvent()),
        child: TweenAnimationBuilder<Offset>(
          // Smooth the immediate mouse jumps
          tween: Tween<Offset>(begin: Offset.zero, end: _tiltOffset),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          builder: (context, smoothedOffset, child) {
            
            final double sTiltX = smoothedOffset.dx * widget.maxTiltAngle;
            final double sTiltY = -smoothedOffset.dy * widget.maxTiltAngle;
            final double sLight = ((smoothedOffset.dx + smoothedOffset.dy) / 2 + 1) / 2;
            
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(sTiltY)
              ..rotateY(sTiltX);

            return Transform(
              transform: matrix,
              alignment: FractionalOffset.center,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    // Dynamic shadow that shifts opposite to the tilt direction
                    BoxShadow(
                      color: widget.shadowColor.withValues(alpha: 0.3),
                      offset: Offset(-smoothedOffset.dx * 20, -smoothedOffset.dy * 20 + 20),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // The main content
                      widget.child,
                      
                      // 3D Lighting glare effect
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: sLight * 0.4),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                // Shift the gradient based on tilt to simulate moving light
                                transform: GradientRotation(math.pi / 4 + (smoothedOffset.dx * math.pi / 4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
