import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbSlideActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onComplete;
  final Color? baseColor;
  final Color? activeColor;
  final Widget? icon;

  const SbSlideActionButton({
    super.key,
    required this.text,
    required this.onComplete,
    this.baseColor,
    this.activeColor,
    this.icon,
  });

  @override
  State<SbSlideActionButton> createState() => _SbSlideActionButtonState();
}

class _SbSlideActionButtonState extends State<SbSlideActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  final double _thumbSize = 56.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      setState(() {
        _dragPosition = _dragPosition * (1 - _resetController.value);
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isCompleted) return;

    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) {
        _dragPosition = 0;
      } else if (_dragPosition > maxWidth - _thumbSize) {
        _dragPosition = maxWidth - _thumbSize;
      }
    });
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (_isCompleted) return;

    if (_dragPosition >= maxWidth - _thumbSize - 10) {
      // Completed
      setState(() {
        _isCompleted = true;
        _dragPosition = maxWidth - _thumbSize;
      });
      widget.onComplete();
    } else {
      // Reset
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = widget.baseColor ?? colorScheme.surfaceContainerHighest;
    final active = widget.activeColor ?? colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final progress = _dragPosition / (maxWidth - _thumbSize);

        return Container(
          width: maxWidth,
          height: _thumbSize,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(SBRadius.full),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Stack(
            children: [
              // Background fill
              Container(
                width: _thumbSize + _dragPosition,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: active.withValues(alpha: 0.2 + (0.8 * progress)),
                  borderRadius: BorderRadius.circular(SBRadius.full),
                ),
              ),
              // Text
              Center(
                child: Opacity(
                  opacity: (1.0 - progress).clamp(0.0, 1.0),
                  child: Text(
                    widget.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              // Thumb
              Positioned(
                left: _dragPosition,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanUpdate: (details) => _onPanUpdate(details, maxWidth),
                  onPanEnd: (details) => _onPanEnd(details, maxWidth),
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: _isCompleted ? active : colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(2, 0),
                        )
                      ],
                    ),
                    child: Center(
                      child: _isCompleted
                          ? Icon(Icons.check_rounded, color: colorScheme.onPrimary)
                          : widget.icon ?? Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: active,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
