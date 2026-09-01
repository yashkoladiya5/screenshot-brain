import 'package:flutter/material.dart';

class SbTiltParallaxCard extends StatefulWidget {
  final Widget background;
  final Widget foreground;
  final double width;
  final double height;
  final double maxTilt;

  const SbTiltParallaxCard({
    super.key,
    required this.background,
    required this.foreground,
    this.width = 300.0,
    this.height = 400.0,
    this.maxTilt = 0.2, // Radians
  });

  @override
  State<SbTiltParallaxCard> createState() => _SbTiltParallaxCardState();
}

class _SbTiltParallaxCardState extends State<SbTiltParallaxCard> with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  
  // Normalized mouse position: -1.0 to 1.0 (0,0 is center)
  Offset _normalizedPointer = Offset.zero;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _resetController.addListener(() {
      setState(() {
        _normalizedPointer = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset localPosition) {
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
    
    // Convert local pixels to normalized -1.0 to 1.0 space relative to center
    final double centerX = widget.width / 2;
    final double centerY = widget.height / 2;
    
    final double normalizedX = (localPosition.dx - centerX) / centerX;
    final double normalizedY = (localPosition.dy - centerY) / centerY;
    
    setState(() {
      _normalizedPointer = Offset(
        normalizedX.clamp(-1.0, 1.0),
        normalizedY.clamp(-1.0, 1.0),
      );
    });
  }

  void _onPointerExit() {
    // Animate smoothly back to flat (0,0)
    _resetAnimation = Tween<Offset>(
      begin: _normalizedPointer,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutBack,
    ));
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // The rotation effect (tilt the card away from the mouse)
    // Moving mouse Right (positive X) rotates around Y axis
    // Moving mouse Down (positive Y) rotates around X axis (but negative to tilt away)
    final double rotateX = -_normalizedPointer.dy * widget.maxTilt;
    final double rotateY = _normalizedPointer.dx * widget.maxTilt;
    
    // The Parallax effect (foreground shifts opposite to tilt to appear "floating")
    final double parallaxOffset = 20.0;
    final double foregroundDx = _normalizedPointer.dx * parallaxOffset;
    final double foregroundDy = _normalizedPointer.dy * parallaxOffset;

    return MouseRegion(
      onHover: (event) => _onPointerMove(event.localPosition),
      onExit: (_) => _onPointerExit(),
      child: GestureDetector(
        onPanUpdate: (details) => _onPointerMove(details.localPosition),
        onPanEnd: (_) => _onPointerExit(),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective
              ..rotateX(rotateX)
              ..rotateY(rotateY),
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                // Background Layer (Flat on the card)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: widget.background,
                ),
                
                // Shadow Layer for depth
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: Offset(
                          -foregroundDx * 0.5, 
                          -foregroundDy * 0.5 + 10
                        ),
                      )
                    ]
                  ),
                ),
                
                // Foreground Layer (Shifts dynamically based on tilt)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(foregroundDx, foregroundDy),
                    child: widget.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
