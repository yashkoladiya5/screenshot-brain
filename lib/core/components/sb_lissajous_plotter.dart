import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A harmonograph-style Lissajous plotter with real damped-oscillator math.
///
/// The pen position follows the classic two-pendulum harmonograph
/// parameterisation
///
/// ```
/// x(t) = A * e^{-decayX * t} * sin(freqX * t + phase)
/// y(t) = B * e^{-decayY * t} * sin(freqY * t)
/// ```
///
/// which is the small-angle solution of two damped harmonic oscillators read
/// on perpendicular axes. Because the amplitudes decay exponentially (the
/// exact solution of `da/dt = -λ a`), the trace slowly spirals toward the
/// centre like a real optical-plot recording.
///
/// The curve is sampled continuously by an own [Ticker] (not an
/// [AnimationController]), so the trace advances at wall-clock rate and the
/// history fades from the tail. Drag horizontally to shift the relative
/// [phase] — the same thing a real harmonograph does when you nudge one
/// pendulum bob — and tap to rewind the paper.
class SbLissajousPlotter extends StatefulWidget {
  const SbLissajousPlotter({
    super.key,
    this.size = 260.0,
    this.freqX = 3.0,
    this.freqY = 2.0,
    this.phase = math.pi / 2,
    this.decayX = 0.06,
    this.decayY = 0.08,
    this.amplitudeFactor = 0.42,
    this.speed = 1.0,
    this.maxPoints = 420,
    this.lineColor = const Color(0xFF4DD0E1),
    this.penColor = const Color(0xFFFF7043),
    this.backgroundColor = const Color(0xFF10212B),
    this.interactive = true,
    this.penKey,
    this.onPhaseChanged,
  });

  /// Side length of the square plot area.
  final double size;

  /// Angular frequency of the x oscillator, in rad per plot-time unit.
  final double freqX;

  /// Angular frequency of the y oscillator. Their ratio sets the figure
  /// (3:2 gives the classic trefoil Lissajous).
  final double freqY;

  /// Relative phase between the two oscillators, in radians. Draggable.
  final double phase;

  /// Exponential amplitude decay rates (1/second of plot time).
  final double decayX;
  final double decayY;

  /// Half-length of the pen travel as a fraction of [size].
  final double amplitudeFactor;

  /// Plot-time units advanced per wall second.
  final double speed;

  /// Number of polyline samples kept before the tail fades out.
  final int maxPoints;

  final Color lineColor;
  final Color penColor;
  final Color backgroundColor;

  /// Whether drag (phase) and tap (rewind) gestures are enabled.
  final bool interactive;

  /// [Key] attached to the pen marker so tests can assert its geometry.
  final Key? penKey;

  /// Reports the live phase whenever the user drags it.
  final ValueChanged<double>? onPhaseChanged;

  /// Exact pen position of the damped harmonograph at plot time [t],
  /// in a coordinate system centred at (`size/2`, `size/2`).
  static Offset penAt({
    required double t,
    required double size,
    required double freqX,
    required double freqY,
    required double phase,
    required double decayX,
    required double decayY,
    required double amplitudeFactor,
  }) {
    final double amp = size * amplitudeFactor;
    final double dx =
        amp * math.exp(-decayX * t) * math.sin(freqX * t + phase);
    final double dy =
        amp * math.exp(-decayY * t) * math.sin(freqY * t);
    return Offset(size / 2 + dx, size / 2 + dy);
  }

  @override
  State<SbLissajousPlotter> createState() => _SbLissajousPlotterState();
}

class _SbLissajousPlotterState extends State<SbLissajousPlotter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Accumulated plot time.
  double _t = 0.0;

  /// Live phase, shifted by horizontal drags.
  late double _phase;

  /// Traced samples, oldest first.
  final List<Offset> _trail = [];

  /// Sample cadence in plot-time units; ~400 samples per 2π sweep gives a
  /// smooth polyline without O(n^2) repaint cost.
  static const double _sampleDt = 0.022;

  double _lastSampleT = -1e9;

  @override
  void initState() {
    super.initState();
    _phase = widget.phase;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset _penAt(double t) => SbLissajousPlotter.penAt(
        t: t,
        size: widget.size,
        freqX: widget.freqX,
        freqY: widget.freqY,
        phase: _phase,
        decayX: widget.decayX,
        decayY: widget.decayY,
        amplitudeFactor: widget.amplitudeFactor,
      );

  void _onTick(Duration elapsed) {
    double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    dt = dt.clamp(0.0001, 1 / 30) * widget.speed;

    final double t0 = _t;
    _t += dt;

    // Emit polyline samples at a fixed plot-time cadence, sub-frame
    // accurate: whatever portion of [t0, _t] crossed sample boundaries is
    // recorded, so the trail density is independent of frame rate.
    double s = _lastSampleT < 0
        ? t0
        : ((_lastSampleT / _sampleDt).floor() + 1) * _sampleDt;
    while (s <= _t) {
      _trail.add(_penAt(s));
      _lastSampleT = s;
      s += _sampleDt;
    }
    if (_trail.length > widget.maxPoints) {
      _trail.removeRange(0, _trail.length - widget.maxPoints);
    }

    setState(() {});
  }

  void _rewind() {
    _t = 0;
    _lastSampleT = -1e9;
    _trail.clear();
    setState(() {});
  }

  void _handlePanUpdate(DragUpdateDetails d) {
    if (!widget.interactive) return;
    // 2π of phase across the full width, like sliding the pen carriage.
    setState(() {
      _phase = _phase + d.delta.dx / widget.size * 2 * math.pi;
      _lastSampleT = -1e9; // resync sampling to avoid a jump
    });
    widget.onPhaseChanged?.call(_phase);
  }

  @override
  Widget build(BuildContext context) {
    final Offset pen = _penAt(_t);
    return ClipRect(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.interactive ? _rewind : null,
          onHorizontalDragUpdate: _handlePanUpdate,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LissajousPainter(
                    trail: List<Offset>.from(_trail),
                    lineColor: widget.lineColor,
                    backgroundColor: widget.backgroundColor,
                    maxPoints: widget.maxPoints,
                  ),
                ),
              ),
              // Pen marker as a real widget so its geometry is assertable.
              Positioned(
                left: pen.dx - 5,
                top: pen.dy - 5,
                child: IgnorePointer(
                  child: KeyedSubtree(
                    key: widget.penKey,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.penColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.penColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
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

class _LissajousPainter extends CustomPainter {
  _LissajousPainter({
    required this.trail,
    required this.lineColor,
    required this.backgroundColor,
    required this.maxPoints,
  });

  final List<Offset> trail;
  final Color lineColor;
  final Color backgroundColor;
  final int maxPoints;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    // Faint centre cross, like the plotter's registration marks.
    final Paint grid = Paint()
      ..color = lineColor.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), grid);

    if (trail.length < 2) return;

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.6;

    // Draw segment-by-segment: alpha ramps in from the faded tail so the
    // ink "dries" behind the pen.
    final int n = trail.length;
    for (int i = 1; i < n; i++) {
      final double f = i / (n - 1);
      stroke.color = lineColor.withValues(alpha: 0.06 + 0.84 * f * f);
      canvas.drawLine(trail[i - 1], trail[i], stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LissajousPainter oldDelegate) {
    return oldDelegate.trail.length != trail.length ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        (trail.isNotEmpty &&
            oldDelegate.trail.last != trail.last);
  }
}
