import 'package:flutter/material.dart';

class SbAnimatedStretchyHeader extends StatefulWidget {
  final Widget header;
  final Widget body;
  final double expandedHeight;
  final double collapsedHeight;

  const SbAnimatedStretchyHeader({
    super.key,
    required this.header,
    required this.body,
    this.expandedHeight = 300.0,
    this.collapsedHeight = kToolbarHeight,
  });

  @override
  State<SbAnimatedStretchyHeader> createState() => _SbAnimatedStretchyHeaderState();
}

class _SbAnimatedStretchyHeaderState extends State<SbAnimatedStretchyHeader> {
  late ScrollController _scrollController;
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _offset = _scrollController.offset;
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
    double currentHeight = widget.expandedHeight;
    double scale = 1.0;
    
    if (_offset < 0) {
      currentHeight = widget.expandedHeight + _offset.abs();
      scale = 1.0 + (_offset.abs() / widget.expandedHeight);
    } else {
      currentHeight = (widget.expandedHeight - _offset).clamp(
        widget.collapsedHeight, 
        widget.expandedHeight
      );
    }

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: currentHeight,
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomCenter,
              child: widget.header,
            ),
          ),
        ),
        
        Positioned.fill(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: widget.expandedHeight),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: widget.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
