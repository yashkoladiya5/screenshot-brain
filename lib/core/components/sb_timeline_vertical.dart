import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTimelineEvent {
  final String time;
  final String title;
  final String? description;
  final IconData? icon;
  final Color? iconColor;

  const SbTimelineEvent({
    required this.time,
    required this.title,
    this.description,
    this.icon,
    this.iconColor,
  });
}

class SbTimelineVertical extends StatelessWidget {
  final List<SbTimelineEvent> events;

  const SbTimelineVertical({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final dotColor = event.iconColor ?? colorScheme.primary;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Time column
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    event.time,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              const SizedBox(width: SBSpacing.md),
              // Line & Dot column
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        event.icon ?? Icons.circle,
                        size: 16,
                        color: dotColor,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: SBSpacing.md),
              // Content column
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : SBSpacing.xl,
                    top: 6.0, // align with center of circle
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
