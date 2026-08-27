import 'package:flutter/material.dart';
import 'dart:ui';
import '../design/tokens.dart';

class SbFrostedGlassTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final double height;
  final double blurSigma;
  final Color? activeTabColor;
  final Color? inactiveTabColor;
  final Color? indicatorColor;

  const SbFrostedGlassTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.height = 60.0,
    this.blurSigma = 15.0,
    this.activeTabColor,
    this.inactiveTabColor,
    this.indicatorColor,
  }) : assert(tabs.length > 0);

  @override
  State<SbFrostedGlassTabBar> createState() => _SbFrostedGlassTabBarState();
}

class _SbFrostedGlassTabBarState extends State<SbFrostedGlassTabBar> {
  // Store the keys of each tab to calculate exact widths and positions for the sliding indicator
  final List<GlobalKey> _tabKeys = [];
  double _indicatorPosition = 0.0;
  double _indicatorWidth = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.tabs.length; i++) {
      _tabKeys.add(GlobalKey());
    }
    
    // We need to wait for the first frame to measure the text widths
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicator(widget.selectedIndex);
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void didUpdateWidget(SbFrostedGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the tabs changed completely, we need to rebuild the keys
    if (widget.tabs.length != oldWidget.tabs.length) {
      _tabKeys.clear();
      for (int i = 0; i < widget.tabs.length; i++) {
        _tabKeys.add(GlobalKey());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateIndicator(widget.selectedIndex);
      });
    } else if (widget.selectedIndex != oldWidget.selectedIndex && _isInitialized) {
      _updateIndicator(widget.selectedIndex);
    }
  }

  void _updateIndicator(int index) {
    if (index < 0 || index >= _tabKeys.length) return;
    
    final key = _tabKeys[index];
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    
    if (renderBox != null) {
      // Find the position relative to the Row (which is the parent)
      final RenderBox? parentBox = context.findRenderObject() as RenderBox?;
      if (parentBox != null) {
        final position = renderBox.localToGlobal(Offset.zero, ancestor: parentBox);
        setState(() {
          _indicatorPosition = position.dx;
          _indicatorWidth = renderBox.size.width;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final activeColor = widget.activeTabColor ?? theme.colorScheme.onSurface;
    final inactiveColor = widget.inactiveTabColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final highlight = widget.indicatorColor ?? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SBRadius.full),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SBRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
          child: Container(
            color: theme.colorScheme.surface.withValues(alpha: 0.3), // Highly translucent base
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Stack(
              children: [
                // Animated Sliding Indicator Background
                if (_isInitialized)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: _indicatorPosition - 4, // Subtract padding
                    top: 0,
                    bottom: 0,
                    width: _indicatorWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(SBRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                  
                // The actual Tab Text Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.tabs.length, (index) {
                    final bool isSelected = widget.selectedIndex == index;
                    return GestureDetector(
                      onTap: () => widget.onTabChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        key: _tabKeys[index],
                        padding: const EdgeInsets.symmetric(horizontal: SBSpacing.xl),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          style: theme.textTheme.titleSmall!.copyWith(
                            color: isSelected ? activeColor : inactiveColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          child: Text(widget.tabs[index]),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
