import 'package:flutter/material.dart';

class SbElasticSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final Color activeColor;
  final Color inactiveColor;

  const SbElasticSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.activeColor = Colors.blueAccent,
    this.inactiveColor = Colors.black12,
  });

  @override
  State<SbElasticSlider> createState() => _SbElasticSliderState();
}

class _SbElasticSliderState extends State<SbElasticSlider> with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  
  double _dragYOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _springController.addListener(() {
      setState(() {
        _dragYOffset = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragYOffset = 0.0;
    });
    _springController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    // Calculate new value based on X movement
    final double dx = details.delta.dx;
    final double valueRange = widget.max - widget.min;
    final double valuePerPixel = valueRange / maxWidth;
    
    double newValue = widget.value + (dx * valuePerPixel);
    newValue = newValue.clamp(widget.min, widget.max);
    
    // Calculate Y stretching (rubber band effect)
    // The faster/harder you pull up or down, the more the line bends
    setState(() {
      // Add Y delta to offset, but dampen it so it doesn't stretch infinitely
      _dragYOffset += details.delta.dy * 0.5;
      // Clamp the stretch to max 40 pixels up or down
      _dragYOffset = _dragYOffset.clamp(-40.0, 40.0);
    });
    
    if (newValue != widget.value) {
      widget.onChanged(newValue);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    
    // Snap back to zero Y offset with an elastic bounce
    _springAnimation = Tween<double>(begin: _dragYOffset, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut)
    );
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);
        final double thumbX = width * normalizedValue;

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: (details) => _onPanUpdate(details, width),
          onPanEnd: _onPanEnd,
          child: Container(
            color: Colors.transparent, // Expand hit area
            height: 100, // Fixed height to allow for vertical stretching
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The elastic line
                CustomPaint(
                  size: Size(width, 100),
                  painter: _ElasticLinePainter(
                    thumbX: thumbX,
                    thumbYOffset: _dragYOffset,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                  ),
                ),
                
                // The Thumb
                Positioned(
                  left: thumbX - 12, // 12 is half of thumb width (24)
                  top: 50 + _dragYOffset - 12, // 50 is center of the 100 height container
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: _isDragging ? 4 : 1,
                        )
                      ],
                      border: Border.all(
                        color: widget.activeColor,
                        width: 3,
                      )
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ElasticLinePainter extends CustomPainter {
  final double thumbX;
  final double thumbYOffset;
  final Color activeColor;
  final Color inactiveColor;

  _ElasticLinePainter({
    required this.thumbX,
    required this.thumbYOffset,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    // Active track (left side)
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePath = Path();
    activePath.moveTo(0, centerY);
    
    // Draw bezier curve to the thumb position
    if (thumbYOffset != 0) {
      activePath.quadraticBezierTo(
        thumbX / 2, centerY, // Control point
        thumbX, centerY + thumbYOffset // End point (thumb)
      );
    } else {
      activePath.lineTo(thumbX, centerY);
    }
    canvas.drawPath(activePath, activePaint);

    // Inactive track (right side)
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final inactivePath = Path();
    inactivePath.moveTo(thumbX, centerY + thumbYOffset);
    
    if (thumbYOffset != 0) {
      inactivePath.quadraticBezierTo(
        thumbX + (size.width - thumbX) / 2, centerY, // Control point
        size.width, centerY // End point
      );
    } else {
      inactivePath.lineTo(size.width, centerY);
    }
    canvas.drawPath(inactivePath, inactivePaint);
  }

  @override
  bool shouldRepaint(covariant _ElasticLinePainter oldDelegate) {
    return oldDelegate.thumbX != thumbX || oldDelegate.thumbYOffset != thumbYOffset;
  }
}
