import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A pendulum-wave loader: N ideal pendulums whose lengths are tuned so
/// that in one common cycle the i-th completes exactly `baseSwings + i`
/// full oscillations.
///
/// This is the real demo-hall pendulum wave. For small angles a pendulum
/// of length L oscillates with period `T = 2π sqrt(L/g)`, so the required
/// lengths follow `L_i = g * (cycle / (2π n_i))^2`, i.e.
///
/// ```
/// L_i = L_max * (n_min / n_i)^2      with n_i = baseSwings + i
/// theta_i(t) = A * cos(2π n_i t / cycle)
/// ```
///
/// Because every angle is a closed-form solution of the harmonic oscillator
/// (no numerical integration, no timer prop-switching), the ensemble is
/// exactly periodic: at `t = cycle` every bob is back at its release
/// angle, and between those instants the chain self-assembles into
/// travelling and standing wave patterns before re-phasing.
///
/// Each bob is a real positioned widget keyed `ValueKey('sb-pwl-bob-<i>')`
/// so geometry can be asserted in tests.
class SbPendulumWaveLoader extends StatefulWidget {
  const SbPendulumWaveLoader({
    super.key,
    this.width = 300.0,
    this.height = 200.0,
    this.count = 10,
    this.baseSwings = 8,
    this.cycle = const Duration(milliseconds: 2000),
    this.amplitudeRadians = 0.45,
    this.bobRadius = 8.0,
    this.timeScale = 1.0,
    this.stringColor = const Color(0xFF90A4AE),
    this.bobColor = const Color(0xFFFFCA28),
    this.barColor = const Color(0xFF546E7A),
  });

  /// Stage size.
  final double width;
  final double height;

  /// Number of pendulums.
  final int count;

  /// Oscillations completed per cycle by the *longest* pendulum; pendulum
  /// i completes `baseSwings + i`.
  final int baseSwings;

  /// Common re-phasing cycle.
  final Duration cycle;

  /// Release amplitude, in radians (kept < ~0.5 rad so the small-angle
  /// closed form stays faithful).
  final double amplitudeRadians;

  final double bobRadius;

  /// Simulation-time multiplier.
  final double timeScale;

  final Color stringColor;
  final Color bobColor;
  final Color barColor;

  /// Oscillations of pendulum [index] per common cycle.
  int swingsAt(int index) => baseSwings + index;

  /// Small-angle solution `theta_i(t)` in radians at simulation time [t]
  /// seconds.
  double angleAt(double t, int index) =>
      amplitudeRadians *
      math.cos(2 * math.pi * swingsAt(index) * t / cycle.inMicroseconds * 1e6);

  /// Cable length of pendulum [index] in pixels, normalised so the longest
  /// one hangs to `L_max`. From `T = 2π sqrt(L/g)`:
  /// `L_i = L_max * (n_min / n_i)^2`.
  double lengthAt(int index, double lengthMax) {
    final int nMin = baseSwings;
    final double ratio = nMin / swingsAt(index);
    return lengthMax * ratio * ratio;
  }

  /// Pivot of pendulum [index], evenly spaced along the bar.
  Offset pivotAt(int index) {
    final double spacing = width / (count + 1);
    return Offset(spacing * (index + 1), height * 0.14);
  }

  /// Bob centre at simulation time [t] seconds, canvas coordinates.
  Offset bobAt(int index, double t, {double? lengthMax}) {
    final double lMax = lengthMax ?? height * 0.72;
    final double l = lengthAt(index, lMax);
    final double theta = angleAt(t, index);
    // Screen y grows downward; the bob hangs below the pivot.
    return pivotAt(index) + Offset(l * math.sin(theta), l * math.cos(theta));
  }

  @override
  State<SbPendulumWaveLoader> createState() => _SbPendulumWaveLoaderState();
}

class _SbPendulumWaveLoaderState extends State<SbPendulumWaveLoader>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Accumulated simulation time, seconds.
  double _t = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    // Closed-form solution: sample the analytic time directly so the
    // ensemble is exactly periodic (no integrator drift). The clamp only
    // guards against pathological stalls, e.g. a backgrounded app.
    double dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    dt = dt.clamp(0.0, 1 / 30);
    _t += dt * widget.timeScale;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WavePainter(
                  loader: widget,
                  t: _t,
                  stringColor: widget.stringColor,
                  barColor: widget.barColor,
                ),
              ),
            ),
            for (int i = 0; i < widget.count; i++)
              Positioned(
                left: widget.bobAt(i, _t).dx - widget.bobRadius,
                top: widget.bobAt(i, _t).dy - widget.bobRadius,
                child: IgnorePointer(
                  child: Container(
                    key: ValueKey<String>('sb-pwl-bob-$i'),
                    width: widget.bobRadius * 2,
                    height: widget.bobRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.bobColor,
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.4),
                        colors: [
                          widget.bobColor.withValues(alpha: 0.95),
                          widget.bobColor.withValues(alpha: 0.55),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.bobColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.loader,
    required this.t,
    required this.stringColor,
    required this.barColor,
  });

  final SbPendulumWaveLoader loader;
  final double t;
  final Color stringColor;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Support bar.
    final Paint bar = Paint()
      ..color = barColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;
    final double barY = loader.height * 0.14;
    canvas.drawLine(
      Offset(loader.width * 0.06, barY),
      Offset(loader.width * 0.94, barY),
      bar,
    );

    final Paint string = Paint()
      ..color = stringColor.withValues(alpha: 0.65)
      ..strokeWidth = 1.2;
    for (int i = 0; i < loader.count; i++) {
      canvas.drawLine(
        loader.pivotAt(i),
        loader.bobAt(i, t),
        string,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.loader != loader;
  }
}
