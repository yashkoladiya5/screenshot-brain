import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

/// An interactive 2D magnetic field-line visualizer.
///
/// The bar magnet is modeled as a pair of monopoles (+q at the north pole,
/// -q at the south pole). Field lines are true streamlines of that field,
/// obtained with a classic 4th-order Runge-Kutta integration of
/// `dr/ds = B(r)/|B(r)|`, so they curve correctly from pole to pole.
///
/// A free compass needle is simulated as a magnetic dipole in the local
/// field with real torque dynamics: `alpha = k*sin(phi - theta) - c*omega`
/// (semi-implicit Euler), so it swings and settles instead of snapping.
///
/// Drag anywhere to move the magnet; the dash flow along the lines keeps
/// animating from north to south.
class SbMagneticFieldLines extends StatefulWidget {
  const SbMagneticFieldLines({
    super.key,
    this.size = 280.0,
    this.poleSeparation = 88.0,
    this.linesPerPole = 7,
    this.lineColor = const Color(0xFF64B5F6),
    this.northColor = const Color(0xFFEF5350),
    this.southColor = const Color(0xFF29B6F6),
    this.needleColor = const Color(0xFFFFC405),
    this.draggable = true,
    this.onMagnetMoved,
    this.northPoleKey,
    this.southPoleKey,
  });

  /// Side length of the square stage.
  final double size;

  /// Distance between the north and south poles.
  final double poleSeparation;

  /// Number of streamlines seeded around each pole.
  final int linesPerPole;

  final Color lineColor;
  final Color northColor;
  final Color southColor;
  final Color needleColor;

  /// Whether the magnet can be dragged around the stage.
  final bool draggable;

  /// Reports the magnet center (local coordinates) while dragging.
  final ValueChanged<Offset>? onMagnetMoved;

  /// Keys attached to the pole markers so tests can assert geometry.
  final Key? northPoleKey;
  final Key? southPoleKey;

  /// Field of the monopole pair at [r]. North pole contributes +q, south
  /// -q, with a 1/d^2 falloff written as `d / |d|^3`.
  static Offset fieldAt(Offset r, Offset north, Offset south) {
    final Offset dN = r - north;
    final Offset dS = r - south;
    final double rn = math.max(6.0, dN.distance);
    final double rs = math.max(6.0, dS.distance);
    final Offset bN = dN / (rn * rn * rn);
    final Offset bS = dS / (rs * rs * rs);
    return bN - bS;
  }

  /// One RK4 streamline step of unit-length size [h] starting at [p].
  static Offset rk4Step(Offset p, double h, Offset north, Offset south) {
    Offset unit(Offset x) {
      final Offset f = fieldAt(x, north, south);
      final double m = math.max(1e-9, f.distance);
      return f / m;
    }

    final Offset k1 = unit(p);
    final Offset k2 = unit(p + k1 * (h / 2));
    final Offset k3 = unit(p + k2 * (h / 2));
    final Offset k4 = unit(p + k3 * h);
    final Offset avg =
        (k1 + k2 * 2 + k3 * 2 + k4) / 6.0; // ignore w: operator overloads
    return p + avg * h;
  }

  @override
  State<SbMagneticFieldLines> createState() => _SbMagneticFieldLinesState();
}

