import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbStarRating extends StatefulWidget {
  final int maxStars;
  final double rating;
  final double starSize;
  final ValueChanged<double>? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool allowHalfRating;

  const SbStarRating({
    super.key,
    this.maxStars = 5,
    required this.rating,
    this.starSize = 32.0,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
    this.allowHalfRating = true,
  }) : assert(rating >= 0 && rating <= maxStars);

  @override
  State<SbStarRating> createState() => _SbStarRatingState();
}

class _SbStarRatingState extends State<SbStarRating> {
  double _currentRating = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(SbStarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rating != oldWidget.rating && !_isDragging) {
      _currentRating = widget.rating;
    }
  }

  void _handleInteraction(Offset localPosition) {
    if (widget.onRatingChanged == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final double dx = localPosition.dx;
    
    // Calculate rating based on touch position relative to total width
    // We add spacing into account for more accurate touch detection
    final totalWidth = box.size.width;
    double rawRating = (dx / totalWidth) * widget.maxStars;
    
    rawRating = rawRating.clamp(0.0, widget.maxStars.toDouble());

    setState(() {
      if (widget.allowHalfRating) {
        // Round to nearest 0.5
        _currentRating = (rawRating * 2).round() / 2.0;
      } else {
        // Round up to nearest whole number
        _currentRating = rawRating.ceilToDouble();
      }
    });

    widget.onRatingChanged!(_currentRating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = widget.activeColor ?? Colors.amber.shade500;
    final inactive = widget.inactiveColor ?? colorScheme.outlineVariant.withValues(alpha: 0.5);

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _isDragging = true;
        _handleInteraction(details.localPosition);
      },
      onHorizontalDragUpdate: (details) {
        _handleInteraction(details.localPosition);
      },
      onHorizontalDragEnd: (_) {
        _isDragging = false;
      },
      onTapDown: (details) {
        _handleInteraction(details.localPosition);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.maxStars, (index) {
          final isFull = _currentRating >= index + 1;
          final isHalf = widget.allowHalfRating && _currentRating > index && _currentRating < index + 1;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: isFull ? 1.0 : (isHalf ? 0.5 : 0.0),
            ),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Stack(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: inactive,
                    size: widget.starSize,
                  ),
                  ClipRect(
                    clipper: _HalfStarClipper(value),
                    child: Icon(
                      Icons.star_rounded,
                      color: active,
                      size: widget.starSize,
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

class _HalfStarClipper extends CustomClipper<Rect> {
  final double widthFactor;

  _HalfStarClipper(this.widthFactor);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * widthFactor, size.height);
  }

  @override
  bool shouldReclip(covariant _HalfStarClipper oldClipper) {
    return oldClipper.widthFactor != widthFactor;
  }
}
