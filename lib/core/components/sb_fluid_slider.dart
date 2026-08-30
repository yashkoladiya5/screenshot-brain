import 'package:flutter/material.dart';

class SbFluidSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final Color trackColor;
  final Color thumbColor;

  const SbFluidSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.trackColor = Colors.grey,
    this.thumbColor = Colors.blueAccent,
  });

  @override
  State<SbFluidSlider> createState() => _SbFluidSliderState();
}

class _SbFluidSliderState extends State<SbFluidSlider> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  bool _isDragging = false;
  double _dragYOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _updateValue(double localDx, double width) {
    final double percent = (localDx / width).clamp(0.0, 1.0);
    final double newValue = widget.min + (percent * (widget.max - widget.min));
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    // Map value to 0.0 - 1.0
    final double percent = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = 40.0;

        return GestureDetector(
          onPanStart: (details) {
            setState(() {
              _isDragging = true;
              _dragYOffset = 0.0;
            });
            _updateValue(details.localPosition.dx, width);
          },
          onPanUpdate: (details) {
            setState(() {
              // Track vertical movement to stretch the fluid thumb
              _dragYOffset = (_dragYOffset + details.delta.dy).clamp(-50.0, 50.0);
            });
            _updateValue(details.localPosition.dx, width);
          },
          onPanEnd: (_) {
            setState(() {
              _isDragging = false;
            });
            // Snap back the vertical stretch
            final anim = Tween<double>(begin: _dragYOffset, end: 0.0).animate(
              CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut)
            );
            anim.addListener(() {
              setState(() {
                _dragYOffset = anim.value;
              });
            });
            _bounceController.forward(from: 0.0);
          },
          onPanCancel: () {
            setState(() {
              _isDragging = false;
              _dragYOffset = 0.0;
            });
          },
          child: SizedBox(
            width: width,
            height: height + 100, // Extra height for the elastic stretch
            child: Center(
              child: CustomPaint(
                painter: _FluidSliderPainter(
                  percent: percent,
                  isDragging: _isDragging,
                  dragYOffset: _dragYOffset,
                  trackColor: widget.trackColor,
                  thumbColor: widget.thumbColor,
                ),
                size: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FluidSliderPainter extends CustomPainter {
  final double percent;
  final bool isDragging;
  final double dragYOffset;
  final Color trackColor;
  final Color thumbColor;

  _FluidSliderPainter({
    required this.percent,
    required this.isDragging,
    required this.dragYOffset,
    required this.trackColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trackHeight = 10.0;
    final double thumbRadius = 15.0;
    final double centerX = percent * size.width;
    final double centerY = size.height / 2;
    
    // Draw base track
    final RRect trackRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, centerY), width: size.width, height: trackHeight),
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(trackRect, Paint()..color = trackColor.withValues(alpha: 0.3));
    
    // Draw filled track
    final RRect filledTrackRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, centerY - (trackHeight / 2), centerX, centerY + (trackHeight / 2)),
      Radius.circular(trackHeight / 2),
    );
    canvas.drawRRect(filledTrackRect, Paint()..color = thumbColor);

    // Draw the fluid thumb
    final Paint thumbPaint = Paint()..color = thumbColor;
    
    if (isDragging && dragYOffset != 0) {
      // The thumb is being dragged vertically, draw a liquid droplet connecting to the track
      final Path path = Path();
      
      // Calculate drop position
      final double dropY = centerY + dragYOffset;
      final double controlY = centerY + (dragYOffset * 0.5); // Midway point for bezier
      
      // Base of the droplet on the track
      path.moveTo(centerX - thumbRadius, centerY);
      
      // Curve down to the droplet point
      path.quadraticBezierTo(
        centerX - (thumbRadius * 0.5), controlY, // Control point
        centerX - (thumbRadius * 0.8), dropY     // End point (left side of drop)
      );
      
      // Bottom rounded part of the droplet
      path.arcToPoint(
        Offset(centerX + (thumbRadius * 0.8), dropY),
        radius: Radius.circular(thumbRadius),
        clockwise: dragYOffset > 0 ? false : true,
      );
      
      // Curve back up to the track
      path.quadraticBezierTo(
        centerX + (thumbRadius * 0.5), controlY, // Control point
        centerX + thumbRadius, centerY           // End point
      );
      
      canvas.drawPath(path, thumbPaint);
      
      // Also draw the actual thumb circle at the drop point
      canvas.drawCircle(Offset(centerX, dropY), thumbRadius, thumbPaint);
      
    } else {
      // Standard circular thumb
      canvas.drawCircle(Offset(centerX, centerY), thumbRadius, thumbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FluidSliderPainter oldDelegate) {
    return oldDelegate.percent != percent ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.dragYOffset != dragYOffset ||
           oldDelegate.thumbColor != thumbColor;
  }
}
