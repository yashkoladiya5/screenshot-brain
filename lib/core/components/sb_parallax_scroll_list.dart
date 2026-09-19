import 'package:flutter/material.dart';

class SbParallaxScrollList extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> titles;
  final double itemHeight;

  const SbParallaxScrollList({
    super.key,
    required this.imageUrls,
    required this.titles,
    this.itemHeight = 250.0,
  });

  @override
  State<SbParallaxScrollList> createState() => _SbParallaxScrollListState();
}

class _SbParallaxScrollListState extends State<SbParallaxScrollList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
      itemCount: widget.imageUrls.length,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _ParallaxListItem(
            imageUrl: widget.imageUrls[index],
            title: widget.titles.length > index ? widget.titles[index] : '',
            itemHeight: widget.itemHeight,
            // We pass the scrollable's scrollableState down so the item can listen to it
            // Or we just rely on AnimatedBuilder internally listening to Scrollable.of(context)
          ),
        );
      },
    );
  }
}

class _ParallaxListItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double itemHeight;
  final GlobalKey _backgroundImageKey = GlobalKey();

  _ParallaxListItem({
    required this.imageUrl,
    required this.title,
    required this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: itemHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The parallax image layer
          Positioned.fill(
            child: _ParallaxImage(
              imageUrl: imageUrl,
              backgroundImageKey: _backgroundImageKey,
            ),
          ),
          
          // A gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // The Title text
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParallaxImage extends StatefulWidget {
  final String imageUrl;
  final GlobalKey backgroundImageKey;

  const _ParallaxImage({
    required this.imageUrl,
    required this.backgroundImageKey,
  });

  @override
  State<_ParallaxImage> createState() => _ParallaxImageState();
}

class _ParallaxImageState extends State<_ParallaxImage> {
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We get the Scrollable state from the ancestor ListView
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      if (_scrollPosition != scrollable.position) {
        // Remove old listener if it exists
        _scrollPosition?.removeListener(_onScroll);
        _scrollPosition = scrollable.position;
        // Add new listener
        _scrollPosition?.addListener(_onScroll);
      }
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Only rebuild if the widget is mounted
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Flow(
      delegate: _ParallaxFlowDelegate(
        scrollable: Scrollable.maybeOf(context),
        listItemContext: context,
        backgroundImageKey: widget.backgroundImageKey,
      ),
      children: [
        Image.network(
          widget.imageUrl,
          key: widget.backgroundImageKey,
          fit: BoxFit.cover,
        ),
      ],
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  final ScrollableState? scrollable;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;

  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.backgroundImageKey,
  }) : super(repaint: scrollable?.position);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    // We force the image to be taller than the container to give it room to scroll
    return BoxConstraints.tightFor(
      width: constraints.maxWidth,
      height: constraints.maxHeight * 1.5, // 50% taller than the item
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of this list item within the viewport
    final scrollableBox = scrollable?.context.findRenderObject() as RenderBox?;
    final listItemBox = listItemContext.findRenderObject() as RenderBox?;
    
    if (scrollableBox != null && listItemBox != null) {
      // Get the Y offset of this item relative to the scrollable viewport
      final listItemOffset = listItemBox.localToGlobal(
          listItemBox.size.centerLeft(Offset.zero),
          ancestor: scrollableBox);

      // Determine percentage position (0.0 is top of viewport, 1.0 is bottom)
      final viewportDimension = scrollable!.position.viewportDimension;
      final scrollFraction = (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);

      // Calculate the vertical alignment for the image based on the scroll fraction
      // The image is taller than the container, so we shift it up/down based on scroll
      final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);
      
      // Calculate how many pixels we need to shift the image internally
      // context.size is the size of the Flow widget (the list item)
      // context.getChildSize(0) is the size of the Image (taller than the list item)
      final backgroundSize = context.getChildSize(0)!;
      final listItemSize = context.size;
      
      final childRect = verticalAlignment.inscribe(
          backgroundSize, Offset.zero & listItemSize);

      context.paintChild(
        0,
        transform: Transform.translate(
          offset: Offset(0.0, childRect.top),
        ).transform,
      );
    } else {
      // Fallback if render objects aren't ready
      context.paintChild(0);
    }
  }

  @override
  bool shouldRepaint(covariant _ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
           listItemContext != oldDelegate.listItemContext ||
           backgroundImageKey != oldDelegate.backgroundImageKey;
  }
}
