import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SbGlitchTextEffect extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color primaryColor; // Usually Cyan for glitch
  final Color secondaryColor; // Usually Red/Magenta for glitch
  final bool isGlitching;

  const SbGlitchTextEffect({
    super.key,
    required this.text,
    this.style = const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
    this.primaryColor = const Color(0xFF00FFFF),
    this.secondaryColor = const Color(0xFFFF00FF),
    this.isGlitching = true,
  });

  @override
  State<SbGlitchTextEffect> createState() => _SbGlitchTextEffectState();
}

class _SbGlitchTextEffectState extends State<SbGlitchTextEffect> {
  final math.Random _random = math.Random();
  
  // Offsets for the RGB split channels
  double _cyanOffsetX = 0;
  double _cyanOffsetY = 0;
  double _magentaOffsetX = 0;
  double _magentaOffsetY = 0;
  
  // Variables for the "slicing" effect
  double _sliceY = 0;
  double _sliceHeight = 0;
  double _sliceOffsetX = 0;
  
  Timer? _glitchTimer;
  Timer? _sliceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isGlitching) {
      _startGlitch();
    }
  }

  @override
  void didUpdateWidget(SbGlitchTextEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlitching != oldWidget.isGlitching) {
      if (widget.isGlitching) {
        _startGlitch();
      } else {
        _stopGlitch();
      }
    }
  }

  void _startGlitch() {
    // 1. Rapid color channel splitting (RGB shift)
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      
      // Usually, glitches aren't constant. They happen in bursts.
      if (_random.nextDouble() > 0.8) {
        setState(() {
          // Intense glitch
          _cyanOffsetX = (_random.nextDouble() - 0.5) * 10;
          _cyanOffsetY = (_random.nextDouble() - 0.5) * 4;
          _magentaOffsetX = (_random.nextDouble() - 0.5) * 10;
          _magentaOffsetY = (_random.nextDouble() - 0.5) * 4;
        });
      } else if (_random.nextDouble() > 0.6) {
        setState(() {
          // Mild jitter
          _cyanOffsetX = (_random.nextDouble() - 0.5) * 3;
          _cyanOffsetY = 0;
          _magentaOffsetX = (_random.nextDouble() - 0.5) * 3;
          _magentaOffsetY = 0;
        });
      } else {
        // Return to normal
        setState(() {
          _cyanOffsetX = 0;
          _cyanOffsetY = 0;
          _magentaOffsetX = 0;
          _magentaOffsetY = 0;
        });
      }
    });

    // 2. The horizontal slicing/tearing effect
    _sliceTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      
      if (_random.nextDouble() > 0.85) {
        setState(() {
          // Tear a random horizontal chunk of the text
          _sliceY = _random.nextDouble(); // 0.0 to 1.0 percent of height
          _sliceHeight = 0.1 + (_random.nextDouble() * 0.2); // 10% to 30% height
          _sliceOffsetX = (_random.nextDouble() - 0.5) * 20; // Shift left or right
        });
        
        // Reset the slice quickly after it happens
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              _sliceHeight = 0; // Hide slice
            });
          }
        });
      }
    });
  }

  void _stopGlitch() {
    _glitchTimer?.cancel();
    _sliceTimer?.cancel();
    setState(() {
      _cyanOffsetX = 0;
      _cyanOffsetY = 0;
      _magentaOffsetX = 0;
      _magentaOffsetY = 0;
      _sliceHeight = 0;
    });
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _sliceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the baseline dimensions of the text to calculate slice coordinates
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    
    final double textHeight = textPainter.size.height;
    final double textWidth = textPainter.size.width;

    return SizedBox(
      width: textWidth + 40, // padding for glitch shifting
      height: textHeight + 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // BOTTOM LAYER: Secondary Color (Magenta) shifted
          Transform.translate(
            offset: Offset(_magentaOffsetX, _magentaOffsetY),
            child: Text(
              widget.text,
              style: widget.style.copyWith(color: widget.secondaryColor),
            ),
          ),
          
          // MIDDLE LAYER: Primary Color (Cyan) shifted
          Transform.translate(
            offset: Offset(_cyanOffsetX, _cyanOffsetY),
            child: Text(
              widget.text,
              style: widget.style.copyWith(color: widget.primaryColor),
            ),
          ),
          
          // TOP LAYER: The actual white text
          Text(
            widget.text,
            style: widget.style,
          ),
          
          // SLICE LAYER: The horizontally torn chunk of text
          // We use ClipRect to only show a specific horizontal sliver of the text,
          // and then we physically translate that sliver to the side
          if (_sliceHeight > 0)
            Positioned.fill(
              child: ClipRect(
                clipper: _GlitchSliceClipper(
                  sliceTopPercent: _sliceY,
                  sliceHeightPercent: _sliceHeight,
                ),
                child: Transform.translate(
                  offset: Offset(_sliceOffsetX, 0),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // The slice also needs the RGB shifting for maximum effect
                        Transform.translate(
                          offset: Offset(_magentaOffsetX * 1.5, _magentaOffsetY),
                          child: Text(
                            widget.text,
                            style: widget.style.copyWith(color: widget.secondaryColor),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(_cyanOffsetX * 1.5, _cyanOffsetY),
                          child: Text(
                            widget.text,
                            style: widget.style.copyWith(color: widget.primaryColor),
                          ),
                        ),
                        Text(
                          widget.text,
                          style: widget.style,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlitchSliceClipper extends CustomClipper<Rect> {
  final double sliceTopPercent;
  final double sliceHeightPercent;

  _GlitchSliceClipper({
    required this.sliceTopPercent,
    required this.sliceHeightPercent,
  });

  @override
  Rect getClip(Size size) {
    final double top = size.height * sliceTopPercent;
    final double height = size.height * sliceHeightPercent;
    
    // We only clip the Y axis, leave the X axis fully open
    return Rect.fromLTWH(0, top, size.width, height);
  }

  @override
  bool shouldReclip(covariant _GlitchSliceClipper oldClipper) {
    return oldClipper.sliceTopPercent != sliceTopPercent ||
           oldClipper.sliceHeightPercent != sliceHeightPercent;
  }
}
