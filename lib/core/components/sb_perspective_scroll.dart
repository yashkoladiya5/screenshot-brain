import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbPerspectiveScroll extends StatefulWidget {
  final List<Widget> children;
  final double itemHeight;
  
  const SbPerspectiveScroll({
    super.key,
    required this.children,
    this.itemHeight = 200.0,
  });

  @override
  State<SbPerspectiveScroll> createState() => _SbPerspectiveScrollState();
}

class _SbPerspectiveScrollState extends State<SbPerspectiveScroll> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        // Find the Y position of this item relative to the viewport
        // A standard list item starts at index * itemHeight.
        // The scroll offset tells us how far down we've scrolled.
        double itemPosition = (index * widget.itemHeight) - 
            (_scrollController.hasClients ? _scrollController.offset : 0);
            
        // Find the center of the screen
        final double screenHeight = MediaQuery.of(context).size.height;
        final double screenCenter = screenHeight / 2;
        
        // Find center of this item
        final double itemCenter = itemPosition + (widget.itemHeight / 2);
        
        // Calculate distance from center (-1.0 to 1.0)
        double distanceFromCenter = (itemCenter - screenCenter) / screenCenter;
        
        // Clamp distance so it doesn't spin infinitely off screen
        distanceFromCenter = distanceFromCenter.clamp(-1.0, 1.0);
        
        // Calculate 3D rotation based on distance from center
        // At center (0.0), rotation is 0.
        // At edges (-1.0 or 1.0), rotation is max (e.g. 60 degrees)
        final double maxRotation = math.pi / 3; // 60 degrees
        final double rotation = distanceFromCenter * maxRotation;
        
        // Calculate scale and opacity to enhance the 3D effect
        final double scale = 1.0 - (distanceFromCenter.abs() * 0.2);
        final double opacity = 1.0 - (distanceFromCenter.abs() * 0.5);

        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateX(rotation) // Rotate vertically
            ..scale(scale),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: SizedBox(
              height: widget.itemHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: widget.children[index],
              ),
            ),
          ),
        );
      },
    );
  }
}
