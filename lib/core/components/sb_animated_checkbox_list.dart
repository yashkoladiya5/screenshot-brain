import 'package:flutter/material.dart';

class SbAnimatedCheckboxList extends StatefulWidget {
  final List<String> items;
  final ValueChanged<List<String>>? onChanged;
  final Color activeColor;

  const SbAnimatedCheckboxList({
    super.key,
    required this.items,
    this.onChanged,
    this.activeColor = Colors.blueAccent,
  });

  @override
  State<SbAnimatedCheckboxList> createState() => _SbAnimatedCheckboxListState();
}

class _SbAnimatedCheckboxListState extends State<SbAnimatedCheckboxList> {
  final Set<String> _selectedItems = {};

  void _toggleItem(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
    
    if (widget.onChanged != null) {
      widget.onChanged!(_selectedItems.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.items.map((item) {
        final bool isSelected = _selectedItems.contains(item);
        
        return GestureDetector(
          onTap: () => _toggleItem(item),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? widget.activeColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(
                      color: isSelected ? widget.activeColor : Colors.grey,
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? widget.activeColor : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    decoration: isSelected ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: widget.activeColor,
                    decorationThickness: 2.0,
                  ),
                  child: Text(item),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
