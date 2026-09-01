import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbCyberpunkGlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool isGlitching;

  const SbCyberpunkGlitchText({
    super.key,
    required this.text,
    this.style,
    this.isGlitching = true,
  });

  @override
  State<SbCyberpunkGlitchText> createState() => _SbCyberpunkGlitchTextState();
}

class _SbCyberpunkGlitchTextState extends State<SbCyberpunkGlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    if (widget.isGlitching) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SbCyberpunkGlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlitching != oldWidget.isGlitching) {
      if (widget.isGlitching) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = widget.style ?? const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.isGlitching || _controller.value == 0.0) {
          return Text(widget.text, style: textStyle);
        }

        final double jitter = _random.nextDouble() * 3.0; 
        
        return Stack(
          children: [
            Transform.translate(
              offset: Offset(-2.0 - jitter, 0.0),
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  widget.text,
                  style: textStyle.copyWith(color: Colors.cyanAccent),
                ),
              ),
            ),
            
            Transform.translate(
              offset: Offset(2.0 + jitter, jitter * 0.5),
              child: Opacity(
                opacity: 0.8,
                child: Text(
                  widget.text,
                  style: textStyle.copyWith(color: Colors.pinkAccent),
                ),
              ),
            ),
            
            ClipRect(
              child: Transform.translate(
                offset: Offset(
                  _random.nextDouble() > 0.8 ? -jitter : 0, 
                  _random.nextDouble() > 0.9 ? jitter : 0
                ),
                child: Text(
                  widget.text,
                  style: textStyle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
