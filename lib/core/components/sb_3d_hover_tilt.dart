import 'package:flutter/material.dart';

class Sb3DHoverTilt extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double maxTilt;

  const Sb3DHoverTilt({
    super.key,
    required this.child,
    this.width = 300,
    this.height = 400,
    this.maxTilt = 0.2, 
  });

  @override
  State<Sb3DHoverTilt> createState() => _Sb3DHoverTiltState();
}

class _Sb3DHoverTiltState extends State<Sb3DHoverTilt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(() {
      setState(() {
        _tilt = Offset.lerp(_tilt, Offset.zero, _controller.value) ?? Offset.zero;
      });
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
    
    final double normalizedX = (localPosition.dx / size.width) * 2 - 1;
    final double normalizedY = (localPosition.dy / size.height) * 2 - 1;
    
    setState(() {
      _tilt = Offset(
        -normalizedY * widget.maxTilt,
        normalizedX * widget.maxTilt,
      );
    });
  }

  void _onEnter(PointerEnterEvent event) {
    _controller.stop();
  }

  void _onExit(PointerExitEvent event) {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onHover: _onHover,
      onExit: _onExit,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: Offset.zero, end: _tilt),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        builder: (context, currentTilt, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) 
              ..rotateX(currentTilt.dx)
              ..rotateY(currentTilt.dy),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: Offset(-currentTilt.dy * 40, currentTilt.dx * 40 + 10),
                  )
                ]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
