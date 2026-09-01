import 'package:flutter/material.dart';

class SbAnimatedPillNavBar extends StatefulWidget {
  final List<SbNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const SbAnimatedPillNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.backgroundColor = Colors.white,
    this.activeColor = const Color(0xFF6200EE),
    this.inactiveColor = Colors.grey,
  });

  @override
  State<SbAnimatedPillNavBar> createState() => _SbAnimatedPillNavBarState();
}

class _SbAnimatedPillNavBarState extends State<SbAnimatedPillNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.items.length, (index) {
          final isSelected = widget.currentIndex == index;
          final item = widget.items[index];

          return GestureDetector(
            onTap: () => widget.onItemSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isSelected ? widget.activeColor.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.activeIcon ?? item.icon : item.icon,
                    color: isSelected ? widget.activeColor : widget.inactiveColor,
                    size: 24,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(
                      width: isSelected ? null : 0,
                      child: Padding(
                        padding: EdgeInsets.only(left: isSelected ? 8.0 : 0.0),
                        child: Text(
                          item.title,
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          style: TextStyle(
                            color: widget.activeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SbNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String title;

  SbNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.title,
  });
}