class _SbMagneticFieldLinesState extends State<SbMagneticFieldLines>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Accumulated animation time, drives the dash flow phase.
  double _time = 0.0;

  /// Compass needle state: angle (rad) and angular velocity (rad/s).
  double _needleTheta = 0.0;
  double _needleOmega = 0.0;

  late Offset _magnetCenter;

  static const double _needleRest = 0.72; // fraction of size, on +x axis

  Offset get _north => _magnetCenter - Offset(0, widget.poleSeparation / 2);
  Offset get _south => _magnetCenter + Offset(0, widget.poleSeparation / 2);

  @override
  void initState() {
    super.initState();
    _magnetCenter = Offset(widget.size / 2, widget.size / 2);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    dt = dt.clamp(0.0001, 1 / 30);
    _time += dt;

    // Dipole torque dynamics: the needle accelerates toward the local
    // field direction and overshoots slightly before damping settles it.
    final Offset needlePos =
        _magnetCenter + Offset(widget.size * _needleRest / 2, 0);
    final Offset b = SbMagneticFieldLines.fieldAt(needlePos, _north, _south);
    final double phi = math.atan2(b.dy, b.dx);
    double diff = phi - _needleTheta;
    diff = math.atan2(math.sin(diff), math.cos(diff)); // wrap to [-pi, pi]
    const double k = 42.0; // torsional field constant
    const double c = 6.5; // angular damping
    final double alpha = k * math.sin(diff) - c * _needleOmega;
    _needleOmega += alpha * dt;
    _needleTheta += _needleOmega * dt;

    setState(() {});
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (!widget.draggable) return;
    final double pad = widget.poleSeparation / 2 + 10;
    setState(() {
      _magnetCenter = Offset(
        (_magnetCenter.dx + d.delta.dx).clamp(pad, widget.size - pad),
        (_magnetCenter.dy + d.delta.dy).clamp(pad, widget.size - pad),
      );
    });
    widget.onMagnetMoved?.call(_magnetCenter);
  }

  /// Trace streamlines with RK4: forward from seeds around the north
  /// pole, backward from seeds around the south pole.
  List<Path> _buildFieldLines() {
    final List<Path> paths = [];
    final double h = widget.size / 110; // streamline step length
    final int maxSteps = 260;
    final double seedR = 9.0;
    final Rect bounds = Rect.fromLTRB(
      -40,
      -40,
      widget.size + 40,
      widget.size + 40,
    );

    Path trace(Offset start, bool forward) {
      final Path path = Path()..moveTo(start.dx, start.dy);
      Offset p = start;
      for (int i = 0; i < maxSteps; i++) {
        final Offset next = forward
            ? SbMagneticFieldLines.rk4Step(p, h, _north, _south)
            : SbMagneticFieldLines.rk4Step(p, -h, _north, _south);
        if (!bounds.contains(next)) {
          path.lineTo(next.dx, next.dy);
          break;
        }
        // Terminate when the line runs into a pole.
        if ((next - _north).distance < seedR ||
            (next - _south).distance < seedR) {
          path.lineTo(next.dx, next.dy);
          break;
        }
        path.lineTo(next.dx, next.dy);
        p = next;
      }
      return path;
    }

    final int n = widget.linesPerPole;
    for (int i = 0; i < n; i++) {
      final double a = 2 * math.pi * i / n + math.pi / (2 * n);
      // Seeds around the north pole, traced outward (forward).
      final Offset seedN =
          _north + Offset(seedR * math.cos(a), seedR * math.sin(a));
      paths.add(trace(seedN, true));
      // Seeds around the south pole, traced inward (backward), which
      // recovers lines arriving from the far side into south.
      final Offset seedS =
          _south + Offset(seedR * math.cos(a), seedR * math.sin(a));
      paths.add(trace(seedS, false));
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    final double marker = 16.0;
    return ClipRect(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: _handlePanUpdate,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _FieldLinePainter(
                    lines: _buildFieldLines(),
                    lineColor: widget.lineColor,
                    // Dash flow phase, advancing along each streamline.
                    phase: (_time * 26.0) % 17.0,
                    needlePos:
                        _magnetCenter +
                        Offset(widget.size * _needleRest / 2, 0),
                    needleTheta: _needleTheta,
                    needleColor: widget.needleColor,
                    magnetCenter: _magnetCenter,
                    poleSeparation: widget.poleSeparation,
                    northColor: widget.northColor,
                    southColor: widget.southColor,
                  ),
                ),
              ),
              // Pole markers as real widgets so geometry is assertable.
              Positioned(
                left: _north.dx - marker / 2,
                top: _north.dy - marker / 2,
                child: KeyedSubtree(
                  key: widget.northPoleKey,
                  child: _PoleMarker(
                    label: 'N',
                    color: widget.northColor,
                    diameter: marker,
                  ),
                ),
              ),
              Positioned(
                left: _south.dx - marker / 2,
                top: _south.dy - marker / 2,
                child: KeyedSubtree(
                  key: widget.southPoleKey,
                  child: _PoleMarker(
                    label: 'S',
                    color: widget.southColor,
                    diameter: marker,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PoleMarker extends StatelessWidget {
  const _PoleMarker({
    required this.label,
    required this.color,
    required this.diameter,
  });

  final String label;
  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: diameter * 0.55,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FieldLinePainter extends CustomPainter {
  _FieldLinePainter({
    required this.lines,
    required this.lineColor,
    required this.phase,
    required this.needlePos,
    required this.needleTheta,
    required this.needleColor,
    required this.magnetCenter,
    required this.poleSeparation,
    required this.northColor,
    required this.southColor,
  });

  final List<Path> lines;
  final Color lineColor;
  final double phase;
  final Offset needlePos;
  final double needleTheta;
  final Color needleColor;
  final Offset magnetCenter;
  final double poleSeparation;
  final Color northColor;
  final Color southColor;

  static const double _dash = 10.0;
  static const double _gap = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint solid guide under each streamline.
    final Paint guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = lineColor.withValues(alpha: 0.14);
    // Moving dashes = energy flowing north -> south.
    final Paint dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = lineColor.withValues(alpha: 0.85);

    for (final Path path in lines) {
      canvas.drawPath(path, guide);
      for (final PathMetric metric in path.computeMetrics()) {
        double d = phase;
        while (d < metric.length) {
          final double end = math.min(d + _dash, metric.length);
          canvas.drawPath(metric.extractPath(d, end), dash);
          d += _dash + _gap;
        }
      }
    }

    // Bar magnet body.
    final Rect body = Rect.fromCenter(
      center: magnetCenter,
      width: 22,
      height: poleSeparation + 18,
    );
    final RRect rrect = RRect.fromRectAndRadius(body, const Radius.circular(7));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF263238));
    final Rect topHalf = Rect.fromLTRB(
      body.left,
      body.top,
      body.right,
      magnetCenter.dy,
    );
    final Rect bottomHalf = Rect.fromLTRB(
      body.left,
      magnetCenter.dy,
      body.right,
      body.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        topHalf.deflate(1.5),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      Paint()..color = northColor.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bottomHalf.deflate(1.5),
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
      Paint()..color = southColor.withValues(alpha: 0.9),
    );

    // Compass needle (drawn rotated by its simulated angle).
    canvas.save();
    canvas.translate(needlePos.dx, needlePos.dy);
    canvas.rotate(needleTheta);
    final Path head = Path()
      ..moveTo(14, 0)
      ..lineTo(-4, -4.5)
      ..lineTo(-4, 4.5)
      ..close();
    canvas.drawPath(head, Paint()..color = needleColor);
    final Path tail = Path()
      ..moveTo(-14, 0)
      ..lineTo(4, -4.5)
      ..lineTo(4, 4.5)
      ..close();
    canvas.drawPath(tail, Paint()..color = needleColor.withValues(alpha: 0.35));
    canvas.drawCircle(Offset.zero, 2.4, Paint()..color = Colors.white70);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FieldLinePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.needleTheta != needleTheta ||
        oldDelegate.magnetCenter != magnetCenter ||
        oldDelegate.lines.length != lines.length;
  }
}
