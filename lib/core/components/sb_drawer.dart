import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbDrawer extends StatelessWidget {
  final Widget? header;
  final List<Widget> children;
  final Widget? footer;

  const SbDrawer({
    super.key,
    this.header,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Drawer(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(SBRadius.xl),
          bottomRight: Radius.circular(SBRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              Padding(
                padding: const EdgeInsets.all(SBSpacing.md),
                child: header!,
              ),
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ],
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: SBSpacing.sm),
                children: children,
              ),
            ),
            if (footer != null) ...[
              Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              Padding(
                padding: const EdgeInsets.all(SBSpacing.md),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
