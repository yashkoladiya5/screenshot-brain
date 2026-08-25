import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbAnimatedToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData? activeIcon;
  final IconData? inactiveIcon;

  const SbAnimatedToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeIcon = Icons.check_rounded,
    this.inactiveIcon = Icons.close_rounded,
  });

  @override
  State<SbAnimatedToggle> createState() => _SbAnimatedToggleState();
}

class _SbAnimatedToggleState extends State<SbAnimatedToggle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _alignmentAnimation = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorScheme = Theme.of(context).colorScheme;
    
    _colorAnimation = ColorTween(
      begin: widget.inactiveColor ?? colorScheme.surfaceContainerHighest,
      end: widget.activeColor ?? colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(SbAnimatedToggle oldWidget) {
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
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 64.0,
            height: 36.0,
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(SBRadius.full),
            ),
            child: Align(
              alignment: _alignmentAnimation.value,
              child: Container(
                width: 28.0,
                height: 28.0,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Active Icon
                    if (widget.activeIcon != null)
                      Opacity(
                        opacity: _controller.value,
                        child: Transform.scale(
                          scale: _controller.value,
                          child: Icon(
                            widget.activeIcon,
                            size: 16,
                            color: _colorAnimation.value,
                          ),
                        ),
                      ),
                    // Inactive Icon
                    if (widget.inactiveIcon != null)
                      Opacity(
                        opacity: 1.0 - _controller.value,
                        child: Transform.scale(
                          scale: 1.0 - _controller.value,
                          child: Icon(
                            widget.inactiveIcon,
                            size: 16,
                            color: _colorAnimation.value,
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
    );
  }
}
