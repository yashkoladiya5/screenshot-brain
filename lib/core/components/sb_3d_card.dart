import 'package:flutter/material.dart';
import '../design/tokens.dart';

class Sb3DCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double maxTiltAngle;
  final Color? backgroundColor;
  final double borderRadius;
  final double depth;

  const Sb3DCard({
    super.key,
    required this.child,
    this.width = 300.0,
    this.height = 400.0,
    this.maxTiltAngle = 0.2, // Radians
    this.backgroundColor,
    this.borderRadius = SBRadius.lg,
    this.depth = 20.0,
  });

  @override
  State<Sb3DCard> createState() => _Sb3DCardState();
}

class _Sb3DCardState extends State<Sb3DCard> with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  
  Offset _currentPointerPosition = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _resetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    ));
    
    _resetController.addListener(() {
      if (_resetController.isAnimating) {
        setState(() {
          _currentPointerPosition = _resetAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event) {
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
    setState(() {
      _isHovering = true;
      _currentPointerPosition = event.localPosition;
    });
  }

  void _onPointerExit(PointerEvent event) {
    setState(() {
      _isHovering = false;
    });
    
    _resetAnimation = Tween<Offset>(
      begin: _currentPointerPosition,
      end: Offset(widget.width / 2, widget.height / 2),
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    ));
    
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.surface;

    // Default center if not hovering and not animating
    final center = Offset(widget.width / 2, widget.height / 2);
    final activePosition = _isHovering || _resetController.isAnimating 
        ? _currentPointerPosition 
        : center;

    // Calculate rotation angles
    // Normalize coordinates so center is (0,0), ranging from -1 to 1
    final normalizedX = ((activePosition.dx / widget.width) * 2) - 1;
    final normalizedY = ((activePosition.dy / widget.height) * 2) - 1;

    // Clamp values to prevent extreme flipping if pointer goes way outside
    final clampedX = normalizedX.clamp(-1.0, 1.0);
    final clampedY = normalizedY.clamp(-1.0, 1.0);

    // X axis rotation is controlled by Y pointer movement
    final rotateX = -clampedY * widget.maxTiltAngle;
    // Y axis rotation is controlled by X pointer movement
    final rotateY = clampedX * widget.maxTiltAngle;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(rotateX)
      ..rotateY(rotateY);
      
    // Calculate shadow offset based on tilt
    final shadowOffsetX = clampedX * widget.depth;
    final shadowOffsetY = clampedY * widget.depth;

    return MouseRegion(
      onHover: (event) => _onPointerMove(event),
      onExit: (event) => _onPointerExit(event),
      child: GestureDetector(
        onPanUpdate: (details) => _onPointerMove(
          PointerHoverEvent(position: details.globalPosition, localPosition: details.localPosition)
        ),
        onPanEnd: (details) => _onPointerExit(const PointerExitEvent()),
        child: TweenAnimationBuilder<Matrix4>(
          tween: Matrix4Tween(begin: transform, end: transform),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          builder: (context, matrix, child) {
            return Transform(
              transform: matrix,
              alignment: FractionalOffset.center,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: widget.depth,
                      spreadRadius: -5,
                      offset: Offset(-shadowOffsetX, -shadowOffsetY + 10),
                    )
                  ],
                ),
                // Gloss/Reflection effect overlay
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: widget.child,
                    ),
                    // Only show gloss if hovering
                    if (_isHovering || _resetController.isAnimating)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: FractionalOffset(
                                (activePosition.dx / widget.width).clamp(0.0, 1.0),
                                (activePosition.dy / widget.height).clamp(0.0, 1.0),
                              ),
                              radius: 1.0,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.8],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
