import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/tokens.dart';

class SbMagneticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double magnetStrength;
  final Color? backgroundColor;
  final double borderRadius;

  const SbMagneticButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.width = 150.0,
    this.height = 50.0,
    this.magnetStrength = 0.5, // How far the button pulls towards cursor (0.0 to 1.0)
    this.backgroundColor,
    this.borderRadius = SBRadius.full,
  });

  @override
  State<SbMagneticButton> createState() => _SbMagneticButtonState();
}

class _SbMagneticButtonState extends State<SbMagneticButton> with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  
  Offset _magnetOffset = Offset.zero;
  bool _isHovering = false;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _resetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
    
    _resetController.addListener(() {
      if (_resetController.isAnimating) {
        setState(() {
          _magnetOffset = _resetAnimation.value;
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
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
    
    // Calculate distance from center of the button
    final size = renderBox.size;
    final center = Offset(size.width / 2, size.height / 2);
    final dx = event.localPosition.dx - center.dx;
    final dy = event.localPosition.dy - center.dy;
    
    setState(() {
      _isHovering = true;
      // Pull button towards cursor based on strength
      _magnetOffset = Offset(dx * widget.magnetStrength, dy * widget.magnetStrength);
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovering = false;
    });
    
    // Animate back to center using elastic curve
    _resetAnimation = Tween<Offset>(
      begin: _magnetOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.elasticOut,
    ));
    
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = widget.backgroundColor ?? theme.colorScheme.primary;
    
    final activeOffset = _isHovering || _resetController.isAnimating 
        ? _magnetOffset 
        : Offset.zero;

    return MouseRegion(
      onHover: _onPointerMove,
      onExit: (_) => _onPointerExit(),
      child: GestureDetector(
        onPanUpdate: (details) => _onPointerMove(
          PointerHoverEvent(
            position: details.globalPosition, 
            localPosition: details.localPosition
          )
        ),
        onPanEnd: (_) => _onPointerExit(),
        onTap: widget.onPressed,
        child: Container(
          // We wrap in a slightly larger invisible container so the hover area
          // is larger than the button itself, making the magnetic pull start earlier
          width: widget.width + 40,
          height: widget.height + 40,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: activeOffset,
            child: Container(
              key: _buttonKey,
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.4),
                    blurRadius: _isHovering ? 20 : 10,
                    spreadRadius: _isHovering ? 2 : 0,
                    offset: Offset(
                      _isHovering ? -activeOffset.dx * 0.5 : 0,
                      _isHovering ? -activeOffset.dy * 0.5 + 4 : 4,
                    ),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Center(
                    child: DefaultTextStyle(
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
