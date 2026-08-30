import 'package:flutter/material.dart';

class SbParallaxBackground extends StatefulWidget {
  final Widget background; // The distant layer (moves slowest)
  final Widget middleground; // The mid layer
  final Widget foreground; // The close layer (moves fastest, usually where content goes)
  
  // How much each layer should move in response to a pointer pan
  final double bgParallaxFactor;
  final double mgParallaxFactor;
  final double fgParallaxFactor;

  const SbParallaxBackground({
    super.key,
    required this.background,
    required this.middleground,
    required this.foreground,
    this.bgParallaxFactor = 0.2, // Moves least
    this.mgParallaxFactor = 0.5,
    this.fgParallaxFactor = 1.0, // Moves most
  });

  @override
  State<SbParallaxBackground> createState() => _SbParallaxBackgroundState();
}

class _SbParallaxBackgroundState extends State<SbParallaxBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _pointerOffset = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Spring back duration
    );

    _controller.addListener(() {
      if (!_isHovering) {
        setState(() {
          _pointerOffset = Offset.lerp(_pointerOffset, Offset.zero, _controller.value) ?? Offset.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset globalPosition, Size screenSize) {
    if (!mounted) return;
    
    // Normalize coordinates to -1.0 to 1.0 based on screen size, where 0,0 is center
    final double normalizedX = (globalPosition.dx / screenSize.width) * 2 - 1;
    final double normalizedY = (globalPosition.dy / screenSize.height) * 2 - 1;

    setState(() {
      _pointerOffset = Offset(normalizedX, normalizedY);
    });
  }

  void _onPointerEnter() {
    _controller.stop();
    setState(() {
      _isHovering = true;
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovering = false;
    });
    // Trigger spring back to center
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    
    // We need to scale the layers up slightly so that when they pan, we don't see the edges of the screen
    // We calculate a safe scale factor based on the maximum parallax translation
    const double maxTranslation = 50.0; // Assume max 50 pixels of translation
    final double scaleFactor = 1.0 + (maxTranslation * 2 / screenSize.longestSide);

    return MouseRegion(
      onEnter: (_) => _onPointerEnter(),
      onHover: (event) => _onPointerMove(event.position, screenSize),
      onExit: (_) => _onPointerExit(),
      child: GestureDetector(
        onPanDown: (details) {
          _onPointerEnter();
          _onPointerMove(details.globalPosition, screenSize);
        },
        onPanUpdate: (details) {
          _onPointerMove(details.globalPosition, screenSize);
        },
        onPanEnd: (_) => _onPointerExit(),
        onPanCancel: () => _onPointerExit(),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background (Slowest moving)
              Transform.translate(
                offset: Offset(
                  -_pointerOffset.dx * maxTranslation * widget.bgParallaxFactor,
                  -_pointerOffset.dy * maxTranslation * widget.bgParallaxFactor,
                ),
                child: Transform.scale(
                  scale: scaleFactor,
                  child: widget.background,
                ),
              ),
              
              // 2. Middleground
              Transform.translate(
                offset: Offset(
                  -_pointerOffset.dx * maxTranslation * widget.mgParallaxFactor,
                  -_pointerOffset.dy * maxTranslation * widget.mgParallaxFactor,
                ),
                child: Transform.scale(
                  scale: scaleFactor,
                  child: widget.middleground,
                ),
              ),

              // 3. Foreground (Fastest moving, appears closest to user)
              Transform.translate(
                offset: Offset(
                  -_pointerOffset.dx * maxTranslation * widget.fgParallaxFactor,
                  -_pointerOffset.dy * maxTranslation * widget.fgParallaxFactor,
                ),
                child: Transform.scale(
                  scale: scaleFactor,
                  child: widget.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
