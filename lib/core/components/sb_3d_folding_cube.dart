import 'package:flutter/material.dart';
import 'dart:math' as math;

class Sb3dFoldingCube extends StatefulWidget {
  final double size;
  final List<Widget> faces; // Exactly 6 faces required
  
  const Sb3dFoldingCube({
    super.key,
    this.size = 200.0,
    required this.faces,
  }) : assert(faces.length == 6, 'A cube must have exactly 6 faces');

  @override
  State<Sb3dFoldingCube> createState() => _Sb3dFoldingCubeState();
}

class _Sb3dFoldingCubeState extends State<Sb3dFoldingCube> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Interactive rotation variables
  double _rx = math.pi / 4; // Initial tilt
  double _ry = math.pi / 4; // Initial spin

  @override
  void initState() {
    super.initState();
    // Controls the "folding" animation (0.0 = flat net, 1.0 = folded cube)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Auto-fold on start
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _ry -= details.delta.dx * 0.01;
      _rx += details.delta.dy * 0.01;
    });
  }
  
  void _toggleFold() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onDoubleTap: _toggleFold,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double foldProgress = Curves.easeInOutCubic.transform(_controller.value);
            
            // At foldProgress 0.0, it's a flat cross (the net of a cube)
            // At foldProgress 1.0, it's a fully folded 3D cube
            final double foldAngle = foldProgress * (math.pi / 2); // Folds up to 90 degrees
            
            // Base Transform for the entire object (for interactive spinning)
            final Matrix4 baseTransform = Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective distortion
              ..rotateX(_rx)
              ..rotateY(_ry);

            return Transform(
              transform: baseTransform,
              alignment: FractionalOffset.center,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // To build the cube, we treat Face 0 as the bottom base of the cross
                    // All other faces are chained off of it or its neighbors.
                    // Instead of a true hierarchy (which requires complex recursive Transforms),
                    // we can mathematically calculate the absolute transform for each face from the center.

                    // FACE 0: BOTTOM (The static anchor)
                    _buildFace(
                      index: 0,
                      transform: Matrix4.identity()
                        ..translate(0.0, 0.0, widget.size / 2 * foldProgress), 
                        // It pushes out along Z as it folds to keep the cube centered
                    ),
                    
                    // FACE 1: FRONT (Folds up from Bottom's top edge)
                    _buildFace(
                      index: 1,
                      transform: Matrix4.identity()
                        ..translate(0.0, -widget.size / 2, widget.size / 2 * foldProgress) // Move to top edge
                        ..rotateX(foldAngle) // Fold it
                        ..translate(0.0, widget.size / 2, 0.0), // Move pivot back
                    ),
                    
                    // FACE 2: BACK (Folds up from Bottom's bottom edge)
                    _buildFace(
                      index: 2,
                      transform: Matrix4.identity()
                        ..translate(0.0, widget.size / 2, widget.size / 2 * foldProgress)
                        ..rotateX(-foldAngle)
                        ..translate(0.0, -widget.size / 2, 0.0),
                    ),
                    
                    // FACE 3: LEFT (Folds up from Bottom's left edge)
                    _buildFace(
                      index: 3,
                      transform: Matrix4.identity()
                        ..translate(-widget.size / 2, 0.0, widget.size / 2 * foldProgress)
                        ..rotateY(-foldAngle)
                        ..translate(widget.size / 2, 0.0, 0.0),
                    ),
                    
                    // FACE 4: RIGHT (Folds up from Bottom's right edge)
                    _buildFace(
                      index: 4,
                      transform: Matrix4.identity()
                        ..translate(widget.size / 2, 0.0, widget.size / 2 * foldProgress)
                        ..rotateY(foldAngle)
                        ..translate(-widget.size / 2, 0.0, 0.0),
                    ),
                    
                    // FACE 5: TOP (Chained off the FRONT face)
                    // It folds off the front face, so its angle is 2x the fold angle
                    _buildFace(
                      index: 5,
                      transform: Matrix4.identity()
                        ..translate(0.0, -widget.size / 2, widget.size / 2 * foldProgress) // Anchor to Front's top
                        ..rotateX(foldAngle) // First fold (Front)
                        ..translate(0.0, -widget.size, 0.0) // Move to top edge of Front
                        ..rotateX(foldAngle) // Second fold (Top)
                        ..translate(0.0, widget.size / 2, 0.0), // Move pivot
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFace({required int index, required Matrix4 transform}) {
    // To make it look like a physical box with shading, we calculate a dynamic lighting shadow
    // based on the face's absolute normal vector relative to a static light source.
    // For simplicity, we just use a hardcoded color shading trick.
    
    final List<Color> shadingColors = [
      Colors.black.withValues(alpha: 0.1), // Bottom
      Colors.black.withValues(alpha: 0.0), // Front
      Colors.black.withValues(alpha: 0.4), // Back
      Colors.black.withValues(alpha: 0.3), // Left
      Colors.black.withValues(alpha: 0.2), // Right
      Colors.black.withValues(alpha: 0.0), // Top
    ];

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withValues(alpha: 0.5), width: 1.0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.faces[index],
            
            // Shading overlay
            Container(color: shadingColors[index]),
            
            // Debug text just so we can see which face is which during folding
            // Center(
            //   child: Text('Face $index', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            // ),
          ],
        ),
      ),
    );
  }
}
