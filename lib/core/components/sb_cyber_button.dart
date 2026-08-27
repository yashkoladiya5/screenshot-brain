import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCyberButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color secondaryColor;

  const SbCyberButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primaryColor = Colors.cyanAccent,
    this.secondaryColor = Colors.pinkAccent,
  });

  @override
  State<SbCyberButton> createState() => _SbCyberButtonState();
}

class _SbCyberButtonState extends State<SbCyberButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
          child: CustomPaint(
            painter: _CyberPainter(
              animation: _controller,
              isHovered: _isHovered,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              child: Text(
                widget.text.toUpperCase(),
                style: TextStyle(
                  color: _isHovered ? Colors.black : widget.primaryColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  fontSize: 16,
                  shadows: _isHovered ? [] : [
                    Shadow(
                      color: widget.primaryColor,
                      blurRadius: 10,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isHovered;
  final Color primaryColor;
  final Color secondaryColor;

  _CyberPainter({
    required this.animation,
    required this.isHovered,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    final double chamfer = 15.0;

    // Draw cyberpunk chamfered box
    path.moveTo(0, chamfer);
    path.lineTo(chamfer, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - chamfer);
    path.lineTo(size.width - chamfer, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Fill logic
    if (isHovered) {
      canvas.drawPath(
        path, 
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.fill
      );
    } else {
      // Stroke
      canvas.drawPath(
        path,
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
      );
    }
    
    // Draw animated scanning line
    if (!isHovered) {
      final double scanY = (animation.value * size.height * 2) - size.height; // Loop from -height to +height
      
      canvas.save();
      canvas.clipPath(path);
      canvas.drawLine(
        Offset(0, scanY),
        Offset(size.width, scanY),
        Paint()
          ..color = secondaryColor.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CyberPainter oldDelegate) => true;
}
