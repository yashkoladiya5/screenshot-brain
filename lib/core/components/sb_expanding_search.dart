import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbExpandingSearch extends StatefulWidget {
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final Color activeColor;
  final Color inactiveColor;

  const SbExpandingSearch({
    super.key,
    this.onSubmitted,
    this.onChanged,
    this.hintText = 'Search...',
    this.activeColor = Colors.blueAccent,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<SbExpandingSearch> createState() => _SbExpandingSearchState();
}

class _SbExpandingSearchState extends State<SbExpandingSearch> with SingleTickerProviderStateMixin {
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

    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _textController.text.isEmpty && _isExpanded) {
        _toggleExpand();
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

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        _focusNode.requestFocus();
      } else {
        _controller.reverse();
        _focusNode.unfocus();
        _textController.clear();
        if (widget.onChanged != null) widget.onChanged!('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Assume maximum width if unconstrained, otherwise use constraint
        final double maxWidth = constraints.maxWidth == double.infinity ? 300.0 : constraints.maxWidth;
        final double minWidth = 56.0; // Size of the closed circle button

        return AnimatedBuilder(
          animation: _widthAnimation,
          builder: (context, child) {
            final double currentWidth = minWidth + (_widthAnimation.value * (maxWidth - minWidth));
            final Color currentColor = Color.lerp(widget.inactiveColor, widget.activeColor, _widthAnimation.value) ?? widget.inactiveColor;

            return Container(
              width: currentWidth,
              height: 56.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.0), // Always fully rounded ends
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.2 + (_widthAnimation.value * 0.1)),
                    blurRadius: 10.0 + (_widthAnimation.value * 10.0),
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: currentColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // TextField (Fades and slides in)
                  Positioned(
                    left: 56.0, // Start text right after the search icon
                    right: 56.0, // Leave room for close button
                    top: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: _widthAnimation.value,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - _widthAnimation.value), 0),
                        child: Center(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Search Icon (Always on left)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 56.0,
                    child: GestureDetector(
                      onTap: _isExpanded ? null : _toggleExpand,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.search,
                            key: ValueKey(_isExpanded),
                            color: currentColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Close Icon (Fades in on the right)
                  if (_widthAnimation.value > 0.1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 56.0,
                      child: Opacity(
                        opacity: _widthAnimation.value,
                        child: GestureDetector(
                          onTap: _toggleExpand,
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Icon(
                              Icons.close,
                              color: widget.inactiveColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
