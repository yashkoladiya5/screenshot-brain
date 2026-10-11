import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A gyro-style tilt container driven by a *cascade of two damped springs*.
///
/// Each axis runs two second-order oscillators in series:
///
/// ```
/// driver:    a = -k1 (x1 - target) - c1 v1        (+ injected fling velocity)
/// follower:  a = -k2 (x2 - x1)     - c2 v2
/// ```
///
/// i.e. the follower chases the driver, and the driver chases the finger.
/// Because the follower spring is softer than the driver spring, the visual
/// tilt (taken from the follower) lags and overshoots exactly like the
/// parallax layer of an iOS Home-Screen icon under the gyroscope: flick it
/// and it wobbles back to rest instead of snapping.
///
/// Both oscillators are integrated with semi-implicit Euler on the true
/// ticker delta (clamped for stability), so the motion is frame-rate
/// independent. Drag to tilt; release to let the springs ring out.
class SbDoubleSpringTilt extends StatefulWidget {
  const SbDoubleSpringTilt({
    super.key,
    required this.child,
    this.maxTiltRadians = math.pi / 7,
    this.driverStiffness = 190.0,
    this.driverDampingRatio = 0.55,
    this.followerStiffness = 95.0,
    this.followerDampingRatio = 0.38,
    this.dragSensitivity = 0.5,
    this.perspective = 0.0018,
    this.tiltKey,
    this.onTiltChanged,
  });

  /// The card/icon that will be tilted.
  final Widget child;

  /// Tilt reached when the finger sits at the edge of the tile.
  final double maxTiltRadians;

  /// Driver spring: stiffness (1/s^2) and damping ratio (1 = critical).
  final double driverStiffness;
  final double driverDampingRatio;

  /// Follower spring — deliberately softer so it lags the driver.
  final double followerStiffness;
  final double followerDampingRatio;

  /// Fraction of the half-width that maps to full tilt.
  final double dragSensitivity;

  /// Perspective depth fed into the matrix's w entries.
  final double perspective;

  /// Key attached to the transformed tile so tests can read the matrix.
  final Key? tiltKey;

  /// Reports (followerX, followerY) tilt angles in radians every frame.
  final ValueChanged<Offset>? onTiltChanged;

  /// One semi-implicit Euler step of a damped harmonic oscillator chasing
  /// [target]: `a = -k (x - target) - 2 zeta sqrt(k) v`.
  static ({double x, double v}) springStep({
    required double x,
    required double v,
    required double target,
    required double stiffness,
    required double dampingRatio,
    required double dt,
  }) {
    final double c = 2 * dampingRatio * math.sqrt(stiffness);
    final double a = -stiffness * (x - target) - c * v;
    final double vn = v + a * dt; // velocity first: semi-implicit
    return (x: x + vn * dt, v: vn);
  }

  @override
  State<SbDoubleSpringTilt> createState() => _SbDoubleSpringTiltState();
}

