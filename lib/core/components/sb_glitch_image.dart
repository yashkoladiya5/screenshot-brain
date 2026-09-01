import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbGlitchImage extends StatefulWidget {
  final ImageProvider imageProvider;
  final double width;
  final double height;
  final bool isGlitching;
  final Duration glitchFrequency;

  const SbGlitchImage({
    super.key,
    required this.imageProvider,
    this.width = double.infinity,
    this.height = 300.0,
    this.isGlitching = true,
    this.glitchFrequency = const Duration(milliseconds: 200),
  });

  @override
  State<SbGlitchImage> createState() => _SbGlitchImageState();
}

class _SbGlitchImageState extends State<SbGlitchImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.glitchFrequency,
    );

    if (widget.isGlitching) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SbGlitchImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlitching != oldWidget.isGlitching) {
      if (widget.isGlitching) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!widget.isGlitching) {
            return Image(
              image: widget.imageProvider,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
            );
          }

          // Randomize glitch parameters on every frame
          final double cyanOffsetX = (_random.nextDouble() - 0.5) * 10;
          final double redOffsetX = (_random.nextDouble() - 0.5) * 10;
          
          final double sliceTop = _random.nextDouble(); // 0.0 to 1.0 percentage
          final double sliceHeight = _random.nextDouble() * 0.2; // Max 20% slice height
          final double sliceOffsetX = (_random.nextDouble() - 0.5) * 20;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Cyan channel shift
              Transform.translate(
                offset: Offset(cyanOffsetX, 0),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.cyan, Colors.cyan],
                  ).createShader(bounds),
                  child: Image(
                    image: widget.imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // 2. Red channel shift
              Transform.translate(
                offset: Offset(redOffsetX, 0),
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.red, Colors.red],
                  ).createShader(bounds),
                  child: Image(
                    image: widget.imageProvider,
                    fit: BoxFit.cover,
                    // Use a blend mode that combines the colors correctly
                    colorBlendMode: BlendMode.screen,
                  ),
                ),
              ),

              // 3. The main image sliced
              ClipPath(
                clipper: _GlitchClipper(sliceTop: sliceTop, sliceHeight: sliceHeight, invert: true),
                child: Image(
                  image: widget.imageProvider,
                  fit: BoxFit.cover,
                ),
              ),

              // 4. The shifted slice
              Transform.translate(
                offset: Offset(sliceOffsetX, 0),
                child: ClipPath(
                  clipper: _GlitchClipper(sliceTop: sliceTop, sliceHeight: sliceHeight, invert: false),
                  child: Image(
                    image: widget.imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlitchClipper extends CustomClipper<Path> {
  final double sliceTop;
  final double sliceHeight;
  final bool invert;

  _GlitchClipper({
    required this.sliceTop,
    required this.sliceHeight,
    required this.invert,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final double topY = size.height * sliceTop;
    final double bottomY = topY + (size.height * sliceHeight);

    if (invert) {
      // Cut OUT the slice
      path.addRect(Rect.fromLTWH(0, 0, size.width, topY));
      path.addRect(Rect.fromLTWH(0, bottomY, size.width, size.height - bottomY));
    } else {
      // KEEP ONLY the slice
      path.addRect(Rect.fromLTWH(0, topY, size.width, bottomY - topY));
    }

    return path;
  }

  @override
  bool shouldReclip(covariant _GlitchClipper oldClipper) {
    return oldClipper.sliceTop != sliceTop || 
           oldClipper.sliceHeight != sliceHeight || 
           oldClipper.invert != invert;
  }
}
