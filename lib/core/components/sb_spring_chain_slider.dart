import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A range slider whose two thumbs are physical masses on a spring chain.
///
/// Each thumb has
///
/// * an *anchor spring* pulling it back to its home fraction, and
/// * a *coupling spring* connecting it to the other thumb,
///
/// so the free end follows the dragged end with real lag and overshoot:
///
/// ```
/// a_i   = -k_anchor (p_i - home_i) + k_couple (p_j - p_i) - c v_i
/// c     = 2 zeta sqrt(k_anchor + k_couple)
/// ```
///
/// integrated with semi-implicit Euler (`v += a dt; p += v dt`) on the
/// ticker's true delta, clamped for stability. The dragged thumb is
/// kinematic (it follows the finger exactly); on release it becomes dynamic
/// too and the whole chain rings back to its homes. Track ends act as
/// fully inelastic stops (position clamped, velocity zeroed). Reported
/// values are the `[min, max]` of the two thumb fractions, so even
/// crossing thumbs yield a sane range.
class SbSpringChainSlider extends StatefulWidget {
  const SbSpringChainSlider({
    super.key,
    this.width = 280.0,
    this.initialStart = 0.28,
    this.initialEnd = 0.72,
    this.anchorStiffness = 160.0,
    this.couplingStiffness = 240.0,
    this.dampingRatio = 0.42,
    this.activeTrackColor = const Color(0xFF26A69A),
    this.thumbColor = const Color(0xFFECEFF1),
    this.trackColor = const Color(0xFF37474F),
    this.thumbRadius = 11.0,
    this.leftThumbKey,
    this.rightThumbKey,
    this.onRangeChanged,
  });

  /// Track width in logical pixels.
  final double width;

  /// Home (and initial) positions as fractions of the track.
  final double initialStart;
  final double initialEnd;

  /// Anchor spring stiffness (1/s^2 in fraction units).
  final double anchorStiffness;

  /// Coupling spring stiffness between the thumbs.
  final double couplingStiffness;

  /// Damping ratio of both thumb oscillators (1 = critically damped).
  final double dampingRatio;

  final Color activeTrackColor;
  final Color thumbColor;
  final Color trackColor;
  final double thumbRadius;

  /// Keys on the thumb widgets for geometry assertions.
  final Key? leftThumbKey;
  final Key? rightThumbKey;

  /// Emits the live `[min, max]` thumb range in track fractions.
  final ValueChanged<RangeValues>? onRangeChanged;

  /// One semi-implicit Euler step for a free thumb under anchor +
  /// coupling forces:
  /// `a = -ka (p - home) + kc ((other - p) + couplingBias) - 2 zeta sqrt(ka+kc) v`.
  ///
  /// [couplingBias] is the signed rest gap of the coupling spring
  /// (`∓(home2 - home1)`), so the spring is relaxed — and both thumbs rest
  /// exactly at their anchor homes — when they sit at their initial
  /// positions.
  static ({double p, double v}) integrateThumb({
    required double p,
    required double v,
    required double home,
    required double other,
    required double anchorStiffness,
    required double couplingStiffness,
    required double dampingRatio,
    required double dt,
    double couplingBias = 0.0,
  }) {
    final double kEff = anchorStiffness + couplingStiffness;
    final double c = 2 * dampingRatio * (kEff > 0 ? math.sqrt(kEff) : 0.0);
    final double a = -anchorStiffness * (p - home) +
        couplingStiffness * (other - p + couplingBias) -
        c * v;
    final double vn = v + a * dt;
    return (p: p + vn * dt, v: vn);
  }

  @override
  State<SbSpringChainSlider> createState() => _SbSpringChainSliderState();
}

/// Which thumb (if any) the finger currently owns.
enum SbChainThumb { none, first, second }

