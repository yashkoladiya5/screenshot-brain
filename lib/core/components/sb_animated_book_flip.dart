import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbAnimatedBookFlip extends StatefulWidget {
  final List<Widget> pages;
  final double width;
  final double height;
  final Color coverColor;
  final Color pageColor;

  const SbAnimatedBookFlip({
    super.key,
    required this.pages,
    this.width = 300.0,
    this.height = 400.0,
    this.coverColor = const Color(0xFF8B4513), // Saddle brown leather
    this.pageColor = const Color(0xFFFDF5E6), // Old paper
  }) : assert(pages.length > 1, 'A book needs at least 2 pages');

  @override
  State<SbAnimatedBookFlip> createState() => _SbAnimatedBookFlipState();
}

class _SbAnimatedBookFlipState extends State<SbAnimatedBookFlip> with TickerProviderStateMixin {
  int _currentPageIndex = 0;
  
  // Controls the 3D flip animation of the current page
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  bool _isFlippingForward = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // We use a custom curve to make the flip feel weighty
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_isFlippingForward) {
            _currentPageIndex++;
          } else {
            _currentPageIndex--;
          }
        });
        _flipController.reset();
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPageIndex < widget.pages.length - 1 && !_flipController.isAnimating) {
      setState(() {
        _isFlippingForward = true;
      });
      _flipController.forward(from: 0.0);
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0 && !_flipController.isAnimating) {
      setState(() {
        _isFlippingForward = false;
      });
      _flipController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -300) {
          _nextPage();
        } else if (details.primaryVelocity! > 300) {
          _previousPage();
        }
      },
      child: Center(
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.coverColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(10, 10),
              ),
              // Spine shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 5,
                offset: const Offset(-2, 0),
              )
            ]
          ),
          child: Stack(
            children: [
              // 1. The Right Side (Next Page content)
              if (_currentPageIndex < widget.pages.length - 1)
                Positioned.fill(
                  left: 10, // Spine padding
                  top: 5,
                  bottom: 5,
                  right: 5,
                  child: _buildStaticPage(widget.pages[_currentPageIndex + 1]),
                ),

              // 2. The Left Side (Previous Page content - revealed when flipping backward)
              // Since we only show the right side of the book in this design, 
              // the "previous page" is what you see when you flip backwards.
              if (!_isFlippingForward && _currentPageIndex > 0)
                Positioned.fill(
                  left: 10,
                  top: 5,
                  bottom: 5,
                  right: 5,
                  child: _buildStaticPage(widget.pages[_currentPageIndex - 1]),
                ),
                
              // 3. The Current Static Page (visible when not animating)
              if (!_flipController.isAnimating)
                Positioned.fill(
                  left: 10,
                  top: 5,
                  bottom: 5,
                  right: 5,
                  child: _buildStaticPage(widget.pages[_currentPageIndex]),
                ),

              // 4. The 3D Animated Flipping Page
              if (_flipController.isAnimating)
                Positioned.fill(
                  left: 10,
                  top: 5,
                  bottom: 5,
                  right: 5,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      // If flipping forward, angle goes from 0 to -pi (folds left)
                      // If flipping backward, angle goes from -pi to 0 (unfolds right)
                      double angle = _isFlippingForward
                          ? -math.pi * _flipAnimation.value
                          : -math.pi * (1.0 - _flipAnimation.value);

                      // To prevent z-fighting and rendering issues when exactly at 90 degrees
                      if (angle == -math.pi / 2) angle += 0.001;

                      // Determine which side of the page is currently visible to the camera
                      bool isFrontVisible = angle > -math.pi / 2;

                      // Matrix math to create 3D rotation anchored at the left edge (the spine)
                      final Matrix4 transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.002) // Perspective distortion
                        ..rotateY(angle); // Rotate around Y axis

                      // Shadow math: As the page lifts up (angle approaches -pi/2), the shadow gets larger and softer
                      final double shadowIntensity = math.sin(angle.abs());
                      
                      return Transform(
                        transform: transform,
                        alignment: Alignment.centerLeft, // Anchor to the spine
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.pageColor,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3 * shadowIntensity),
                                blurRadius: 20 * shadowIntensity,
                                offset: Offset(20 * shadowIntensity, 10 * shadowIntensity),
                              )
                            ]
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // The actual content. If we're looking at the back of the page, we hide it.
                              if (isFrontVisible)
                                widget.pages[_isFlippingForward ? _currentPageIndex : _currentPageIndex - 1],
                                
                              // If looking at the back of the page, we show a blank page (or the back content)
                              // We have to mirror it so it doesn't render backwards in 3D space
                              if (!isFrontVisible)
                                Transform(
                                  transform: Matrix4.rotationY(math.pi),
                                  alignment: Alignment.center,
                                  child: Container(
                                    color: widget.pageColor,
                                    child: Center(
                                      child: Text(
                                        'Page ${_isFlippingForward ? _currentPageIndex + 1 : _currentPageIndex}',
                                        style: TextStyle(color: Colors.black.withValues(alpha: 0.2)),
                                      ),
                                    ),
                                  ),
                                ),
                                
                              // Dynamic lighting overlay
                              // Creates a gradient shadow that simulates a page bending under a light source
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.1 + (0.3 * (1.0 - shadowIntensity))), // Spine shadow
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.2 * shadowIntensity), // Highlight on the bend
                                      Colors.black.withValues(alpha: isFrontVisible ? 0.0 : 0.2), // Backside shadow
                                    ],
                                    stops: const [0.0, 0.4, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
              // Page turn hint (dog-ear corner)
              if (!_flipController.isAnimating && _currentPageIndex < widget.pages.length - 1)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: CustomPaint(
                    size: const Size(30, 30),
                    painter: _DogEarPainter(color: widget.pageColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticPage(Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: widget.pageColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1), // Page edge separation
        )
      ),
      child: content,
    );
  }
}

class _DogEarPainter extends CustomPainter {
  final Color color;

  _DogEarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
      
    // Shadow under the fold
    canvas.drawShadow(path, Colors.black, 4.0, false);
    
    final Paint paint = Paint()
      ..color = Colors.white // The underside of the page
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(path, paint);
    
    // Add a gradient to the fold to make it look 3D
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.black.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _DogEarPainter oldDelegate) {
    return false;
  }
}
