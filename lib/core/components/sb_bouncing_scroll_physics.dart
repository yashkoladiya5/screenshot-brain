import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom ScrollPhysics that implements an exaggerated, springy bounce
/// similar to native iOS but with highly customizable mass, stiffness, and damping.
class SbBouncingScrollPhysics extends ScrollPhysics {
  final double springStiffness;
  final double springDamping;
  final double mass;

  const SbBouncingScrollPhysics({
    ScrollPhysics? parent,
    this.springStiffness = 200.0,
    this.springDamping = 15.0,
    this.mass = 0.5,
  }) : super(parent: parent);

  @override
  SbBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SbBouncingScrollPhysics(
      parent: buildParent(ancestor),
      springStiffness: springStiffness,
      springDamping: springDamping,
      mass: mass,
    );
  }

  @override
  SpringDescription get spring => SpringDescription(
        mass: mass,
        stiffness: springStiffness,
        damping: springDamping,
      );

  @override
  double frictionFactor(double overscrollFraction) {
    // Standard bouncing physics friction is 0.52 * pow(1 - overscroll, 2)
    // We make it slightly looser (0.6) for a more dramatic stretch
    return 0.6 * math.pow(1 - overscrollFraction, 2);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart = math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd = math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) || (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing ? frictionFactor(
        (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(double extentOutside, double absDelta, double friction) {
    double total = 0.0;
    double deltaToLimit = extentOutside;
    if (deltaToLimit < absDelta) {
      total += deltaToLimit * friction;
      absDelta -= deltaToLimit;
      friction = friction * 0.95; // Custom exponential decay on friction
    }
    total += absDelta * friction;
    return total;
  }

  @override
  bool get allowImplicitScrolling => true;
}
