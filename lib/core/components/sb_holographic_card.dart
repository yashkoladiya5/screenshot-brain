import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbHolographicCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final Color foilColor1;
  final Color foilColor2;
  final Color foilColor3;

  const SbHolographicCard({
    super.key,
    required this.child,
    this.width = 300.0,
    this.height = 420.0,
    this.borderRadius = 20.0,
    this.foilColor1 = const Color(0xFFFF00FF), // Magenta
    this.foilColor2 = const Color(0xFF00FFFF), // Cyan
    this.foilColor3 = const Color(0xFFFFFF00), // Yellow
  });

  @override
  State<SbHolographicCard> createState() => _SbHolographicCardState();
}

class _SbHolographicCardState extends State<SbHolographicCard> with SingleTickerProviderStateMixin {
  // We use touch positions to tilt the card and shift the holo gradient
  double _tiltX = 0;
  double _tiltY = 0;
  
  // Animation controller for when the user releases the card, returning it to center
  late AnimationController _restoreController;
  late Animation<double> _restoreAnimation;

  @override
  void initState() {
    super.initState();
    _restoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _restoreAnimation = CurvedAnimation(
      parent: _restoreController,
      curve: Curves.easeOutElastic,
    );
    
    _restoreController.addListener(() {
      setState(() {
        _tiltX = _tiltX * (1.0 - _restoreAnimation.value);
        _tiltY = _tiltY * (1.0 - _restoreAnimation.value);
      });
    });
  }

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_restoreController.isAnimating) {
      _restoreController.stop();
    }
    
    setState(() {
      // Convert drag deltas into tilt degrees (max ~20 degrees)
      _tiltX -= details.delta.dy * 0.5;
      _tiltY += details.delta.dx * 0.5;
      
      _tiltX = _tiltX.clamp(-20.0, 20.0);
      _tiltY = _tiltY.clamp(-20.0, 20.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _restoreController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // We convert the physical tilt into a shift in the gradient
    // When tilted left, gradient shifts right. When tilted up, gradient shifts down.
    final double gradientShiftX = -(_tiltY / 20.0);
    final double gradientShiftY = -(_tiltX / 20.0);
    
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () => _onPanEnd(DragEndDetails()),
      child: Transform(
        // Apply 3D perspective and physical rotation
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(_tiltX * math.pi / 180)
          ..rotateY(_tiltY * math.pi / 180),
        alignment: FractionalOffset.center,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Colors.white,
            boxShadow: [
              // Dynamic shadow that moves opposite to the tilt direction
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20 + (_tiltX.abs() + _tiltY.abs()) * 0.5,
                spreadRadius: 2,
                offset: Offset(_tiltY, _tiltX * 1.5),
              ),
            ]
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. The base child content
              widget.child,
              
              // 2. The holographic foil layer
              // We use a sweep gradient combined with a linear gradient and BlendMode
              // to create an iridescent foil effect that reacts to the tilt!
              Positioned.fill(
                child: BlendModeOverlay(
                  blendMode: BlendMode.colorBurn,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(gradientShiftX - 1.0, gradientShiftY - 1.0),
                        end: Alignment(gradientShiftX + 1.0, gradientShiftY + 1.0),
                        colors: [
                          widget.foilColor1.withValues(alpha: 0.5),
                          widget.foilColor2.withValues(alpha: 0.5),
                          widget.foilColor3.withValues(alpha: 0.5),
                          widget.foilColor1.withValues(alpha: 0.5),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              
              // 3. Glare/Shine overlay
              // A sharp white diagonal line that sweeps across the card based on tilt
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(gradientShiftX - 1.5, gradientShiftY - 1.5),
                      end: Alignment(gradientShiftX + 1.5, gradientShiftY + 1.5),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget to apply advanced blend modes to children in Flutter
class BlendModeOverlay extends StatelessWidget {
  final Widget child;
  final BlendMode blendMode;

  const BlendModeOverlay({
    super.key,
    required this.child,
    required this.blendMode,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: blendMode,
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [Colors.white, Colors.white],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
