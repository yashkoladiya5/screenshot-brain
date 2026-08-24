import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbExpandingSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double maxWidth;
  final double collapsedWidth;

  const SbExpandingSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.maxWidth = 300.0,
    this.collapsedWidth = 48.0,
  });

  @override
  State<SbExpandingSearchBar> createState() => _SbExpandingSearchBarState();
}

class _SbExpandingSearchBarState extends State<SbExpandingSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  bool _isExpanded = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: widget.maxWidth,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.controller.text.isEmpty) {
        _collapse();
      }
    });
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    _focusNode.requestFocus();
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: widget.collapsedWidth,
          decoration: BoxDecoration(
            color: _isExpanded ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(SBRadius.full),
            border: _isExpanded ? Border.all(color: colorScheme.outlineVariant) : null,
            boxShadow: _isExpanded 
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _isExpanded ? null : _expand,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: widget.collapsedWidth,
                  height: widget.collapsedWidth,
                  decoration: BoxDecoration(
                    color: _isExpanded ? Colors.transparent : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: _isExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              if (_widthAnimation.value > widget.collapsedWidth + 20)
                Expanded(
                  child: Opacity(
                    opacity: (_widthAnimation.value - widget.collapsedWidth) / (widget.maxWidth - widget.collapsedWidth),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: widget.onChanged,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isExpanded && widget.controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
                    _collapse();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
