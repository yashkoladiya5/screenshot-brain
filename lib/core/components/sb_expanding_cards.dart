import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbExpandingCardItem {
  final String title;
  final String? subtitle;
  final ImageProvider image;
  final Widget? content;

  const SbExpandingCardItem({
    required this.title,
    required this.image,
    this.subtitle,
    this.content,
  });
}

class SbExpandingCards extends StatefulWidget {
  final List<SbExpandingCardItem> items;
  final double height;
  final double expandedFlex;
  final double collapsedFlex;
  final double borderRadius;

  const SbExpandingCards({
    super.key,
    required this.items,
    this.height = 400.0,
    this.expandedFlex = 5.0,
    this.collapsedFlex = 1.0,
    this.borderRadius = SBRadius.lg,
  }) : assert(items.length > 0);

  @override
  State<SbExpandingCards> createState() => _SbExpandingCardsState();
}

class _SbExpandingCardsState extends State<SbExpandingCards> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        children: List.generate(widget.items.length, (index) {
          final bool isActive = _activeIndex == index;
          final item = widget.items[index];
          
          return Expanded(
            flex: (isActive ? widget.expandedFlex * 10 : widget.collapsedFlex * 10).toInt(),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuint,
                margin: EdgeInsets.only(
                  right: index == widget.items.length - 1 ? 0 : SBSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  image: DecorationImage(
                    image: item.image,
                    fit: BoxFit.cover,
                    // Slightly darken inactive cards
                    colorFilter: isActive 
                        ? null 
                        : ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Stack(
                    children: [
                      // Gradient overlay at bottom for text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: widget.height * 0.4,
                        child: AnimatedOpacity(
                          opacity: isActive ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Content (Text & custom widget)
                      Positioned(
                        bottom: SBSpacing.lg,
                        left: SBSpacing.lg,
                        right: SBSpacing.lg,
                        child: AnimatedOpacity(
                          opacity: isActive ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          // Delay the text fade in slightly for a smoother sequence
                          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (item.content != null) ...[
                                const SizedBox(height: SBSpacing.md),
                                item.content!,
                              ]
                            ],
                          ),
                        ),
                      ),
                      
                      // Vertical text for collapsed state
                      if (!isActive)
                        Positioned.fill(
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: 3, // Rotate 270 degrees
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
