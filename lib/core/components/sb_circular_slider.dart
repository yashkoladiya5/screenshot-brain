import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/tokens.dart';

class SbCircularSlider extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final double radius;
  final double strokeWidth;
  final Color? activeColor;
  final Color? inactiveColor;
  final Widget? child;

  const SbCircularSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.radius = 100.0,
    this.strokeWidth = 15.0,
    this.activeColor,
    this.inactiveColor,
    this.child,
  });

  @override
  State<SbCircularSlider> createState() => _SbCircularSliderState();
}

class _SbCircularSliderState extends State<SbCircularSlider> {
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(SbCircularSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _currentValue) {
      _currentValue = widget.value.clamp(0.0, 1.0);
    }
  }

  void _handlePan(Offset localPosition, Size size) {
    // Calculate angle from center
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    
    // math.atan2 returns angle from -pi to pi.
    // We want 0 at the top (which is -pi/2 in standard cartesian, assuming Y grows down)
    double angle = math.atan2(dy, dx);
    
    // Shift so 0 is at top (-pi/2)
    angle += math.pi / 2;
    
    // Normalize to 0 -> 2pi
    if (angle < 0) {
      angle += 2 * math.pi;
    }
    
    // Convert angle to percentage 0.0 -> 1.0
    double percentage = angle / (2 * math.pi);
    
    setState(() {
      _currentValue = percentage;
    });
    
    widget.onChanged(percentage);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.activeColor ?? theme.colorScheme.primary;
    final inactive = widget.inactiveColor ?? theme.colorScheme.surfaceContainerHighest;

    final double size = widget.radius * 2;

    return GestureDetector(
      onPanDown: (details) => _handlePan(details.localPosition, Size(size, size)),
      onPanUpdate: (details) => _handlePan(details.localPosition, Size(size, size)),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background & Track painter
            CustomPaint(
              size: Size(size, size),
              painter: _CircularSliderPainter(
                value: _currentValue,
                strokeWidth: widget.strokeWidth,
                activeColor: active,
                inactiveColor: inactive,
              ),
            ),
            
            // Thumb
            _buildThumb(size, active),
            
            // Child (usually text showing percentage)
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
  
  Widget _buildThumb(double size, Color activeColor) {
    // Angle in radians (0 at top, clockwise)
    final double angle = _currentValue * 2 * math.pi - (math.pi / 2);
    
    // The radius where the center of the thumb should sit
    final double trackRadius = widget.radius - (widget.strokeWidth / 2);
    
    final double dx = math.cos(angle) * trackRadius;
    final double dy = math.sin(angle) * trackRadius;
    
    final double thumbRadius = widget.strokeWidth * 0.8;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: thumbRadius * 2,
        height: thumbRadius * 2,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }
}

class _CircularSliderPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  _CircularSliderPainter({
    required this.value,
    required this.strokeWidth,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);

    // Draw inactive track (full circle)
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius, inactivePaint);

    // Draw active track (arc)
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start angle: -pi/2 (Top)
    // Sweep angle: value * 2pi
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      value * 2 * math.pi,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
