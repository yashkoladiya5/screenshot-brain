import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final String? time;
  final Widget? avatar;

  const SbChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.time,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = isSender ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isSender ? colorScheme.onPrimary : colorScheme.onSurface;
    final timeColor = isSender 
        ? colorScheme.onPrimary.withValues(alpha: 0.7) 
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: SBSpacing.sm),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender && avatar != null) ...[
            avatar!,
            const SizedBox(width: SBSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(SBRadius.lg),
                  topRight: const Radius.circular(SBRadius.lg),
                  bottomLeft: Radius.circular(isSender ? SBRadius.lg : 0),
                  bottomRight: Radius.circular(isSender ? 0 : SBRadius.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      time!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: timeColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isSender && avatar != null) ...[
            const SizedBox(width: SBSpacing.sm),
            avatar!,
          ],
        ],
      ),
    );
  }
}
