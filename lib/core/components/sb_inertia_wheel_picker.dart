import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

/// Phases of the picker's motion state machine.
enum _SbWheelPhase { idle, drag, ballistic, settle }

/// A vertical cylinder-wheel picker driven by real rotational physics.
///
/// Drag position is mapped to an arc angle on a wheel of radius
/// `itemExtent / angularPitch`. On release the wheel coasts under viscous
/// angular friction (exponential velocity decay, the exact solution of
/// `dw/dt = -k*w`), then a semi-implicit-Euler spring (stiffness +
/// damping torque) snaps it onto the nearest item detent.
///
/// Unlike [CupertinoPicker]-style list scrolling this widget owns its own
/// ticker, so the motion remains frame-rate independent: integration uses
/// the true ticker elapsed time clamped to a stable maximum step.
class SbInertiaWheelPicker extends StatefulWidget {
  const SbInertiaWheelPicker({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onSelectionChanged,
    this.itemExtent = 44.0,
    this.height = 240.0,
    this.angularPitch = math.pi / 7,
    this.friction = 3.2,
    this.springStiffness = 260.0,
    this.springDampingRatio = 0.78,
    this.maxFlingVelocity = 18.0,
    this.selectedKey,
    this.labelStyle,
  });

  /// Labels shown around the wheel.
  final List<String> items;

  /// Item selected before any interaction.
  final int initialIndex;

  /// Fired whenever the snapped (rounded) selection changes.
  final ValueChanged<int>? onSelectionChanged;

  /// Arc length per item slot, in logical pixels.
  final double itemExtent;

  /// Total widget height. Items outside it are clipped.
  final double height;

  /// Angle step between adjacent items, in radians. Wheel radius is
  /// `itemExtent / angularPitch` so the arc length per slot equals
  /// [itemExtent].
  final double angularPitch;

  /// Viscous angular friction coefficient (1/second) used during the
  /// ballistic coast phase.
  final double friction;

  /// Spring stiffness (rad/s^2 per unit error) of the detent snap.
  final double springStiffness;

  /// Damping ratio of the snap spring (1.0 = critically damped).
  final double springDampingRatio;

  /// Hard cap on fling velocity, in items/second.
  final double maxFlingVelocity;

  /// Optional [Key] attached to the currently centered item's text, useful
  /// for testing and semantics.
  final Key? selectedKey;

  final TextStyle? labelStyle;

  @override
  State<SbInertiaWheelPicker> createState() => _SbInertiaWheelPickerState();
}

