import 'package:flutter/material.dart';

class SbParallaxImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double parallaxFactor;

  const SbParallaxImage({
    super.key,
    required this.imageUrl,
    this.height = 250.0,
    this.parallaxFactor = 0.2,
  }) : assert(parallaxFactor >= 0.0 && parallaxFactor <= 1.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Flow(
              delegate: _ParallaxFlowDelegate(
                scrollable: Scrollable.of(context),
                listItemContext: context,
                parallaxFactor: parallaxFactor,
              ),
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: constraints.maxWidth,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  final ScrollableState scrollable;
  final BuildContext listItemContext;
  final double parallaxFactor;

  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.parallaxFactor,
  }) : super(repaint: scrollable.position);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      // Make the image slightly taller than the container to allow for parallax scrolling
      height: constraints.maxHeight + (constraints.maxHeight * parallaxFactor * 2),
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of the list item within the viewport
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final listItemBox = listItemContext.findRenderObject() as RenderBox;
    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    // Determine the percent position of the list item within the scrollable area
    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction = (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);

    // Calculate the vertical alignment based on the scroll fraction
    // scrollFraction 0.0 -> Alignment.top (parallaxFactor)
    // scrollFraction 0.5 -> Alignment.center (0.0)
    // scrollFraction 1.0 -> Alignment.bottom (-parallaxFactor)
    final verticalAlignment = (0.5 - scrollFraction) * parallaxFactor * 2;

    // Convert the alignment into a pixel offset
    final childHeight = context.getChildSize(0)!.height;
    final containerHeight = context.size.height;
    final yOffset = ((containerHeight - childHeight) / 2) + (childHeight * verticalAlignment / 2);

    context.paintChild(
      0,
      transform: Matrix4.translationValues(0.0, yOffset, 0.0),
    );
  }

  @override
  bool shouldRepaint(covariant _ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
           listItemContext != oldDelegate.listItemContext ||
           parallaxFactor != oldDelegate.parallaxFactor;
  }
}
