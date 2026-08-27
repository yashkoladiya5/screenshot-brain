import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedRatingFace extends StatefulWidget {
  final double rating; // 0.0 to 1.0 (0 = sad, 0.5 = neutral, 1.0 = happy)
  final double size;
  final Color baseColor;
  final ValueChanged<double>? onRatingChanged;

  const SbAnimatedRatingFace({
    super.key,
    required this.rating,
    this.size = 100.0,
    this.baseColor = Colors.amber,
    this.onRatingChanged,
  });

  @override
  State<SbAnimatedRatingFace> createState() => _SbAnimatedRatingFaceState();
}

class _SbAnimatedRatingFaceState extends State<SbAnimatedRatingFace> {
  double _currentRating = 0.5;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(SbAnimatedRatingFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating && widget.onRatingChanged == null) {
      _currentRating = widget.rating.clamp(0.0, 1.0);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.onRatingChanged == null) return;
    
    // Convert horizontal drag to rating (0.0 to 1.0)
    final double dx = details.delta.dx;
    final double sensitivity = 0.005;
    
    setState(() {
      _currentRating = (_currentRating + (dx * sensitivity)).clamp(0.0, 1.0);
    });
    
    widget.onRatingChanged!(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: widget.onRatingChanged != null ? _handlePanUpdate : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _currentRating, end: _currentRating),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, ratingVal, child) {
            // Interpolate color from Red (0) -> Yellow (0.5) -> Green (1)
            Color faceColor = widget.baseColor;
            if (widget.baseColor == Colors.amber) {
              if (ratingVal < 0.5) {
                faceColor = Color.lerp(Colors.redAccent, Colors.amber, ratingVal * 2)!;
              } else {
                faceColor = Color.lerp(Colors.amber, Colors.greenAccent, (ratingVal - 0.5) * 2)!;
              }
            }

            return CustomPaint(
              painter: _FacePainter(
                rating: ratingVal,
                color: faceColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final double rating;
  final Color color;

  _FacePainter({
    required this.rating,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Face Base
    final facePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, facePaint);

    // Inner shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1;
    canvas.drawCircle(center, radius - (radius * 0.05), shadowPaint);

    // Common style for features
    final featurePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.12;

    final fillPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    // 2. Draw Eyes
    final double eyeXOffset = radius * 0.35;
    final double eyeYOffset = radius * 0.2;
    
    final Offset leftEyePos = Offset(center.dx - eyeXOffset, center.dy - eyeYOffset);
    final Offset rightEyePos = Offset(center.dx + eyeXOffset, center.dy - eyeYOffset);
    
    final double eyeSize = radius * 0.15;

    // Eyes get slightly squeezed when very happy (squint) or very sad
    double eyeHeightMult = 1.0;
    if (rating > 0.8) eyeHeightMult = 0.5; // squint when happy
    if (rating < 0.2) eyeHeightMult = 0.7; // slightly squint when sad

    canvas.drawOval(
      Rect.fromCenter(center: leftEyePos, width: eyeSize, height: eyeSize * eyeHeightMult),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rightEyePos, width: eyeSize, height: eyeSize * eyeHeightMult),
      fillPaint,
    );

    // 3. Draw Mouth (The animated part)
    // Rating 0 = Sad (curve down)
    // Rating 0.5 = Neutral (straight)
    // Rating 1 = Happy (curve up)
    
    final path = Path();
    
    final double mouthWidth = radius * 0.5;
    final double mouthYOffset = radius * 0.25;
    
    final Offset mouthStart = Offset(center.dx - mouthWidth, center.dy + mouthYOffset);
    final Offset mouthEnd = Offset(center.dx + mouthWidth, center.dy + mouthYOffset);

    // Map rating 0..1 to control point offset -1..1
    // 0 -> -1 (curve down/sad), 0.5 -> 0 (straight/neutral), 1.0 -> 1 (curve up/happy)
    final double curveFactor = (rating - 0.5) * 2; 
    
    // The height of the curve
    final double curveHeight = radius * 0.4 * curveFactor;

    path.moveTo(mouthStart.dx, mouthStart.dy);
    
    if (curveFactor == 0) {
      path.lineTo(mouthEnd.dx, mouthEnd.dy);
    } else {
      path.quadraticBezierTo(
        center.dx, center.dy + mouthYOffset + curveHeight, // Control point
        mouthEnd.dx, mouthEnd.dy, // End point
      );
      
      // If very happy, draw open mouth
      if (rating > 0.7) {
        final openMouthFactor = (rating - 0.7) * 3.33; // map 0.7-1.0 to 0-1
        path.quadraticBezierTo(
          center.dx, center.dy + mouthYOffset + (curveHeight * (1.0 + openMouthFactor * 0.5)),
          mouthStart.dx, mouthStart.dy,
        );
        canvas.drawPath(path, fillPaint); // Fill the open mouth
      }
    }

    if (rating <= 0.7) {
      canvas.drawPath(path, featurePaint);
    }
    
    // 4. Draw eyebrows (Animated)
    final double browWidth = radius * 0.25;
    final double browYOffset = radius * 0.45;
    
    // Angle interpolates from sad (inner up) to angry/neutral (flat) to happy (outer up)
    // Map rating: 0 = 30deg, 0.5 = 0deg, 1.0 = -15deg
    double browAngle = 0.0;
    if (rating < 0.5) {
      browAngle = -math.pi / 6 * (1.0 - (rating * 2)); // Up to 30 deg inwards
    } else {
      browAngle = math.pi / 12 * ((rating - 0.5) * 2); // Up to 15 deg outwards
    }

    // Left Eyebrow
    canvas.save();
    canvas.translate(center.dx - eyeXOffset, center.dy - browYOffset);
    canvas.rotate(browAngle);
    canvas.drawLine(Offset(-browWidth/2, 0), Offset(browWidth/2, 0), featurePaint);
    canvas.restore();

    // Right Eyebrow
    canvas.save();
    canvas.translate(center.dx + eyeXOffset, center.dy - browYOffset);
    canvas.rotate(-browAngle); // Mirror rotation
    canvas.drawLine(Offset(-browWidth/2, 0), Offset(browWidth/2, 0), featurePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.rating != rating || oldDelegate.color != color;
  }
}
