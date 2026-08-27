import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class SbRipple {
  final Offset position;
  double radius = 0.0;
  double opacity = 1.0;
  bool isDead = false;

  SbRipple(this.position);

  void update(double maxRadius) {
    // Expand radius quickly
    radius += 4.0;
    
    // Fade out as it expands
    opacity = (1.0 - (radius / maxRadius)).clamp(0.0, 1.0);
    
    if (radius >= maxRadius) {
      isDead = true;
    }
  }
}

class SbRippleBackground extends StatefulWidget {
  final Widget? child;
  final Color rippleColor;
  final double maxRadius;
  final Color? backgroundColor;
  final bool autoRipples;

  const SbRippleBackground({
    super.key,
    this.child,
    this.rippleColor = const Color(0x44FFFFFF),
    this.maxRadius = 150.0,
    this.backgroundColor,
    this.autoRipples = false,
  });

  @override
  State<SbRippleBackground> createState() => _SbRippleBackgroundState();
}

class _SbRippleBackgroundState extends State<SbRippleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SbRipple> _ripples = [];
  final math.Random _random = math.Random();
  Size _currentSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        _updateRipples();
      });
      
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateRipples() {
    setState(() {
      for (var ripple in _ripples) {
        ripple.update(widget.maxRadius);
      }
      _ripples.removeWhere((r) => r.isDead);
      
      // Optionally spawn random background ripples
      if (widget.autoRipples && _currentSize != Size.zero) {
        if (_random.nextDouble() < 0.02) { // 2% chance per frame
          _addRipple(Offset(
            _random.nextDouble() * _currentSize.width,
            _random.nextDouble() * _currentSize.height,
          ));
        }
      }
    });
  }

  void _addRipple(Offset position) {
    setState(() {
      _ripples.add(SbRipple(position));
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _currentSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return GestureDetector(
          onTapDown: (details) => _addRipple(details.localPosition),
          onPanUpdate: (details) {
            // Only spawn ripples every so often while dragging to prevent too many objects
            if (_ripples.isEmpty || _ripples.last.radius > 20) {
              _addRipple(details.localPosition);
            }
          },
          child: Container(
            color: widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  size: _currentSize,
                  painter: _RipplePainter(
                    ripples: _ripples,
                    color: widget.rippleColor,
                  ),
                ),
                if (widget.child != null) widget.child!,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final List<SbRipple> ripples;
  final Color color;

  _RipplePainter({
    required this.ripples,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var ripple in ripples) {
      if (ripple.opacity > 0) {
        final paint = Paint()
          ..color = color.withValues(alpha: color.a * ripple.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
          
        canvas.drawCircle(ripple.position, ripple.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true; // Constant animation
}