class _SbInertiaWheelPickerState extends State<SbInertiaWheelPicker>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Continuous wheel position, in item units. `items[_position.round()]`
  /// is the item nearest the center.
  double _position = 0.0;

  /// Angular velocity expressed in items/second (dp/dt of [_position]).
  double _velocity = 0.0;

  _SbWheelPhase _phase = _SbWheelPhase.idle;
  double _settleTarget = 0.0;
  int _selectedIndex = 0;

  double get _radius => widget.itemExtent / widget.angularPitch;

  @override
  void initState() {
    super.initState();
    _position = widget.initialIndex
        .clamp(0, math.max(0, widget.items.length - 1))
        .toDouble();
    _selectedIndex = _position.round();
    _settleTarget = _position;
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startTicker() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop();
  }

  void _emitSelectionIfNeeded() {
    final int idx = _position.round().clamp(0, widget.items.length - 1);
    if (idx != _selectedIndex) {
      _selectedIndex = idx;
      widget.onSelectionChanged?.call(idx);
    }
  }

  /// Frame-rate independent integration of the current phase.
  void _onTick(Duration elapsed) {
    double dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    // Clamp the step so a stalled frame cannot destabilise the Euler
    // integration (standard fixed-step physics guard).
    dt = dt.clamp(0.0001, 1 / 30);

    final int last = widget.items.length - 1;

    switch (_phase) {
      case _SbWheelPhase.ballistic:
        // Exact solution of viscous friction: w' = -k w  =>  w *= e^{-k dt}
        _position += _velocity * dt;
        _velocity *= math.exp(-widget.friction * dt);
        // Hard stops at either end of a finite wheel kill the velocity.
        if (_position <= 0) {
          _position = 0;
          _velocity = 0;
        } else if (_position >= last) {
          _position = last.toDouble();
          _velocity = 0;
        }
        if (_velocity.abs() < 0.35) {
          _settleTarget = _position.round().clamp(0, last).toDouble();
          _phase = _SbWheelPhase.settle;
        }
        break;

      case _SbWheelPhase.settle:
        // Damped harmonic oscillator around the detent, semi-implicit
        // Euler: a = -k x - c v (c = 2 zeta sqrt(k)).
        final double x = _position - _settleTarget;
        final double c =
            2 * widget.springDampingRatio * math.sqrt(widget.springStiffness);
        final double a = -widget.springStiffness * x - c * _velocity;
        _velocity += a * dt;
        _position += _velocity * dt;
        if (x.abs() < 0.002 && _velocity.abs() < 0.02) {
          _position = _settleTarget;
          _velocity = 0;
          _phase = _SbWheelPhase.idle;
          _stopTicker();
        }
        break;

      case _SbWheelPhase.idle:
      case _SbWheelPhase.drag:
        _stopTicker();
        return;
    }

    _emitSelectionIfNeeded();
    setState(() {});
  }

  void _handleDragStart(DragStartDetails d) {
    _stopTicker();
    _velocity = 0;
    _phase = _SbWheelPhase.drag;
  }

  void _handleDragUpdate(DragUpdateDetails d) {
    // Direct manipulation: the surface follows the finger, so a downward
    // drag lowers the continuous position index.
    _position = (_position - d.delta.dy / widget.itemExtent).clamp(
      0.0,
      widget.items.length - 1.0,
    );
    _emitSelectionIfNeeded();
    setState(() {});
  }

  void _handleDragEnd(DragEndDetails d) {
    final double vy = d.velocity.pixelsPerSecond.dy;
    // Convert linear finger velocity to wheel velocity in items/second.
    _velocity = (-vy / widget.itemExtent).clamp(
      -widget.maxFlingVelocity,
      widget.maxFlingVelocity,
    );
    _phase = _velocity.abs() < 0.35
        ? _SbWheelPhase.settle
        : _SbWheelPhase.ballistic;
    if (_phase == _SbWheelPhase.settle) {
      _settleTarget = _position
          .round()
          .clamp(0, widget.items.length - 1)
          .toDouble();
    }
    _startTicker();
  }

  void _animateTo(int index) {
    _settleTarget = index.toDouble();
    // Keep coasting velocity for a natural feel; the spring absorbs it.
    _phase = _SbWheelPhase.settle;
    _startTicker();
  }

  List<Widget> _buildWheelItems() {
    final double r = _radius;
    final double half = widget.height / 2;
    final int center = _position.round();
    final int reach = (widget.angularPitch == 0)
        ? 0
        : math.min(
            widget.items.length,
            (math.pi / 2 / widget.angularPitch).ceil() + 1,
          );
    final List<Widget> children = [];
    for (int i = center - reach; i <= center + reach; i++) {
      if (i < 0 || i >= widget.items.length) continue;
      final double phi = (i - _position) * widget.angularPitch;
      final double y = r * math.sin(phi);
      final double cos = math.cos(phi);
      if (cos <= 0 || y.abs() > half + widget.itemExtent) continue;
      final double scale = (0.55 + 0.45 * cos).clamp(0.55, 1.0);
      final double opacity = math.pow(cos, 1.6).toDouble().clamp(0.0, 1.0);
      if (y.abs() > half) continue;
      children.add(
        Positioned(
          left: 0,
          right: 0,
          top: half - widget.itemExtent / 2 + y,
          child: IgnorePointer(
            ignoring: opacity < 0.25,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _animateTo(i),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    height: widget.itemExtent,
                    child: Center(
                      child: Text(
                        widget.items[i],
                        key: i == _selectedIndex ? widget.selectedKey : null,
                        style:
                            (widget.labelStyle ??
                                    const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ))
                                .copyWith(
                                  fontWeight: i == _selectedIndex
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._buildWheelItems(),
              // Selection indicator sits above the wheel at the focal line.
              IgnorePointer(
                child: Container(
                  height: widget.itemExtent,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.itemExtent / 2),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.5,
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
