import 'package:flutter/material.dart';

class SbAnimatedListWrapper extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDuration;
  final Duration itemDuration;
  final Offset startOffset;

  const SbAnimatedListWrapper({
    super.key,
    required this.children,
    this.staggerDuration = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 400),
    this.startOffset = const Offset(0, 50),
  });

  @override
  State<SbAnimatedListWrapper> createState() => _SbAnimatedListWrapperState();
}

class _SbAnimatedListWrapperState extends State<SbAnimatedListWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.staggerDuration.inMilliseconds * widget.children.length + widget.itemDuration.inMilliseconds,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SbAnimatedListWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _controller.duration = Duration(
        milliseconds: widget.staggerDuration.inMilliseconds * widget.children.length + widget.itemDuration.inMilliseconds,
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        // Calculate the start and end time for this specific item's animation
        // Both knobs are public and nullable-by-value: passing Duration.zero
        // to skip the animation made the total zero, and dividing by it
        // produced NaN intervals that Interval asserts on.
        final totalMs = _controller.duration!.inMilliseconds;
        if (totalMs <= 0) {
          return widget.children[index];
        }
        final double start = (widget.staggerDuration.inMilliseconds * index) / totalMs;
        final double end = start + (widget.itemDuration.inMilliseconds / totalMs);
        
        final Animation<double> opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          ),
        );
        
        final Animation<Offset> slideAnim = Tween<Offset>(
          begin: widget.startOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          ),
        );

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: opacityAnim.value,
              child: Transform.translate(
                offset: slideAnim.value,
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      },
    );
  }
}
