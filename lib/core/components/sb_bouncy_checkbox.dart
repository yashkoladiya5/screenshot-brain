import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBouncyCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color activeColor;
  final Color checkColor;
  final Color inactiveColor;

  const SbBouncyCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 28.0,
    this.activeColor = Colors.blueAccent,
    this.checkColor = Colors.white,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<SbBouncyCheckbox> createState() => _SbBouncyCheckboxState();
}

class _SbBouncyCheckboxState extends State<SbBouncyCheckbox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Bouncy scale effect when checked
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Reveal checkmark
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack)),
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SbBouncyCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final isChecked = _controller.value > 0.3;
            
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: isChecked ? widget.activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(SBRadius.sm),
                  border: Border.all(
                    color: isChecked ? widget.activeColor : (_isHovered ? widget.activeColor : widget.inactiveColor),
                    width: 2.0,
                  ),
                  boxShadow: isChecked ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ] : null,
                ),
                child: CustomPaint(
                  painter: _CheckmarkPainter(
                    progress: _checkAnimation.value,
                    color: widget.checkColor,
                    strokeWidth: widget.size * 0.12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    
    // Checkmark coordinates (relative to size)
    final Offset p1 = Offset(size.width * 0.25, size.height * 0.5);
    final Offset p2 = Offset(size.width * 0.45, size.height * 0.7);
    final Offset p3 = Offset(size.width * 0.75, size.height * 0.3);

    // Draw the checkmark progressively based on the animation
    path.moveTo(p1.dx, p1.dy);

    if (progress < 0.5) {
      // Draw first segment (down stroke)
      final t = progress * 2; // Normalize to 0-1 for this segment
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      // Draw first segment full
      path.lineTo(p2.dx, p2.dy);
      // Draw second segment (up stroke)
      final t = (progress - 0.5) * 2; // Normalize to 0-1 for this segment
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
