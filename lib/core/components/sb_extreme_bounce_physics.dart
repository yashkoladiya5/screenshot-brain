import 'package:flutter/material.dart';
import 'dart:math' as math;

class SbExtremeBouncePhysics extends ScrollPhysics {
  final double frictionFactor;
  final double bounceSpringFactor;

  const SbExtremeBouncePhysics({
    super.parent,
    this.frictionFactor = 0.4,
    this.bounceSpringFactor = 0.8,
  });

  @override
  SbExtremeBouncePhysics applyTo(ScrollPhysics? ancestor) {
    return SbExtremeBouncePhysics(
      parent: buildParent(ancestor),
      frictionFactor: frictionFactor,
      bounceSpringFactor: bounceSpringFactor,
    );
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

    final double friction = easing
        ? frictionFactor * math.pow(0.9, overscrollPast / 20.0).toDouble()
        : frictionFactor;
    
    return offset * friction;
  }

  @override
  SpringDescription get spring {
    return SpringDescription.withDampingRatio(
      mass: 0.5,
      stiffness: 100.0 * bounceSpringFactor,
      ratio: 0.8,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return 0.0; 
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    
    if (position.outOfRange) {
      double? snapBackVelocity;
      if (position.pixels > position.maxScrollExtent) {
        snapBackVelocity = (position.pixels - position.maxScrollExtent) < 10.0 && velocity.abs() < tolerance.velocity 
            ? 0.0 : velocity;
      } else if (position.pixels < position.minScrollExtent) {
        snapBackVelocity = (position.minScrollExtent - position.pixels) < 10.0 && velocity.abs() < tolerance.velocity 
            ? 0.0 : velocity;
      }
      
      if (snapBackVelocity != null) {
        return ScrollSpringSimulation(
          spring,
          position.pixels,
          position.pixels < position.minScrollExtent ? position.minScrollExtent : position.maxScrollExtent,
          snapBackVelocity,
          tolerance: tolerance,
        );
      }
    }
    
    if (velocity.abs() > tolerance.velocity) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    
    return null;
  }

  @override
  bool get allowImplicitScrolling => true;
}

class SbExtremeBouncingWrapper extends StatelessWidget {
  final Widget child;
  
  const SbExtremeBouncingWrapper({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        physics: const SbExtremeBouncePhysics(
          frictionFactor: 0.8, 
          bounceSpringFactor: 0.3, 
        ),
      ),
      child: child,
    );
  }
}
