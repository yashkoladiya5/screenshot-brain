import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design/tokens.dart';

class SbDatePickerButton extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const SbDatePickerButton({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.placeholder = 'Select Date',
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? DateTime(now.year - 5);
    final last = lastDate ?? DateTime(now.year + 5);
    // showDatePicker asserts that initialDate lies inside firstDate..lastDate.
    // A stored date outside the window - any expense older than the default
    // five-year span - therefore threw the moment the button was tapped.
    var initialDate = selectedDate ?? now;
    if (initialDate.isBefore(first)) initialDate = first;
    if (initialDate.isAfter(last)) initialDate = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasDate = selectedDate != null;

    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(SBRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SBSpacing.md,
          vertical: SBSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(SBRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: hasDate
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: SBSpacing.sm),
            Text(
              hasDate
                  ? DateFormat('MMM d, yyyy').format(selectedDate!)
                  : placeholder,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasDate
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
