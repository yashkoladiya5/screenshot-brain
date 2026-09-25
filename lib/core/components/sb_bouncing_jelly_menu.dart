import 'package:flutter/material.dart';

class SbBouncingJellyMenu extends StatefulWidget {
  final List<IconData> icons;
  final ValueChanged<int> onItemSelected;
  final Color baseColor;
  final Color activeColor;

  const SbBouncingJellyMenu({
    super.key,
    required this.icons,
    required this.onItemSelected,
    this.baseColor = const Color(0xFFE0E0E0),
    this.activeColor = const Color(0xFFFF4081),
  }) : assert(icons.length > 0, 'Must have at least one icon');

  @override
  State<SbBouncingJellyMenu> createState() => _SbBouncingJellyMenuState();
}

class _SbBouncingJellyMenuState extends State<SbBouncingJellyMenu> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  
  // Controls the jelly squish effect
  late AnimationController _squishController;
  late Animation<double> _squishAnimation;
  
  // Controls the horizontal slide of the active indicator
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // The physics for the jelly squishing down and bouncing back up
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Elastic curve gives it that wobbly jelly feel
    _squishAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _squishController,
        curve: Curves.elasticOut,
      ),
    );
    
    // The physics for sliding horizontally
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )
    );
    
    // Start with fully formed jelly
    _squishController.forward();
  }

  @override
  void dispose() {
    _squishController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
    
    widget.onItemSelected(index);
    
    // Update the slide animation to move from previous to new
    _slideAnimation = Tween<double>(
      begin: _previousIndex.toDouble(), 
      end: _selectedIndex.toDouble()
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack, // Gives a slight overshoot when sliding
      )
    );
    
    // Reset and fire both animations simultaneously
    _slideController.forward(from: 0.0);
    _squishController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ]
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / widget.icons.length;
          
          return Stack(
            children: [
              // 1. The Jelly Indicator
              AnimatedBuilder(
                animation: Listenable.merge([_slideController, _squishController]),
                builder: (context, child) {
                  // Calculate horizontal position based on the slide animation
                  final double xOffset = _slideAnimation.value * itemWidth;
                  
                  // Calculate jelly deformation
                  // When squish is 0, it's flat. When squish is 1, it's fully round.
                  // But because it's elasticOut, it actually overshoots past 1.0 and bounces!
                  final double stretchX = 1.0 + (1.0 - _squishAnimation.value) * 0.5; // Stretches wider when moving
                  final double stretchY = _squishAnimation.value; // Flattens when moving
                  
                  return Positioned(
                    left: xOffset,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Center(
                      child: Transform.scale(
                        scaleX: stretchX,
                        scaleY: stretchY,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: widget.activeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.activeColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // 2. The Icons (layered on top)
              Row(
                children: List.generate(widget.icons.length, (index) {
                  final bool isActive = index == _selectedIndex;
                  
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      height: constraints.maxHeight,
                      child: Center(
                        // We also animate the icon popping up when selected
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          transform: Matrix4.identity()..translate(0.0, isActive ? -8.0 : 0.0),
                          child: Icon(
                            widget.icons[index],
                            color: isActive ? Colors.white : Colors.black54,
                            size: isActive ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }
      ),
    );
  }
}
