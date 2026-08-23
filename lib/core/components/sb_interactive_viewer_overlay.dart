import 'package:flutter/material.dart';

class SbInteractiveViewerOverlay extends StatelessWidget {
  final Widget child;
  final double maxScale;
  final double minScale;

  const SbInteractiveViewerOverlay({
    super.key,
    required this.child,
    this.maxScale = 4.0,
    this.minScale = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withValues(alpha: 0.9),
            barrierDismissible: true,
            pageBuilder: (context, _, __) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      maxScale: maxScale,
                      minScale: minScale,
                      child: Center(
                        child: Hero(
                          tag: child.hashCode,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      child: Hero(
        tag: child.hashCode,
        child: child,
      ),
    );
  }
}
