import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SbAnimatedSpotlightCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color baseColor;
  final Color spotlightColor;
  final double spotlightRadius;

  const SbAnimatedSpotlightCard({
    super.key,
    required this.child,
    this.width = 300.0,
    this.height = 200.0,
    this.baseColor = const Color(0xFF1E1E1E),
    this.spotlightColor = const Color(0x44FFFFFF),
    this.spotlightRadius = 150.0,
  });

  @override
  State<SbAnimatedSpotlightCard> createState() => _SbAnimatedSpotlightCardState();
}

class _SbAnimatedSpotlightCardState extends State<SbAnimatedSpotlightCard> {
  Offset _mousePosition = Offset.zero;
  bool _isHovering = false;

  void _onHover(PointerEvent details) {
    setState(() {
      _mousePosition = details.localPosition;
    });
  }

  void _onEnter(PointerEnterEvent details) {
    setState(() {
      _isHovering = true;
    });
  }

  void _onExit(PointerExitEvent details) {
    setState(() {
      _isHovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _mousePosition = details.localPosition;
            _isHovering = true;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isHovering = false;
          });
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovering ? 1.0 : 0.0,
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: _SpotlightPainter(
                    mousePosition: _mousePosition,
                    spotlightColor: widget.spotlightColor,
                    radius: widget.spotlightRadius,
                  ),
                ),
              ),
              Center(
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset mousePosition;
  final Color spotlightColor;
  final double radius;

  _SpotlightPainter({
    required this.mousePosition,
    required this.spotlightColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromCircle(center: mousePosition, radius: radius);
    
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          spotlightColor,
          spotlightColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.mousePosition != mousePosition || 
           oldDelegate.spotlightColor != spotlightColor || 
           oldDelegate.radius != radius;
  }
}
