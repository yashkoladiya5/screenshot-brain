import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbAnimatedTimeline extends StatefulWidget {
  final List<TimelineItem> items;
  final Color activeColor;
  final Color inactiveColor;
  final double iconSize;

  const SbAnimatedTimeline({
    super.key,
    required this.items,
    this.activeColor = Colors.blueAccent,
    this.inactiveColor = Colors.grey,
    this.iconSize = 30.0,
  });

  @override
  State<SbAnimatedTimeline> createState() => _SbAnimatedTimelineState();
}

class TimelineItem {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final IconData icon;

  TimelineItem({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.icon = Icons.check_circle,
  });
}

class _SbAnimatedTimelineState extends State<SbAnimatedTimeline> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // We will animate the progress line drawing itself downwards
  late Animation<double> _lineProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _lineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Auto-play the timeline drawing animation on load
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lineProgress,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isLast = index == widget.items.length - 1;

            // Calculate when this specific item's node should appear in the overall timeline animation
            // E.g., if there are 4 items, item 0 appears at 0%, item 1 at 33%, item 2 at 66%, item 3 at 100%
            final double itemTimeSegment = widget.items.length > 1 ? index / (widget.items.length - 1) : 1.0;
            
            // Has the drawing line reached this node yet?
            final bool hasLineReached = _lineProgress.value >= itemTimeSegment;

            // If the item is marked completed data-wise, AND the animation has reached it
            final bool isActive = item.isCompleted && hasLineReached;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. The Timeline Node and Line column
                  SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        // The Node Icon
                        AnimatedScale(
                          scale: hasLineReached ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: Container(
                            width: widget.iconSize,
                            height: widget.iconSize,
                            decoration: BoxDecoration(
                              color: isActive ? widget.activeColor : widget.inactiveColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: widget.activeColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ] : null,
                            ),
                            child: Icon(
                              item.icon,
                              color: isActive ? Colors.white : widget.inactiveColor,
                              size: widget.iconSize * 0.6,
                            ),
                          ),
                        ),

                        // The Connecting Line (Only draw if not the last item)
                        if (!isLast)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Determine how much of THIS specific line segment should be drawn based on global progress
                                final double nextItemTimeSegment = (index + 1) / (widget.items.length - 1);
                                
                                double segmentProgress = 0.0;
                                if (_lineProgress.value >= nextItemTimeSegment) {
                                  segmentProgress = 1.0; // Fully drawn
                                } else if (_lineProgress.value > itemTimeSegment) {
                                  // Partially drawn
                                  final double range = nextItemTimeSegment - itemTimeSegment;
                                  final double amountIntoRange = _lineProgress.value - itemTimeSegment;
                                  segmentProgress = amountIntoRange / range;
                                }

                                return CustomPaint(
                                  size: Size(2, constraints.maxHeight),
                                  painter: _TimelineLinePainter(
                                    progress: segmentProgress,
                                    activeColor: widget.activeColor,
                                    inactiveColor: widget.inactiveColor.withValues(alpha: 0.2),
                                    isActive: isActive && widget.items[index+1].isCompleted,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 2. The Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
                      child: AnimatedOpacity(
                        opacity: hasLineReached ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: AnimatedSlide(
                          offset: hasLineReached ? Offset.zero : const Offset(0.1, 0),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4), // Align with icon center
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? null : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final bool isActive;

  _TimelineLinePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double startX = size.width / 2;
    
    // Draw background (inactive) line
    final Paint bgPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(
      Offset(startX, 0), 
      Offset(startX, size.height), 
      bgPaint,
    );

    // Draw foreground (active/animating) line
    if (progress > 0) {
      final Paint fgPaint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      // Draw the line down to the current progress percentage of the height
      canvas.drawLine(
        Offset(startX, 0), 
        Offset(startX, size.height * progress), 
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.isActive != isActive;
  }
}
