import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbInteractiveFluidMesh extends StatefulWidget {
  final int rows;
  final int columns;
  final Color nodeColor;
  final Color meshColor;
  final double width;
  final double height;

  const SbInteractiveFluidMesh({
    super.key,
    this.rows = 15,
    this.columns = 10,
    this.nodeColor = const Color(0xFF00FFCC),
    this.meshColor = const Color(0x4400FFCC),
    this.width = double.infinity,
    this.height = double.infinity,
  });

  @override
  State<SbInteractiveFluidMesh> createState() => _SbInteractiveFluidMeshState();
}

class _SbInteractiveFluidMeshState extends State<SbInteractiveFluidMesh> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<List<_MeshNode>> _grid;
  
  Offset? _touchPosition;
  double _touchVelocity = 0;
  Offset _lastTouchPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // 60 FPS update loop
    )..addListener(_updatePhysics);
  }

  void _initGrid(Size size) {
    _grid = List.generate(widget.columns, (col) {
      return List.generate(widget.rows, (row) {
        final double x = (col / (widget.columns - 1)) * size.width;
        final double y = (row / (widget.rows - 1)) * size.height;
        return _MeshNode(
          baseX: x,
          baseY: y,
          currentX: x,
          currentY: y,
        );
      });
    });
    _controller.repeat();
  }

  void _updatePhysics() {
    if (!mounted) return;
    setState(() {
      for (int col = 0; col < widget.columns; col++) {
        for (int row = 0; row < widget.rows; row++) {
          final node = _grid[col][row];
          
          // 1. Touch repulsion physics
          if (_touchPosition != null) {
            final double dx = node.currentX - _touchPosition!.dx;
            final double dy = node.currentY - _touchPosition!.dy;
            final double distance = math.sqrt(dx * dx + dy * dy);
            
            // Interaction radius depends on drag velocity
            final double radius = 100 + (_touchVelocity * 2).clamp(0.0, 150.0);
            
            if (distance < radius && distance > 0) {
              // Calculate push force (stronger when closer)
              final double force = (radius - distance) / radius;
              // Push nodes away from touch
              node.vx += (dx / distance) * force * 5.0;
              node.vy += (dy / distance) * force * 5.0;
            }
          }
          
          // 2. Spring physics pulling back to base position
          final double springForceX = (node.baseX - node.currentX) * 0.1;
          final double springForceY = (node.baseY - node.currentY) * 0.1;
          
          node.vx += springForceX;
          node.vy += springForceY;
          
          // 3. Friction
          node.vx *= 0.85;
          node.vy *= 0.85;
          
          // 4. Update position
          node.currentX += node.vx;
          node.currentY += node.vy;
        }
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final now = details.localPosition;
    final double dx = now.dx - _lastTouchPosition.dx;
    final double dy = now.dy - _lastTouchPosition.dy;
    
    setState(() {
      _touchPosition = now;
      _touchVelocity = math.sqrt(dx * dx + dy * dy);
      _lastTouchPosition = now;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize grid on first build
        if (!_controller.isAnimating) {
          _initGrid(Size(constraints.maxWidth, constraints.maxHeight));
        }
        
        return GestureDetector(
          onPanDown: (details) {
            _touchPosition = details.localPosition;
            _lastTouchPosition = details.localPosition;
            _touchVelocity = 0;
          },
          onPanUpdate: _onPanUpdate,
          onPanEnd: (_) {
            _touchPosition = null;
            _touchVelocity = 0;
          },
          onPanCancel: () {
            _touchPosition = null;
            _touchVelocity = 0;
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              painter: _FluidMeshPainter(
                grid: _grid,
                columns: widget.columns,
                rows: widget.rows,
                nodeColor: widget.nodeColor,
                meshColor: widget.meshColor,
              ),
            ),
          ),
        );
      }
    );
  }
}

class _MeshNode {
  final double baseX;
  final double baseY;
  double currentX;
  double currentY;
  double vx = 0;
  double vy = 0;

  _MeshNode({
    required this.baseX,
    required this.baseY,
    required this.currentX,
    required this.currentY,
  });
}

class _FluidMeshPainter extends CustomPainter {
  final List<List<_MeshNode>> grid;
  final int columns;
  final int rows;
  final Color nodeColor;
  final Color meshColor;

  _FluidMeshPainter({
    required this.grid,
    required this.columns,
    required this.rows,
    required this.nodeColor,
    required this.meshColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = meshColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final Paint nodePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;
      
    final Paint glowPaint = Paint()
      ..color = nodeColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path path = Path();

    // Draw horizontal connections
    for (int row = 0; row < rows; row++) {
      path.moveTo(grid[0][row].currentX, grid[0][row].currentY);
      for (int col = 1; col < columns; col++) {
        // Use quadratic bezier for smooth fluid-like curves between nodes
        final prev = grid[col - 1][row];
        final curr = grid[col][row];
        final midX = (prev.currentX + curr.currentX) / 2;
        final midY = (prev.currentY + curr.currentY) / 2;
        
        path.quadraticBezierTo(prev.currentX, prev.currentY, midX, midY);
        
        if (col == columns - 1) {
          path.lineTo(curr.currentX, curr.currentY);
        }
      }
    }

    // Draw vertical connections
    for (int col = 0; col < columns; col++) {
      path.moveTo(grid[col][0].currentX, grid[col][0].currentY);
      for (int row = 1; row < rows; row++) {
        final prev = grid[col][row - 1];
        final curr = grid[col][row];
        final midX = (prev.currentX + curr.currentX) / 2;
        final midY = (prev.currentY + curr.currentY) / 2;
        
        path.quadraticBezierTo(prev.currentX, prev.currentY, midX, midY);
        
        if (row == rows - 1) {
          path.lineTo(curr.currentX, curr.currentY);
        }
      }
    }

    // Draw all lines at once for performance
    canvas.drawPath(path, linePaint);

    // Draw nodes
    for (int col = 0; col < columns; col++) {
      for (int row = 0; row < rows; row++) {
        final node = grid[col][row];
        // Calculate stretch for dynamic sizing
        final double dx = node.currentX - node.baseX;
        final double dy = node.currentY - node.baseY;
        final double stretch = math.sqrt(dx * dx + dy * dy);
        
        // Nodes grow slightly when stretched
        final double radius = 3.0 + (stretch * 0.05).clamp(0.0, 4.0);
        
        canvas.drawCircle(Offset(node.currentX, node.currentY), radius * 2, glowPaint);
        canvas.drawCircle(Offset(node.currentX, node.currentY), radius, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FluidMeshPainter oldDelegate) {
    return true; // Always repainting due to physics loop
  }
}
