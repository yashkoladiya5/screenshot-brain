import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbMonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onMonthSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const SbMonthPicker({
    super.key,
    required this.initialDate,
    required this.onMonthSelected,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<SbMonthPicker> createState() => _SbMonthPickerState();
}

class _SbMonthPickerState extends State<SbMonthPicker> {
  late DateTime _currentDate;
  
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
  }

  void _changeYear(int delta) {
    setState(() {
      _currentDate = DateTime(_currentDate.year + delta, _currentDate.month);
    });
  }

  void _selectMonth(int monthIndex) {
    final newDate = DateTime(_currentDate.year, monthIndex + 1);
    
    // Check bounds
    if (widget.firstDate != null && newDate.isBefore(DateTime(widget.firstDate!.year, widget.firstDate!.month))) {
      return;
    }
    if (widget.lastDate != null && newDate.isAfter(DateTime(widget.lastDate!.year, widget.lastDate!.month))) {
      return;
    }

    setState(() {
      _currentDate = newDate;
    });
    widget.onMonthSelected(_currentDate);
  }

  bool _isMonthDisabled(int monthIndex) {
    final date = DateTime(_currentDate.year, monthIndex + 1);
    if (widget.firstDate != null && date.isBefore(DateTime(widget.firstDate!.year, widget.firstDate!.month))) {
      return true;
    }
    if (widget.lastDate != null && date.isAfter(DateTime(widget.lastDate!.year, widget.lastDate!.month))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(SBSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(SBRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeYear(-1),
                color: colorScheme.onSurfaceVariant,
              ),
              Text(
                '${_currentDate.year}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _changeYear(1),
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: SBSpacing.lg),
          // Months Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              crossAxisSpacing: SBSpacing.sm,
              mainAxisSpacing: SBSpacing.sm,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final isSelected = _currentDate.month == index + 1;
              final isDisabled = _isMonthDisabled(index);

              return Material(
                color: isSelected ? colorScheme.primary : (isDisabled ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.transparent),
                borderRadius: BorderRadius.circular(SBRadius.md),
                child: InkWell(
                  onTap: isDisabled ? null : () => _selectMonth(index),
                  borderRadius: BorderRadius.circular(SBRadius.md),
                  child: Center(
                    child: Text(
                      _months[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected 
                            ? colorScheme.onPrimary 
                            : (isDisabled ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3) : colorScheme.onSurface),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
