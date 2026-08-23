import 'package:flutter/material.dart';
import 'dart:async';

class SbScrollingTextTicker extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // Pixels per second
  final double blankSpace;

  const SbScrollingTextTicker({
    super.key,
    required this.text,
    this.style,
    this.velocity = 50.0,
    this.blankSpace = 50.0,
  });

  @override
  State<SbScrollingTextTicker> createState() => _SbScrollingTextTickerState();
}

class _SbScrollingTextTickerState extends State<SbScrollingTextTicker> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (_isScrolling || !mounted) return;
    _isScrolling = true;
    _scroll();
  }

  void _scroll() {
    if (!_scrollController.hasClients || !mounted) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final currentPosition = _scrollController.position.pixels;
    
    // If the text is shorter than the viewport, don't scroll
    if (maxExtent <= 0) {
      _isScrolling = false;
      return;
    }

    final distanceToScroll = maxExtent - currentPosition;
    final durationSeconds = distanceToScroll / widget.velocity;

    _scrollController.animateTo(
      maxExtent,
      duration: Duration(milliseconds: (durationSeconds * 1000).toInt()),
      curve: Curves.linear,
    ).then((_) {
      if (!mounted) return;
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _scrollController.jumpTo(0);
          _scroll();
        }
      });
    });
  }

  @override
  void didUpdateWidget(SbScrollingTextTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _scrollController.jumpTo(0);
      _isScrolling = false;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startScrolling();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: widget.style ?? Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(width: widget.blankSpace),
          Text(
            widget.text,
            style: widget.style ?? Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
