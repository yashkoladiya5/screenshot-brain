import 'package:flutter/material.dart';

class SbStretchyHeader extends StatefulWidget {
  final Widget header;
  final Widget body;
  final double expandedHeight;
  final double collapsedHeight;

  const SbStretchyHeader({
    super.key,
    required this.header,
    required this.body,
    this.expandedHeight = 250.0,
    this.collapsedHeight = kToolbarHeight + 40.0, // Default appbar + some padding
  });

  @override
  State<SbStretchyHeader> createState() => _SbStretchyHeaderState();
}

class _SbStretchyHeaderState extends State<SbStretchyHeader> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When scrollOffset is negative, we are overscrolling the top
    final double overscroll = _scrollOffset < 0 ? _scrollOffset.abs() : 0.0;
    
    // Total height of the header area changes if we overscroll
    final double currentHeaderHeight = (widget.expandedHeight + overscroll).clamp(
      widget.collapsedHeight, 
      double.infinity
    );
    
    // Scale factor for the background image/widget to make it zoom in as it stretches
    final double scale = 1.0 + (overscroll / widget.expandedHeight);
    
    // How much the header should slide up under the status bar when scrolling down
    final double headerTranslationY = _scrollOffset > 0 
        ? -_scrollOffset.clamp(0.0, widget.expandedHeight - widget.collapsedHeight)
        : 0.0;

    return Stack(
      children: [
        // 1. The Scrollable Body Content
        // We push the content down by the expandedHeight so it starts below the header
        ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.only(top: widget.expandedHeight),
          children: [
            widget.body,
          ],
        ),

        // 2. The Stretchy Header
        Positioned(
          top: headerTranslationY,
          left: 0,
          right: 0,
          height: currentHeaderHeight,
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: widget.header,
            ),
          ),
        ),
      ],
    );
  }
}
