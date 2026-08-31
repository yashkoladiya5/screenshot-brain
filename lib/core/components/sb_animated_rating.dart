import 'package:flutter/material.dart';

class SbAnimatedRating extends StatefulWidget {
  final int maxRating;
  final int initialRating;
  final ValueChanged<int>? onRatingChanged;
  final double iconSize;
  final Color activeColor;
  final Color inactiveColor;

  const SbAnimatedRating({
    super.key,
    this.maxRating = 5,
    this.initialRating = 0,
    this.onRatingChanged,
    this.iconSize = 40.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<SbAnimatedRating> createState() => _SbAnimatedRatingState();
}

class _SbAnimatedRatingState extends State<SbAnimatedRating> with TickerProviderStateMixin {
  late int _currentRating;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;

    _controllers = List.generate(
      widget.maxRating,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 0.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    // Set initial state without animation
    for (int i = 0; i < widget.maxRating; i++) {
      if (i < _currentRating) {
        _controllers[i].value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStarTapped(int index) {
    int newRating = index + 1;
    if (_currentRating == newRating) {
      newRating = 0; // Toggle off if tapping the same rating
    }

    setState(() {
      _currentRating = newRating;
    });

    for (int i = 0; i < widget.maxRating; i++) {
      if (i < _currentRating) {
        _controllers[i].forward(from: 0.0);
      } else {
        _controllers[i].reverse();
      }
    }

    if (widget.onRatingChanged != null) {
      widget.onRatingChanged!(_currentRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: () => _onStarTapped(index),
          child: AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final isFilled = index < _currentRating;
              return Transform.scale(
                scale: _scaleAnimations[index].value,
                child: Transform.rotate(
                  angle: _rotationAnimations[index].value,
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFilled ? widget.activeColor : widget.inactiveColor,
                    size: widget.iconSize,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
