import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTicketView extends StatelessWidget {
  final Widget topContent;
  final Widget bottomContent;
  final Color? backgroundColor;
  final double punchRadius;
  final double dashWidth;
  final double dashSpace;

  const SbTicketView({
    super.key,
    required this.topContent,
    required this.bottomContent,
    this.backgroundColor,
    this.punchRadius = 12.0,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Section
        ClipPath(
          clipper: _TicketTopClipper(punchRadius: punchRadius),
          child: Container(
            width: double.infinity,
            color: bgColor,
            child: topContent,
          ),
        ),
        
        // Divider Section
        Container(
          height: punchRadius * 2,
          color: bgColor,
          child: Stack(
            children: [
              // Left Punch Hole (Half circle)
              Positioned(
                left: -punchRadius,
                top: 0,
                bottom: 0,
                child: Container(
                  width: punchRadius * 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Right Punch Hole (Half circle)
              Positioned(
                right: -punchRadius,
                top: 0,
                bottom: 0,
                child: Container(
                  width: punchRadius * 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Dashed Line
              Positioned.fill(
                left: punchRadius,
                right: punchRadius,
                child: CustomPaint(
                  painter: _DashedLinePainter(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    dashWidth: dashWidth,
                    dashSpace: dashSpace,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bottom Section
        ClipPath(
          clipper: _TicketBottomClipper(punchRadius: punchRadius),
          child: Container(
            width: double.infinity,
            color: bgColor,
            child: bottomContent,
          ),
        ),
      ],
    );
  }
}

class _TicketTopClipper extends CustomClipper<Path> {
  final double punchRadius;

  _TicketTopClipper({required this.punchRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    // Draw inverted arc on bottom left
    path.arcToPoint(
      Offset(punchRadius, size.height - punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: true,
    );
    path.lineTo(size.width - punchRadius, size.height - punchRadius);
    // Draw inverted arc on bottom right
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(punchRadius),
      clockwise: true,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketTopClipper oldClipper) {
    return oldClipper.punchRadius != punchRadius;
  }
}

class _TicketBottomClipper extends CustomClipper<Path> {
  final double punchRadius;

  _TicketBottomClipper({required this.punchRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    // Draw inverted arc on top left
    path.arcToPoint(
      Offset(punchRadius, punchRadius),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    path.lineTo(size.width - punchRadius, punchRadius);
    // Draw inverted arc on top right
    path.arcToPoint(
      Offset(size.width, 0),
      radius: Radius.circular(punchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TicketBottomClipper oldClipper) {
    return oldClipper.punchRadius != punchRadius;
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  _DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.dashWidth != dashWidth ||
           oldDelegate.dashSpace != dashSpace;
  }
}
