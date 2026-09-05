import 'package:flutter/material.dart';

class SbAnimatedExpandingSearch extends StatefulWidget {
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final double expandedWidth;

  const SbAnimatedExpandingSearch({
    super.key,
    this.onSubmitted,
    this.onChanged,
    this.hintText = 'Search...',
    this.backgroundColor = const Color(0xFFF0F0F0),
    this.iconColor = Colors.grey,
    this.textColor = Colors.black87,
    this.expandedWidth = 300.0,
  });

  @override
  State<SbAnimatedExpandingSearch> createState() => _SbAnimatedExpandingSearchState();
}

class _SbAnimatedExpandingSearchState extends State<SbAnimatedExpandingSearch> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _widthAnimation = Tween<double>(
      begin: 50.0, 
      end: widget.expandedWidth,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _textController.text.isEmpty) {
        _closeSearch();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_isExpanded) {
      if (_textController.text.isNotEmpty) {
        widget.onSubmitted?.call(_textController.text);
      } else {
        _closeSearch();
      }
    } else {
      setState(() {
        _isExpanded = true;
      });
      _controller.forward();
      _focusNode.requestFocus();
    }
  }

  void _closeSearch() {
    setState(() {
      _isExpanded = false;
    });
    _controller.reverse();
    _focusNode.unfocus();
    _textController.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 50.0,
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: _isExpanded ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ] : null,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleSearch,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: Center(
                    child: Icon(
                      Icons.search,
                      color: widget.iconColor,
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: Opacity(
                  opacity: _controller.value,
                  child: IgnorePointer(
                    ignoring: !_isExpanded,
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      style: TextStyle(color: widget.textColor),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(color: widget.iconColor.withValues(alpha: 0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(right: 16.0),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (_isExpanded && _controller.value > 0.5)
                Opacity(
                  opacity: (_controller.value - 0.5) * 2, 
                  child: GestureDetector(
                    onTap: _closeSearch,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 50.0,
                      height: 50.0,
                      child: Center(
                        child: Icon(
                          Icons.close,
                          color: widget.iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}
