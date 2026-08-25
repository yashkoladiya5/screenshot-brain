import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbBottomSheetOption<T> {
  final String label;
  final T value;
  final IconData? icon;
  final String? subtitle;

  const SbBottomSheetOption({
    required this.label,
    required this.value,
    this.icon,
    this.subtitle,
  });
}

class SbBottomSheetSelector<T> extends StatelessWidget {
  final String title;
  final List<SbBottomSheetOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T> onSelected;

  const SbBottomSheetSelector({
    super.key,
    required this.title,
    required this.options,
    required this.onSelected,
    this.selectedValue,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<SbBottomSheetOption<T>> options,
    T? selectedValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SbBottomSheetSelector<T>(
          title: title,
          options: options,
          selectedValue: selectedValue,
          onSelected: (val) {
            Navigator.of(context).pop(val);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SBRadius.xl),
          topRight: Radius.circular(SBRadius.xl),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: SBSpacing.sm, bottom: SBSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(SBRadius.full),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          // List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              padding: EdgeInsets.only(
                top: SBSpacing.sm,
                bottom: bottomPadding > 0 ? bottomPadding : SBSpacing.lg,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.value == selectedValue;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: SBSpacing.lg),
                  leading: option.icon != null 
                    ? Icon(
                        option.icon, 
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      )
                    : null,
                  title: Text(
                    option.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: option.subtitle != null
                    ? Text(
                        option.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                  trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                    : null,
                  onTap: () => onSelected(option.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
