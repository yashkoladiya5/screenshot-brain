import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedRotarySlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double radius;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  const SbAnimatedRotarySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.radius = 100.0,
    this.strokeWidth = 15.0,
    this.activeColor = Colors.deepPurpleAccent,
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  State<SbAnimatedRotarySlider> createState() => _SbAnimatedRotarySliderState();
}

class _SbAnimatedRotarySliderState extends State<SbAnimatedRotarySlider> {
  static const double _startAngle = -math.pi / 2;

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    final Offset position = details.localPosition;
    
    double angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    
    angle = angle - _startAngle;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    final double percentage = angle / (2 * math.pi);
    
    final double valueRange = widget.max - widget.min;
    final double newValue = widget.min + (percentage * valueRange);
    
    widget.onChanged(newValue.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final double percentage = (widget.value - widget.min) / (widget.max - widget.min);
    
    final double currentAngle = _startAngle + (percentage * 2 * math.pi);
    final double thumbX = widget.radius + (widget.radius * math.cos(currentAngle));
    final double thumbY = widget.radius + (widget.radius * math.sin(currentAngle));
    
    final double diameter = widget.radius * 2;

    return GestureDetector(
      onPanUpdate: (details) => _onPanUpdate(details, Offset(widget.radius, widget.radius)),
      child: SizedBox(
        width: diameter + widget.strokeWidth * 2,
        height: diameter + widget.strokeWidth * 2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(diameter, diameter),
              painter: _RotarySliderPainter(
                percentage: percentage,
                strokeWidth: widget.strokeWidth,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
              ),
            ),
            
            Positioned(
              left: thumbX,
              top: thumbY,
              child: Container(
                width: widget.strokeWidth * 2,
                height: widget.strokeWidth * 2,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    )
                  ],
                  border: Border.all(
                    color: widget.activeColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            
            Center(
              child: Text(
                '${widget.value.toInt()}',
                style: TextStyle(
                  fontSize: widget.radius * 0.4,
                  fontWeight: FontWeight.bold,
                  color: widget.activeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RotarySliderPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  _RotarySliderPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    canvas.drawCircle(center, radius, inactivePaint);

    final Paint activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = percentage * 2 * math.pi;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 
      sweepAngle,   
      false,        
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RotarySliderPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}
