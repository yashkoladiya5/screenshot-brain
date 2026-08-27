import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SbGlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool isAnimated;
  final Duration glitchInterval;

  const SbGlitchText({
    super.key,
    required this.text,
    this.style,
    this.isAnimated = true,
    this.glitchInterval = const Duration(milliseconds: 3000),
  });

  @override
  State<SbGlitchText> createState() => _SbGlitchTextState();
}

class _SbGlitchTextState extends State<SbGlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _glitchTimer;
  final math.Random _random = math.Random();
  
  bool _isGlitching = false;
  double _offset1 = 0;
  double _offset2 = 0;
  double _offset3 = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (_isGlitching) {
          setState(() {
            // Rapidly randomize offsets during the glitch burst
            _offset1 = (_random.nextDouble() - 0.5) * 6;
            _offset2 = (_random.nextDouble() - 0.5) * 6;
            _offset3 = (_random.nextDouble() - 0.5) * 6;
          });
        }
      });
      
    if (widget.isAnimated) {
      _startGlitchCycle();
    }
  }

  @override
  void didUpdateWidget(SbGlitchText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _startGlitchCycle();
      } else {
        _glitchTimer?.cancel();
        _controller.stop();
        setState(() {
          _isGlitching = false;
          _offset1 = _offset2 = _offset3 = 0;
        });
      }
    }
  }

  void _startGlitchCycle() {
    _glitchTimer?.cancel();
    _glitchTimer = Timer.periodic(widget.glitchInterval, (timer) {
      // Trigger a short burst of glitching
      _isGlitching = true;
      _controller.forward(from: 0.0).then((_) {
        _isGlitching = false;
        setState(() {
          _offset1 = _offset2 = _offset3 = 0;
        });
      });
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = widget.style ?? theme.textTheme.headlineMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    ) ?? const TextStyle();

    // Determine slice heights for the clipping effect
    final double slice1Height = _isGlitching ? 0.3 + _random.nextDouble() * 0.2 : 0.33;
    final double slice2Height = _isGlitching ? 0.2 + _random.nextDouble() * 0.3 : 0.33;

    return Stack(
      children: [
        // 1. Base layer (unaffected)
        Opacity(
          opacity: _isGlitching ? 0.2 : 1.0,
          child: Text(widget.text, style: baseStyle),
        ),
        
        // 2. Cyan Shift Layer (Top Slice)
        if (_isGlitching)
          Transform.translate(
            offset: Offset(_offset1, 0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: slice1Height,
                child: Text(
                  widget.text,
                  style: baseStyle.copyWith(
                    color: Colors.cyanAccent,
                    shadows: [
                      const Shadow(color: Colors.cyanAccent, blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ),
          
        // 3. Magenta Shift Layer (Middle Slice)
        if (_isGlitching)
          Transform.translate(
            offset: Offset(_offset2, 0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                heightFactor: slice2Height,
                child: Text(
                  widget.text,
                  style: baseStyle.copyWith(
                    color: Colors.pinkAccent,
                    shadows: [
                      const Shadow(color: Colors.pinkAccent, blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ),
          ),
          
        // 4. Yellow Shift Layer (Bottom Slice)
        if (_isGlitching)
          Transform.translate(
            offset: Offset(_offset3, 0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1.0 - slice1Height - slice2Height,
                child: Text(
                  widget.text,
                  style: baseStyle.copyWith(
                    color: Colors.yellowAccent,
                  ),
                ),
              ),
            ),
          ),
          
        // 5. White overlay text during glitch to simulate flash
        if (_isGlitching)
          Transform.translate(
            offset: Offset(_offset1 * 0.5, _offset2 * 0.5),
            child: Opacity(
              opacity: _random.nextDouble() > 0.5 ? 0.8 : 0.2,
              child: Text(
                widget.text,
                style: baseStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
