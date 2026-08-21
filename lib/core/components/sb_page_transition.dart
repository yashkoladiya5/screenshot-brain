import 'package:flutter/material.dart';

enum SbTransitionType { fade, slideRight, slideLeft, slideUp, slideDown, scale, size }

class SbPageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SbTransitionType type;
  final Duration duration;
  final Curve curve;
  final Alignment? alignment;

  SbPageTransition({
    required this.child,
    this.type = SbTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case SbTransitionType.fade:
                return FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case SbTransitionType.scale:
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  alignment: alignment ?? Alignment.center,
                  child: child,
                );
              case SbTransitionType.size:
                return Align(
                  alignment: alignment ?? Alignment.center,
                  child: SizeTransition(
                    sizeFactor: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: curve),
                    ),
                    child: child,
                  ),
                );
              case SbTransitionType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case SbTransitionType.slideLeft:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case SbTransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
              case SbTransitionType.slideDown:
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
                    CurvedAnimation(parent: animation, curve: curve),
                  ),
                  child: child,
                );
            }
          },
        );
}
