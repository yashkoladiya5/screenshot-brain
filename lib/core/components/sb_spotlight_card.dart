import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbSpotlightCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color spotlightColor;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const SbSpotlightCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = 200.0,
    this.spotlightColor = const Color(0x33FFFFFF), // Highly translucent white
    this.borderRadius = SBRadius.lg,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<SbSpotlightCard> createState() => _SbSpotlightCardState();
}

class _SbSpotlightCardState extends State<SbSpotlightCard> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  Offset _pointerPosition = Offset.zero;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event) {
    setState(() {
      _isHovering = true;
      _pointerPosition = event.localPosition;
    });
    if (!_fadeController.isAnimating && _fadeController.value != 1.0) {
      _fadeController.forward();
    }
  }

  void _onPointerExit(PointerEvent event) {
    setState(() {
      _isHovering = false;
    });
    _fadeController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final border = widget.borderColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.2);

    return MouseRegion(
      onHover: _onPointerMove,
      onExit: _onPointerExit,
      child: GestureDetector(
        onPanUpdate: (details) => _onPointerMove(
          PointerHoverEvent(
            position: details.globalPosition, 
            localPosition: details.localPosition
          )
        ),
        onPanEnd: (_) => _onPointerExit(const PointerExitEvent()),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              // 1. Base Background
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(color: border),
                ),
              ),
              
              // 2. The Animated Spotlight Overlay
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    if (_fadeAnimation.value == 0.0) return const SizedBox.shrink();
                    
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: FractionalOffset(
                              (_pointerPosition.dx / widget.width).clamp(0.0, 1.0),
                              (_pointerPosition.dy / widget.height).clamp(0.0, 1.0),
                            ),
                            radius: 1.5,
                            colors: [
                              widget.spotlightColor,
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4], // 0.4 ensures a tight, focused beam
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // 3. The Content Overlay
              // Placed on top so the text/content is drawn *over* the spotlight
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(SBSpacing.md),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