class _SbDoubleSpringTiltState extends State<SbDoubleSpringTilt>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Driver state (chases the finger / release target).
  double _dx = 0.0, _dvx = 0.0, _dy = 0.0, _dvy = 0.0;
  // Follower state (drives the visuals, chases the driver).
  double _fx = 0.0, _fvx = 0.0, _fy = 0.0, _fvy = 0.0;

  double _targetX = 0.0, _targetY = 0.0;
  bool _dragging = false;

  /// Fling velocity injection cap, rad/s, so wild swipes stay sane.
  static const double _maxKick = 14.0;

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

  bool get _atRest {
    const double epsPos = 1e-4, epsVel = 1e-3;
    return !_dragging &&
        _dx.abs() < epsPos &&
        _dy.abs() < epsPos &&
        _fx.abs() < epsPos &&
        _fy.abs() < epsPos &&
        _dvx.abs() < epsVel &&
        _dvy.abs() < epsVel &&
        _fvx.abs() < epsVel &&
        _fvy.abs() < epsVel &&
        _targetX == 0 &&
        _targetY == 0;
  }

  void _onTick(Duration elapsed) {
    double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    dt = dt.clamp(0.0001, 1 / 30);

    if (_atRest) {
      // Park the ticker when everything is exactly at rest; drag handlers
      // restart it. Saves a setState per frame on an idle tile.
      if (_ticker.isActive) _ticker.stop();
      return;
    }

    final ({double x, double v}) driverX = SbDoubleSpringTilt.springStep(
      x: _dx,
      v: _dvx,
      target: _targetX,
      stiffness: widget.driverStiffness,
      dampingRatio: widget.driverDampingRatio,
      dt: dt,
    );
    final ({double x, double v}) driverY = SbDoubleSpringTilt.springStep(
      x: _dy,
      v: _dvy,
      target: _targetY,
      stiffness: widget.driverStiffness,
      dampingRatio: widget.driverDampingRatio,
      dt: dt,
    );
    _dx = driverX.x;
    _dvx = driverX.v;
    _dy = driverY.x;
    _dvy = driverY.v;

    final ({double x, double v}) followerX = SbDoubleSpringTilt.springStep(
      x: _fx,
      v: _fvx,
      target: _dx,
      stiffness: widget.followerStiffness,
      dampingRatio: widget.followerDampingRatio,
      dt: dt,
    );
    final ({double x, double v}) followerY = SbDoubleSpringTilt.springStep(
      x: _fy,
      v: _fvy,
      target: _dy,
      stiffness: widget.followerStiffness,
      dampingRatio: widget.followerDampingRatio,
      dt: dt,
    );
    _fx = followerX.x;
    _fvx = followerX.v;
    _fy = followerY.x;
    _fvy = followerY.v;

    widget.onTiltChanged?.call(Offset(_fx, _fy));
    setState(() {});
  }

  void _ensureTicker() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  double _angleFromDx(double localDx, double width) =>
      ((localDx / (width / 2)).clamp(-1.0, 1.0) *
              widget.dragSensitivity *
              widget.maxTiltRadians)
          .toDouble();

  void _handleDragStart(DragStartDetails d) {
    _ensureTicker();
    _dragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails d, Size size) {
    _ensureTicker();
    _dragging = true;
    setState(() {
      _targetX = _angleFromDx(d.localPosition.dx, size.width);
      // Vertical drag tilts about the X axis; screen-y is downward, so the
      // rotation sign flips to feel like the tile faces the finger.
      _targetY = -_angleFromDx(d.localPosition.dy, size.height);
    });
  }

  void _handleDragEnd(DragEndDetails d) {
    _ensureTicker();
    _dragging = false;
    _targetX = 0.0;
    _targetY = 0.0;
    // Inject the fling velocity into the *driver* so the cascade rings:
    // pixels/s -> rad/s through the same mapping as position.
    final double scale =
        widget.dragSensitivity * widget.maxTiltRadians / (_halfWidth + 1e-6);
    _dvx = (_velocityX(d) * scale).clamp(-_maxKick, _maxKick).toDouble();
    _dvy = (_velocityY(d) * -scale).clamp(-_maxKick, _maxKick).toDouble();
  }

  double _halfWidth = 100;

  double _velocityX(DragEndDetails d) => d.velocity.pixelsPerSecond.dx;
  double _velocityY(DragEndDetails d) => d.velocity.pixelsPerSecond.dy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _halfWidth = constraints.maxWidth / 2;
        final Size size = constraints.biggest;
        final double m = math.max(size.width, size.height);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _handleDragStart,
          onPanUpdate: (d) => _handleDragUpdate(d, size),
          onPanEnd: _handleDragEnd,
          child: Transform(
            key: widget.tiltKey,
            alignment: Alignment.center,
            transform: _tiltMatrix(m),
            child: widget.child,
          ),
        );
      },
    );
  }

  /// Perspective rotation from the *follower* angles (the lagging,
  /// overshooting layer). Depth scales with tile size so small tiles bend
  /// less in absolute space, like a real card of that size.
  Matrix4 _tiltMatrix(double m) {
    final double depth = widget.perspective * (m / 300.0);
    final Matrix4 matrix = Matrix4(
      1, 0, 0, 0, //
      0, 1, 0, 0, //
      0, 0, 1, -depth, //
      0, 0, 0, 1, //
    );
    // The Matrix4 constructor fills column-major storage, so -depth above
    // sits at storage index 11 == entry(row 3, col 2): the standard
    // perspective w-entry (`Matrix4.identity()..setEntry(3, 2, -depth)`).
    matrix.rotateX(_fy);
    matrix.rotateY(_fx);
    return matrix;
  }
}
