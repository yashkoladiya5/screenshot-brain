import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SbGlitchTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color primaryGlitchColor;
  final Color secondaryGlitchColor;
  final bool isGlitching;

  const SbGlitchTextEffect({
    super.key,
    required this.text,
    this.style = const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
    this.primaryGlitchColor = Colors.red,
    this.secondaryGlitchColor = Colors.cyan,
    this.isGlitching = true,
  });

  @override
  State<SbGlitchTextEffect> createState() => _SbGlitchTextEffectState();
}

class _SbGlitchTextEffectState extends State<SbGlitchTextEffect> with SingleTickerProviderStateMixin {
  late Timer _glitchTimer;
  final math.Random _random = math.Random();
  
  double _xOffsetPrimary = 0.0;
  double _yOffsetPrimary = 0.0;
  
  double _xOffsetSecondary = 0.0;
  double _yOffsetSecondary = 0.0;
  
  double _opacityPrimary = 0.0;
  double _opacitySecondary = 0.0;
  
  // Variables for slice clipping
  double _clipTop = 0.0;
  double _clipBottom = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.isGlitching) {
      _startGlitching();
    }
  }

  @override
  void didUpdateWidget(SbGlitchTextEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlitching && !oldWidget.isGlitching) {
      _startGlitching();
    } else if (!widget.isGlitching && oldWidget.isGlitching) {
      _stopGlitching();
    }
  }

  void _startGlitching() {
    // Run a timer very fast to simulate erratic hardware glitches
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      
      // We don't want it to glitch constantly, we want it to stutter
      // 80% chance to do nothing (appear normal)
      if (_random.nextDouble() > 0.2) {
        setState(() {
          _xOffsetPrimary = 0.0;
          _yOffsetPrimary = 0.0;
          _xOffsetSecondary = 0.0;
          _yOffsetSecondary = 0.0;
          _opacityPrimary = 0.0;
          _opacitySecondary = 0.0;
          _clipTop = 0.0;
          _clipBottom = 1.0;
        });
        return;
      }

      // 20% chance to trigger a violent glitch
      setState(() {
        // Random offsets between -4.0 and 4.0
        _xOffsetPrimary = (_random.nextDouble() * 8.0) - 4.0;
        _yOffsetPrimary = (_random.nextDouble() * 4.0) - 2.0;
        
        _xOffsetSecondary = (_random.nextDouble() * 8.0) - 4.0;
        _yOffsetSecondary = (_random.nextDouble() * 4.0) - 2.0;
        
        // Random opacity to make it flicker
        _opacityPrimary = 0.4 + (_random.nextDouble() * 0.6);
        _opacitySecondary = 0.4 + (_random.nextDouble() * 0.6);
        
        // Random slice clipping to simulate tearing
        if (_random.nextDouble() > 0.5) {
          _clipTop = _random.nextDouble() * 0.5;
          _clipBottom = _clipTop + 0.1 + (_random.nextDouble() * 0.4);
        } else {
          _clipTop = 0.0;
          _clipBottom = 1.0;
        }
      });
    });
  }

  void _stopGlitching() {
    if (_glitchTimer.isActive) {
      _glitchTimer.cancel();
    }
    setState(() {
      _xOffsetPrimary = 0.0;
      _yOffsetPrimary = 0.0;
      _xOffsetSecondary = 0.0;
      _yOffsetSecondary = 0.0;
      _opacityPrimary = 0.0;
      _opacitySecondary = 0.0;
      _clipTop = 0.0;
      _clipBottom = 1.0;
    });
  }

  @override
  void dispose() {
    if (_glitchTimer.isActive) {
      _glitchTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Primary Glitch Layer (e.g. Red)
        if (widget.isGlitching)
          Transform.translate(
            offset: Offset(_xOffsetPrimary, _yOffsetPrimary),
            child: Opacity(
              opacity: _opacityPrimary,
              child: ClipRect(
                clipper: _GlitchClipper(_clipTop, _clipBottom),
                child: Text(
                  widget.text,
                  style: widget.style.copyWith(color: widget.primaryGlitchColor),
                ),
              ),
            ),
          ),
          
        // Secondary Glitch Layer (e.g. Cyan)
        if (widget.isGlitching)
          Transform.translate(
            offset: Offset(_xOffsetSecondary, _yOffsetSecondary),
            child: Opacity(
              opacity: _opacitySecondary,
              child: ClipRect(
                clipper: _GlitchClipper(1.0 - _clipBottom, 1.0 - _clipTop),
                child: Text(
                  widget.text,
                  style: widget.style.copyWith(color: widget.secondaryGlitchColor),
                ),
              ),
            ),
          ),
          
        // The actual text (Base Layer)
        // We also clip the base text occasionally to simulate digital tearing
        ClipRect(
          clipper: widget.isGlitching && _clipTop > 0.0 
              ? _GlitchClipper(0.0, _clipTop) // Only show top part when tearing
              : _GlitchClipper(0.0, 1.0), // Show full text normally
          child: Text(
            widget.text,
            style: widget.style,
          ),
        ),
        
        // Bottom part of the tear
        if (widget.isGlitching && _clipTop > 0.0)
          Transform.translate(
            offset: Offset((_random.nextDouble() * 4.0) - 2.0, 0),
            child: ClipRect(
              clipper: _GlitchClipper(_clipBottom, 1.0),
              child: Text(
                widget.text,
                style: widget.style,
              ),
            ),
          )
      ],
    );
  }
}

class _GlitchClipper extends CustomClipper<Rect> {
  final double topPercent;
  final double bottomPercent;

  _GlitchClipper(this.topPercent, this.bottomPercent);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0.0,
      size.height * topPercent,
      size.width,
      size.height * bottomPercent,
    );
  }

  @override
  bool shouldReclip(covariant _GlitchClipper oldClipper) {
    return oldClipper.topPercent != topPercent || oldClipper.bottomPercent != bottomPercent;
  }
}
