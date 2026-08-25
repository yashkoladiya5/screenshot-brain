import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbTimelineEvent {
  final String title;
  final String time;
  final String? description;
  final IconData? icon;
  final Color? color;

  const SbTimelineEvent({
    required this.title,
    required this.time,
    this.description,
    this.icon,
    this.color,
  });
}

class SbTimelineView extends StatelessWidget {
  final List<SbTimelineEvent> events;
  final Color? defaultColor;
  final bool isAnimated;

  const SbTimelineView({
    super.key,
    required this.events,
    this.defaultColor,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final fallbackColor = defaultColor ?? colorScheme.primary;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        final eventColor = event.color ?? fallbackColor;
        
        Widget child = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side: Time
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: SBSpacing.sm, right: SBSpacing.md),
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
              
              // Center: Line and Node
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: eventColor,
                        width: 2.0,
                      ),
                    ),
                    child: event.icon != null
                        ? Icon(
                            event.icon,
                            size: 16,
                            color: eventColor,
                          )
                        : Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: eventColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                      ),
                    ),
                ],
              ),
              
              // Right side: Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: SBSpacing.md,
                    bottom: SBSpacing.xl, // Space between events
                    top: SBSpacing.sm, // Align with node center
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: SBSpacing.xs),
                        Text(
                          event.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (isAnimated) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 150)), // Staggered
            curve: Curves.easeOutQuart,
            builder: (context, value, wrappedChild) {
              return Transform.translate(
                offset: Offset(50 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: wrappedChild,
                ),
              );
            },
            child: child,
          );
        }

        return child;
      },
    );
  }
}
