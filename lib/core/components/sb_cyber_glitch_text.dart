import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbCyberGlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool isGlitching;

  const SbCyberGlitchText({
    super.key,
    required this.text,
    required this.style,
    this.isGlitching = true,
  });

  @override
  State<SbCyberGlitchText> createState() => _SbCyberGlitchTextState();
}

class _SbCyberGlitchTextState extends State<SbCyberGlitchText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    if (widget.isGlitching) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SbCyberGlitchText oldWidget) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.isGlitching || _controller.value == 0) {
          return Text(widget.text, style: widget.style);
        }

        final double intensity = _random.nextDouble() * 4.0 * _controller.value;
        final double sliceY = _random.nextDouble() * 50; 
        final double sliceHeight = _random.nextDouble() * 10 + 2; 

        return Stack(
          alignment: Alignment.center,
          children: [
            // Cyan channel shifted left
            Transform.translate(
              offset: Offset(-intensity, 0),
              child: Text(
                widget.text,
                style: widget.style.copyWith(
                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                ),
              ),
            ),
            
            // Red channel shifted right
            Transform.translate(
              offset: Offset(intensity, 0),
              child: Text(
                widget.text,
                style: widget.style.copyWith(
                  color: Colors.redAccent.withValues(alpha: 0.8),
                ),
              ),
            ),
            
            // The main text, with a random horizontal slice shifted
            ClipPath(
              clipper: _GlitchSliceClipper(sliceY: sliceY, sliceHeight: sliceHeight),
              child: Transform.translate(
                offset: Offset(_random.nextDouble() * 8 - 4, 0),
                child: Text(
                  widget.text,
                  style: widget.style,
                ),
              ),
            ),
            
            // The rest of the main text
            ClipPath(
              clipper: _GlitchInverseSliceClipper(sliceY: sliceY, sliceHeight: sliceHeight),
              child: Text(
                widget.text,
                style: widget.style,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlitchSliceClipper extends CustomClipper<Path> {
  final double sliceY;
  final double sliceHeight;

  _GlitchSliceClipper({required this.sliceY, required this.sliceHeight});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, sliceY, size.width, sliceHeight));
  }

  @override
  bool shouldReclip(covariant _GlitchSliceClipper oldClipper) {
    return oldClipper.sliceY != sliceY || oldClipper.sliceHeight != sliceHeight;
  }
}

class _GlitchInverseSliceClipper extends CustomClipper<Path> {
  final double sliceY;
  final double sliceHeight;

  _GlitchInverseSliceClipper({required this.sliceY, required this.sliceHeight});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, sliceY)) 
      ..addRect(Rect.fromLTWH(0, sliceY + sliceHeight, size.width, size.height - (sliceY + sliceHeight))); 
  }

  @override
  bool shouldReclip(covariant _GlitchInverseSliceClipper oldClipper) {
    return oldClipper.sliceY != sliceY || oldClipper.sliceHeight != sliceHeight;
  }
}
