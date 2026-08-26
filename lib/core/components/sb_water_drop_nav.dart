import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbWaterDropNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String? label;

  const SbWaterDropNavItem({
    required this.icon,
    required this.activeIcon,
    this.label,
  });
}

class SbWaterDropNav extends StatefulWidget {
  final List<SbWaterDropNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? waterDropColor;

  const SbWaterDropNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.waterDropColor,
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  State<SbWaterDropNav> createState() => _SbWaterDropNavState();
}

class _SbWaterDropNavState extends State<SbWaterDropNav> with TickerProviderStateMixin {
  late AnimationController _dropController;
  late Animation<double> _dropAnimation;
  
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _dropAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(SbWaterDropNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _dropController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bg = widget.backgroundColor ?? colorScheme.surface;
    final active = widget.activeColor ?? colorScheme.primary;
    final inactive = widget.inactiveColor ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    final dropColor = widget.waterDropColor ?? active;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Stack(
        children: [
          // The Animated Water Drop Background
          AnimatedBuilder(
            animation: _dropAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _WaterDropPainter(
                  itemsCount: widget.items.length,
                  selectedIndex: widget.selectedIndex,
                  previousIndex: _previousIndex,
                  progress: _dropAnimation.value,
                  color: dropColor,
                ),
              );
            },
          ),
          
          // The Icons
          Row(
            children: List.generate(widget.items.length, (index) {
              final isSelected = index == widget.selectedIndex;
              final item = widget.items[index];
              
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (index != widget.selectedIndex) {
                      widget.onItemSelected(index);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    // Shift the icon up slightly when selected to sit in the drop
                    transform: Matrix4.translationValues(0, isSelected ? -12 : 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? Colors.white : inactive,
                          size: 28,
                        ),
                        if (item.label != null && !isSelected) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.label!,
                            style: TextStyle(
                              color: inactive,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  final int itemsCount;
  final int selectedIndex;
  final int previousIndex;
  final double progress;
  final Color color;

  _WaterDropPainter({
    required this.itemsCount,
    required this.selectedIndex,
    required this.previousIndex,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double sectionWidth = size.width / itemsCount;
    
    // Calculate current horizontal position smoothly moving between previous and new
    final double previousCenterX = (previousIndex * sectionWidth) + (sectionWidth / 2);
    final double targetCenterX = (selectedIndex * sectionWidth) + (sectionWidth / 2);
    
    final double currentCenterX = previousCenterX + ((targetCenterX - previousCenterX) * progress);

    // Draw the water drop shape at the current centerX
    final path = Path();
    
    // We draw a drop shape protruding slightly upwards
    final double dropY = 15.0; // How high the drop goes above the bar
    final double dropWidth = 35.0;
    
    path.moveTo(0, dropY);
    
    // Draw flat line to left side of drop
    path.lineTo(currentCenterX - dropWidth, dropY);
    
    // Draw smooth bezier curve up and around for the drop
    path.cubicTo(
      currentCenterX - (dropWidth / 2), dropY, // Control 1
      currentCenterX - (dropWidth / 2), -5,     // Control 2
      currentCenterX, -5,                       // Point
    );
    
    path.cubicTo(
      currentCenterX + (dropWidth / 2), -5,     // Control 1
      currentCenterX + (dropWidth / 2), dropY,  // Control 2
      currentCenterX + dropWidth, dropY,        // Point
    );
    
    // Draw flat line to end
    path.lineTo(size.width, dropY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // To make it look like a floating bubble inside the bar rather than a cut-out,
    // we actually just draw a circle that moves
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    // The "bounce" effect during transition
    final double bounceOffset = math.sin(progress * math.pi) * 10;
    
    canvas.drawCircle(
      Offset(currentCenterX, dropY - 2 - bounceOffset), 
      22, // Radius
      circlePaint
    );
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.selectedIndex != selectedIndex ||
           oldDelegate.color != color;
  }
}
