import 'package:flutter/material.dart';

class SbNeuSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color backgroundColor;
  final double width;
  final double height;

  const SbNeuSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = Colors.green,
    this.backgroundColor = const Color(0xFFE0E5EC),
    this.width = 80.0,
    this.height = 40.0,
  });

  @override
  State<SbNeuSwitch> createState() => _SbNeuSwitchState();
}

class _SbNeuSwitchState extends State<SbNeuSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.value ? 1.0 : 0.0,
    );

    _alignmentAnimation = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade400,
      end: widget.activeColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(SbNeuSwitch oldWidget) {
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
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              // Simulating inner shadow with standard shadows or just plain track
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Align(
              alignment: _alignmentAnimation.value,
              child: Container(
                width: widget.height - 8,
                height: widget.height - 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.backgroundColor,
                  // Drop shadow effect for the thumb to make it pop out
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: const Offset(-3, -3),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(3, 3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: (widget.height - 8) * 0.4,
                    height: (widget.height - 8) * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colorAnimation.value,
                      boxShadow: widget.value ? [
                        BoxShadow(
                          color: _colorAnimation.value!.withValues(alpha: 0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ] : [],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
