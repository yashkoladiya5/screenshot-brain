import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbTiltImage extends StatefulWidget {
  final ImageProvider image;
  final double width;
  final double height;
  final double borderRadius;
  final double maxTiltAngle;
  final String? caption;
  final Color? captionColor;

  const SbTiltImage({
    super.key,
    required this.image,
    this.width = double.infinity,
    this.height = 250.0,
    this.borderRadius = SBRadius.md,
    this.maxTiltAngle = 0.15,
    this.caption,
    this.captionColor,
  });

  @override
  State<SbTiltImage> createState() => _SbTiltImageState();
}

class _SbTiltImageState extends State<SbTiltImage> with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  
  Offset _tiltOffset = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _resetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutBack,
    ));
    
    _resetController.addListener(() {
      if (_resetController.isAnimating) {
        setState(() {
          _tiltOffset = _resetAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event, Size size) {
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
    
    // Calculate normalized offset from center (-1 to 1)
    final double dx = (event.localPosition.dx - (size.width / 2)) / (size.width / 2);
    final double dy = (event.localPosition.dy - (size.height / 2)) / (size.height / 2);
    
    setState(() {
      _isHovering = true;
      _tiltOffset = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovering = false;
    });
    
    _resetAnimation = Tween<Offset>(
      begin: _tiltOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutBack,
    ));
    
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = widget.width == double.infinity ? constraints.maxWidth : widget.width;
        
        // Active offset based on hover or animation
        final activeOffset = _isHovering || _resetController.isAnimating 
            ? _tiltOffset 
            : Offset.zero;
            
        // X tilt is controlled by Y offset
        final double rotateX = -activeOffset.dy * widget.maxTiltAngle;
        // Y tilt is controlled by X offset
        final double rotateY = activeOffset.dx * widget.maxTiltAngle;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Add perspective
          ..rotateX(rotateX)
          ..rotateY(rotateY);

        return MouseRegion(
          onHover: (event) => _onPointerMove(event, Size(width, widget.height)),
          onExit: (_) => _onPointerExit(),
          child: GestureDetector(
            onPanUpdate: (details) => _onPointerMove(
              PointerHoverEvent(position: details.globalPosition, localPosition: details.localPosition), 
              Size(width, widget.height)
            ),
            onPanEnd: (_) => _onPointerExit(),
            child: TweenAnimationBuilder<Matrix4>(
              tween: Matrix4Tween(begin: transform, end: transform),
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              builder: (context, matrix, child) {
                return Transform(
                  transform: matrix,
                  alignment: FractionalOffset.center,
                  child: Container(
                    width: width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          spreadRadius: -2,
                          offset: Offset(-activeOffset.dx * 15, -activeOffset.dy * 15 + 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base Image (scales up slightly to prevent edge clipping during tilt)
                          Transform.scale(
                            scale: 1.05,
                            child: Image(
                              image: widget.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          // Optional Caption overlay
                          if (widget.caption != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(SBSpacing.md),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  widget.caption!,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: widget.captionColor ?? Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                          // Lighting / Glare effect overlay
                          if (_isHovering || _resetController.isAnimating)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: FractionalOffset(
                                      (activeOffset.dx + 1) / 2, // Map -1..1 to 0..1
                                      (activeOffset.dy + 1) / 2,
                                    ),
                                    radius: 1.2,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
