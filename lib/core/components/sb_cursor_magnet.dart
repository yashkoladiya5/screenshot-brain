import 'package:flutter/material.dart';

class SbCursorMagnet extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double attractionStrength; // How far it moves toward the cursor
  final double detectionRadius; // How far away it senses the cursor

  const SbCursorMagnet({
    super.key,
    required this.child,
    required this.onPressed,
    this.attractionStrength = 20.0,
    this.detectionRadius = 100.0,
  });

  @override
  State<SbCursorMagnet> createState() => _SbCursorMagnetState();
}

class _SbCursorMagnetState extends State<SbCursorMagnet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _magneticOffset = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Spring back animation when cursor leaves
    _controller.addListener(() {
      if (!_isHovering) {
        setState(() {
          _magneticOffset = Offset.lerp(_magneticOffset, Offset.zero, _controller.value) ?? Offset.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    if (!mounted) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final localPosition = renderBox.globalToLocal(event.position);
    
    // Calculate center of the widget
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // Calculate distance from center to cursor
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;
    
    // Calculate percentage based on detection radius
    double percentX = (dx / widget.detectionRadius).clamp(-1.0, 1.0);
    double percentY = (dy / widget.detectionRadius).clamp(-1.0, 1.0);

    setState(() {
      _magneticOffset = Offset(
        percentX * widget.attractionStrength,
        percentY * widget.attractionStrength,
      );
    });
  }

  void _onEnter(PointerEnterEvent event) {
    _controller.stop();
    setState(() {
      _isHovering = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _isHovering = false;
    });
    // Trigger elastic snap back
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onHover: _onHover,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: TweenAnimationBuilder<Offset>(
          // Smooth the immediate mouse jumps
          tween: Tween<Offset>(begin: Offset.zero, end: _magneticOffset),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          builder: (context, smoothedOffset, child) {
            return Transform.translate(
              offset: smoothedOffset,
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