class _SbSpringChainSliderState extends State<SbSpringChainSlider>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  late double _p1; // fraction along the track, thumb 1
  late double _p2;
  double _v1 = 0.0; // fraction/second
  double _v2 = 0.0;
  SbChainThumb _dragged = SbChainThumb.none;

  late final double _home1;
  late final double _home2;

  @override
  void initState() {
    super.initState();
    _home1 = widget.initialStart.clamp(0.0, 1.0);
    _home2 = widget.initialEnd.clamp(0.0, 1.0);
    _p1 = _home1;
    _p2 = _home2;
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _atRest =>
      _dragged == SbChainThumb.none &&
      (_p1 - _home1).abs() < 1e-4 &&
      (_p2 - _home2).abs() < 1e-4 &&
      _v1.abs() < 1e-3 &&
      _v2.abs() < 1e-3;

  void _ensureTicker() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    dt = dt.clamp(0.0001, 1 / 30);

    if (_atRest) {
      _p1 = _home1;
      _p2 = _home2;
      _v1 = 0;
      _v2 = 0;
      if (_ticker.isActive) _ticker.stop();
      return;
    }

    final bool kinematic1 = _dragged == SbChainThumb.first;
    final bool kinematic2 = _dragged == SbChainThumb.second;

    if (!kinematic1) {
      final ({double p, double v}) s1 =
          SbSpringChainSlider.integrateThumb(
        p: _p1,
        v: _v1,
        home: _home1,
        other: _p2,
        anchorStiffness: widget.anchorStiffness,
        couplingStiffness: widget.couplingStiffness,
        dampingRatio: widget.dampingRatio,
        dt: dt,
        couplingBias: -(_home2 - _home1),
      );
      _p1 = s1.p;
      _v1 = s1.v;
    }
    if (!kinematic2) {
      final ({double p, double v}) s2 =
          SbSpringChainSlider.integrateThumb(
        p: _p2,
        v: _v2,
        home: _home2,
        other: _p1,
        anchorStiffness: widget.anchorStiffness,
        couplingStiffness: widget.couplingStiffness,
        dampingRatio: widget.dampingRatio,
        dt: dt,
        couplingBias: _home2 - _home1,
      );
      _p2 = s2.p;
      _v2 = s2.v;
    }

    // Inelastic end stops: clamp onto the track and kill the velocity.
    if (_p1 <= 0) {
      _p1 = 0;
      _v1 = 0;
    } else if (_p1 >= 1) {
      _p1 = 1;
      _v1 = 0;
    }
    if (_p2 <= 0) {
      _p2 = 0;
      _v2 = 0;
    } else if (_p2 >= 1) {
      _p2 = 1;
      _v2 = 0;
    }

    widget.onRangeChanged?.call(
      RangeValues(
        _p1 < _p2 ? _p1 : _p2,
        _p1 < _p2 ? _p2 : _p1,
      ),
    );
    setState(() {});
  }

  void _apply(SbChainThumb which, double localX) {
    // Gesture deltas arrive in the thumb hit-box's local space; convert
    // back to track space with the same layout mapping the Stack uses.
    final double hit = widget.thumbRadius * 2.4;
    final double self = which == SbChainThumb.first ? _p1 : _p2;
    final double boxLeft = (self * widget.width - hit / 2)
        .clamp(0.0, widget.width - hit);
    final double f = ((boxLeft + localX) / widget.width).clamp(0.0, 1.0);
    if (which == SbChainThumb.first) {
      _p1 = f;
      _v1 = 0;
    } else if (which == SbChainThumb.second) {
      _p2 = f;
      _v2 = 0;
    }
  }

  void _beginDrag(SbChainThumb which, double localX) {
    _ensureTicker();
    setState(() {
      _dragged = which;
      _apply(which, localX);
    });
  }

  void _endDrag() {
    _ensureTicker();
    setState(() => _dragged = SbChainThumb.none);
  }

  Widget _thumb({
    required Key? key,
    required SbChainThumb which,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) => _beginDrag(which, d.localPosition.dx),
      onHorizontalDragUpdate: (d) =>
          setState(() => _apply(which, d.localPosition.dx)),
      onHorizontalDragEnd: (_) => _endDrag(),
      child: SizedBox(
        width: widget.thumbRadius * 2.4,
        height: widget.thumbRadius * 2.4,
        child: Center(
          child: Container(
            key: key,
            width: widget.thumbRadius * 2,
            height: widget.thumbRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.thumbColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double trackHeight = 6.0;
    final double hit = widget.thumbRadius * 2.4;
    final double cx1 = _p1 * widget.width;
    final double cx2 = _p2 * widget.width;
    final double lo = cx1 < cx2 ? cx1 : cx2;
    final double hi = cx1 < cx2 ? cx2 : cx1;
    return SizedBox(
      width: widget.width,
      height: hit,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Passive track.
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: trackHeight,
              decoration: BoxDecoration(
                color: widget.trackColor,
                borderRadius: BorderRadius.circular(trackHeight / 2),
              ),
            ),
          ),
          // Active span between the thumbs.
          Positioned(
            left: lo - widget.thumbRadius,
            width: (hi - lo) + widget.thumbRadius * 2,
            child: Container(
              height: trackHeight,
              decoration: BoxDecoration(
                color: widget.activeTrackColor,
                borderRadius: BorderRadius.circular(trackHeight / 2),
              ),
            ),
          ),
          Positioned(
            left: (cx1 - hit / 2).clamp(0.0, widget.width - hit),
            child: _thumb(key: widget.leftThumbKey, which: SbChainThumb.first),
          ),
          Positioned(
            left: (cx2 - hit / 2).clamp(0.0, widget.width - hit),
            child: _thumb(key: widget.rightThumbKey, which: SbChainThumb.second),
          ),
        ],
      ),
    );
  }
}
