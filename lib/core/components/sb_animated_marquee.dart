import 'package:flutter/material.dart';

class SbAnimatedMarquee extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; 
  final Duration pauseDuration;
  final double blankSpace;

  const SbAnimatedMarquee({
    super.key,
    required this.text,
    this.style,
    this.velocity = 50.0,
    this.pauseDuration = const Duration(seconds: 1),
    this.blankSpace = 50.0,
  });

  @override
  State<SbAnimatedMarquee> createState() => _SbAnimatedMarqueeState();
}

class _SbAnimatedMarqueeState extends State<SbAnimatedMarquee> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollability();
    });
  }

  void _checkScrollability() {
    if (!mounted) return;
    
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      setState(() {
        _needsScrolling = maxScrollExtent > 0;
      });
      
      if (_needsScrolling) {
        _startScrolling();
      }
    }
  }

  Future<void> _startScrolling() async {
    if (!mounted) return;

    await Future.delayed(widget.pauseDuration);
    
    if (!mounted) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final scrollDuration = Duration(
      milliseconds: ((maxScrollExtent / widget.velocity) * 1000).toInt()
    );

    await _scrollController.animateTo(
      maxScrollExtent,
      duration: scrollDuration,
      curve: Curves.linear,
    );
    
    if (!mounted) return;
    
    _scrollController.jumpTo(0.0);
    
    _startScrolling();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidget = Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.visible,
        );
        
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              textWidget,
              if (_needsScrolling) ...[
                SizedBox(width: widget.blankSpace),
                textWidget,
              ],
            ],
          ),
        );
      }
    );
  }
}
