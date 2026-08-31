import 'package:flutter/material.dart';

class SbBouncyText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration letterDelay;
  final bool autoPlay;

  const SbBouncyText({
    super.key,
    required this.text,
    this.style,
    this.letterDelay = const Duration(milliseconds: 50),
    this.autoPlay = true,
  });

  @override
  State<SbBouncyText> createState() => _SbBouncyTextState();
}

class _SbBouncyTextState extends State<SbBouncyText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    // Total duration depends on number of letters and delay
    final totalDuration = Duration(
      milliseconds: 600 + (widget.text.length * widget.letterDelay.inMilliseconds)
    );

    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    _animations = [];
    final characters = widget.text.characters.toList();
    
    // Create staggered animations for each letter
    for (int i = 0; i < characters.length; i++) {
      // Calculate start and end times for this specific letter
      final double startTime = (i * widget.letterDelay.inMilliseconds) / totalDuration.inMilliseconds;
      // Each letter takes 600ms to bounce
      final double endTime = startTime + (600 / totalDuration.inMilliseconds);

      _animations.add(
        TweenSequence<double>([
          // Jump up
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -15.0)
                .chain(CurveTween(curve: Curves.easeOutQuad)),
            weight: 30.0,
          ),
          // Fall down past the baseline (squish)
          TweenSequenceItem(
            tween: Tween<double>(begin: -15.0, end: 5.0)
                .chain(CurveTween(curve: Curves.easeInQuad)),
            weight: 30.0,
          ),
          // Settle back to baseline
          TweenSequenceItem(
            tween: Tween<double>(begin: 5.0, end: 0.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 40.0,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(startTime, endTime.clamp(0.0, 1.0)),
          ),
        ),
      );
    }

    if (widget.autoPlay) {
      _controller.forward();
    }
  }
  
  void triggerAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characters = widget.text.characters.toList();
    
    return GestureDetector(
      onTap: triggerAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(characters.length, (index) {
          final char = characters[index];
          // Handle spaces which don't need animation wrappers as heavily, but maintain spacing
          if (char == ' ') {
            return Text(' ', style: widget.style);
          }
          
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animations[index].value),
                child: child,
              );
            },
            child: Text(
              char,
              style: widget.style,
            ),
          );
        }),
      ),
    );
  }
}
