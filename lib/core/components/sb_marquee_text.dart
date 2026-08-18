import 'package:flutter/material.dart';

class SbMarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // Pixels per second
  final double blankSpace;

  const SbMarqueeText({
    super.key,
    required this.text,
    this.style,
    this.velocity = 30.0,
    this.blankSpace = 50.0,
  });

  @override
  State<SbMarqueeText> createState() => _SbMarqueeTextState();
}

class _SbMarqueeTextState extends State<SbMarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  final _key = GlobalKey();

  double _textWidth = 0.0;
  bool _needsScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateScroll();
    });
  }

  @override
  void didUpdateWidget(covariant SbMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.velocity != widget.velocity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateScroll();
      });
    }
  }

  void _calculateScroll() {
    if (!mounted) return;
    
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final containerWidth = renderBox.size.width;
      
      // Calculate text width
      final textPainter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      
      _textWidth = textPainter.size.width;
      
      setState(() {
        _needsScroll = _textWidth > containerWidth;
      });

      if (_needsScroll) {
        _startAnimation();
      } else {
        _animationController.stop();
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    }
  }

  void _startAnimation() {
    _animationController.stop();
    _animationController.reset();

    // Duration based on velocity
    final distance = _textWidth + widget.blankSpace;
    final durationSeconds = distance / widget.velocity;
    
    _animationController.duration = Duration(milliseconds: (durationSeconds * 1000).toInt());
    
    _animationController.forward().then((_) {
      if (mounted && _needsScroll) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        _startAnimation();
      }
    });

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_animationController.value * distance);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: _key,
      builder: (context, constraints) {
        if (!_needsScroll) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.clip,
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              Text(widget.text, style: widget.style),
              SizedBox(width: widget.blankSpace),
              Text(widget.text, style: widget.style),
            ],
          ),
        );
      },
    );
  }
}
