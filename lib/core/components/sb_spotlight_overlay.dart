import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SbSpotlightOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey targetKey;
  final double spotlightRadius;
  final Color overlayColor;
  final VoidCallback? onDismiss;
  final bool animateIn;

  const SbSpotlightOverlay({
    super.key,
    required this.child,
    required this.targetKey,
    this.spotlightRadius = 60.0,
    this.overlayColor = const Color(0x99000000),
    this.onDismiss,
    this.animateIn = true,
  });

  @override
  State<SbSpotlightOverlay> createState() => _SbSpotlightOverlayState();
}

class _SbSpotlightOverlayState extends State<SbSpotlightOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _targetCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTarget();
      if (widget.animateIn) {
        _controller.forward();
      } else {
        _controller.value = 1.0;
      }
    });
  }

  void _calculateTarget() {
    final RenderBox? renderBox = widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _targetCenter = Offset(position.dx + size.width / 2, position.dy + size.height / 2);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetCenter == Offset.zero) {
      return widget.child; // Fallback before frame renders
    }

    return Stack(
      children: [
        // 1. The actual screen content underneath
        widget.child,
        
        // 2. The Spotlight Overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Animate the radius from a massive size (covering screen) down to the target radius
                // Use easeOutBack to give it a little bounce when it lands
                final CurvedAnimation curve = CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutBack,
                );
                
                final double screenMaxDim = MediaQuery.of(context).size.longestSide;
                
                // Start big (no spotlight visible), animate down to target size
                final double currentRadius = ui.lerpDouble(
                  screenMaxDim * 1.5, 
                  widget.spotlightRadius, 
                  curve.value
                )!;
                
                // Animate opacity of the dark overlay
                final Color currentColor = widget.overlayColor.withValues(
                  alpha: widget.overlayColor.a * curve.value.clamp(0.0, 1.0),
                );

                return CustomPaint(
                  painter: _SpotlightPainter(
                    center: _targetCenter,
                    radius: currentRadius,
                    overlayColor: currentColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color overlayColor;

  _SpotlightPainter({
    required this.center,
    required this.radius,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We use Path.combine to subtract a circle from a full screen rectangle
    
    // 1. The full screen dark overlay
    final Path overlayPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // 2. The spotlight hole
    final Path spotlightPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    
    // 3. Subtract the hole from the overlay
    final Path finalPath = Path.combine(PathOperation.difference, overlayPath, spotlightPath);
    
    // Draw it
    canvas.drawPath(finalPath, Paint()..color = overlayColor);
    
    // Add a soft glowing rim around the spotlight hole
    canvas.drawCircle(
      center, 
      radius, 
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.center != center || 
           oldDelegate.radius != radius || 
           oldDelegate.overlayColor != overlayColor;
  }
}
