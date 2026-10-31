import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A pixel-dissolve reveal driven by genuine value noise.
///
/// The child is revealed tile by tile: each grid cell owns a threshold
/// derived from a seeded 2-D value-noise field (integer lattice hashed with
/// an integer mixing function, bilinearly interpolated with a smoothstep
/// curve — the textbook value-noise construction, no RNG at paint time),
/// plus an optional radial bias so the dissolve can sweep outward from a
/// centre. A cell is fully visible once the global progress passes its
/// threshold, and softly fades in through a `feather` band before that.
///
/// The [AnimationController] only supplies the monotonic progress; the
/// *pattern* is pure noise math, so the dissolve never looks like a random
/// timer swap. Tap to replay.
class SbPixelDissolveReveal extends StatefulWidget {
  const SbPixelDissolveReveal({
    super.key,
    required this.child,
    this.pixelSize = 14.0,
    this.duration = const Duration(milliseconds: 1400),
    this.seed = 1337,
    this.feather = 0.22,
    this.radialBias = 0.35,
    this.radialCenter = const Offset(0.5, 0.5),
    this.autoPlay = true,
    this.outlineColor,
    this.onProgressChanged,
    this.onRevealCompleted,
  });

  /// Content being revealed.
  final Widget child;

  /// Edge of one dissolve tile, in logical pixels.
  final double pixelSize;

  /// Full reveal duration.
  final Duration duration;

  /// Noise seed; equal seeds produce identical dissolves.
  final int seed;

  /// Width of the soft fade band (in progress units) before a cell's
  /// threshold.
  final double feather;

  /// How strongly distance from [radialCenter] pushes a cell's threshold
  /// up (0 = pure noise, 1 = pure radial wipe + noise jitter).
  final double radialBias;

  /// Centre of the radial bias in normalised coordinates.
  final Offset radialCenter;

  /// Start the dissolve immediately after the first frame.
  final bool autoPlay;

  /// When non-null, cells currently inside the feather band are outlined,
  /// giving the leading edge a "crunch" of live pixels.
  final Color? outlineColor;

  /// Reports progress in `[0, 1]` every frame.
  final ValueChanged<double>? onProgressChanged;

  /// Fired once when the dissolve reaches full reveal.
  final VoidCallback? onRevealCompleted;

  /// Integer hash of a lattice point + seed, mapped to `[0, 1)`.
  /// Thomas Wang's 32-bit mixer, the standard building block of fast
  /// lattice noise.
  static double hashPoint(int x, int y, int seed) {
    int h = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0xFFFFFFFF;
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF;
    h = (h ^ (h >> 16)) & 0xFFFFFFFF;
    return h / 4294967296.0;
  }

  /// 2-D value noise at (`x`, `y`): bilinear interpolation of the hashed
  /// integer lattice using the smootherstep `6t^5 - 15t^4 + 10t^3` curve,
  /// which has zero first *and* second derivatives at the cell borders —
  /// that is what keeps the noise field visually smooth.
  static double valueNoise2d(double x, double y, int seed) {
    final int ix = x.floor();
    final int iy = y.floor();
    final double fx = x - ix;
    final double fy = y - iy;
    double s(double t) => t * t * t * (t * (t * 6 - 15) + 10);
    final double sx = s(fx);
    final double sy = s(fy);
    final double n00 = hashPoint(ix, iy, seed);
    final double n10 = hashPoint(ix + 1, iy, seed);
    final double n01 = hashPoint(ix, iy + 1, seed);
    final double n11 = hashPoint(ix + 1, iy + 1, seed);
    final double a = n00 + sx * (n10 - n00);
    final double b = n01 + sx * (n11 - n01);
    return a + sy * (b - a);
  }

  /// Reveal threshold of the cell at grid coordinate (`col`, `row`):
  /// `base + (1 - bias) * noise + bias * normalisedRadialDistance`,
  /// normalised so thresholds span roughly `[0, 1]`.
  static double cellThreshold({
    required int col,
    required int row,
    required int cols,
    required int rows,
    required int seed,
    required double radialBias,
    required Offset radialCenter,
  }) {
    final double noise = valueNoise2d(col * 0.53 + 0.17, row * 0.53 + 0.71, seed);
    final double cx = (cols <= 1) ? 0.0 : col / (cols - 1);
    final double cy = (rows <= 1) ? 0.0 : row / (rows - 1);
    final double d = Offset(cx - radialCenter.dx, cy - radialCenter.dy).distance;
    final double dMax =
        math.max(1e-6, Offset(1 - radialCenter.dx, 1 - radialCenter.dy).distance);
    final double radial = (d / dMax).clamp(0.0, 1.0);
    final double mixed = (1 - radialBias) * noise + radialBias * radial;
    // Normalise by the maximum a convex blend can reach (1.0) and keep a
    // small floor so corner cells are not revealed at t == 0.
    return (0.04 + 0.96 * mixed).clamp(0.0, 1.0);
  }

  @override
  State<SbPixelDissolveReveal> createState() => _SbPixelDissolveRevealState();
}

class _SbPixelDissolveRevealState extends State<SbPixelDissolveReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed) {
          _completed = true;
          widget.onRevealCompleted?.call();
        }
      });
    if (widget.autoPlay) _run();
  }

  @override
  void didUpdateWidget(covariant SbPixelDissolveReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    if (_started) return;
    _started = true;
    _completed = false;
    _controller.forward(from: 0.0);
  }

  void _handleTap() {
    _started = true;
    _completed = false;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Size size = constraints.biggest;
          // A zero pixel size divided to Infinity, and Infinity.ceil() throws;
          // a near-zero one would ask for millions of tiles instead.
          final double pixel = math.max(1.0, widget.pixelSize);
          final int cols = math.max(1, (size.width / pixel).ceil());
          final int rows = math.max(1, (size.height / pixel).ceil());
          return AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final double progress = _controller.value;
              if (_started) widget.onProgressChanged?.call(progress);
              return Stack(
                fit: StackFit.passthrough,
                children: [
                  // The child is only painted inside cells whose noise
                  // threshold the progress has passed.
                  PixelDissolveMask(
                    progress: progress,
                    pixelSize: widget.pixelSize,
                    seed: widget.seed,
                    radialBias: widget.radialBias,
                    radialCenter: widget.radialCenter,
                    child: child!,
                  ),
                  // Leading-edge "dust" tiles that are about to appear.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DissolvePainter(
                        progress: progress,
                        pixelSize: widget.pixelSize,
                        cols: cols,
                        rows: rows,
                        seed: widget.seed,
                        feather: widget.feather,
                        radialBias: widget.radialBias,
                        radialCenter: widget.radialCenter,
                        outlineColor: widget.outlineColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DissolvePainter extends CustomPainter {
  _DissolvePainter({
    required this.progress,
    required this.pixelSize,
    required this.cols,
    required this.rows,
    required this.seed,
    required this.feather,
    required this.radialBias,
    required this.radialCenter,
    required this.outlineColor,
  });

  final double progress;
  final double pixelSize;
  final int cols;
  final int rows;
  final int seed;
  final double feather;
  final double radialBias;
  final Offset radialCenter;
  final Color? outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw only the cells inside the live feather band (about to appear),
    // so the leading edge visibly crackles.
    if (progress >= 1.0 || feather <= 0) return;
    final Paint dust = Paint()..style = PaintingStyle.fill;
    final Paint edge = outlineColor == null
        ? dust
        : (Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = outlineColor!);
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double t = SbPixelDissolveReveal.cellThreshold(
          col: col,
          row: row,
          cols: cols,
          rows: rows,
          seed: seed,
          radialBias: radialBias,
          radialCenter: radialCenter,
        );
        final double k = (progress - (t - feather)) / feather;
        if (k <= 0 || k >= 1) continue; // outside the live feather band
        final Rect cell = Rect.fromLTWH(
          col * pixelSize,
          row * pixelSize,
          math.min(pixelSize, size.width - col * pixelSize),
          math.min(pixelSize, size.height - row * pixelSize),
        );
        if (outlineColor != null) {
          canvas.drawRect(cell, edge);
        }
        dust.color = Colors.white.withValues(alpha: 0.10 * (1 - k));
        canvas.drawRect(cell, dust);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DissolvePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seed != seed ||
        oldDelegate.pixelSize != pixelSize ||
        oldDelegate.cols != cols ||
        oldDelegate.rows != rows ||
        oldDelegate.radialBias != radialBias ||
        oldDelegate.outlineColor != outlineColor;
  }
}

/// Wraps [child] so it is only drawn inside cells whose noise threshold the
/// [progress] has passed. Kept as a separate painter-driven clip so the
/// reveal math above and the masking stay in one file.
class PixelDissolveMask extends StatelessWidget {
  const PixelDissolveMask({
    super.key,
    required this.progress,
    required this.pixelSize,
    required this.seed,
    required this.radialBias,
    required this.radialCenter,
    required this.child,
  });

  final double progress;
  final double pixelSize;
  final int seed;
  final double radialBias;
  final Offset radialCenter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = constraints.biggest;
        final int cols = math.max(1, (size.width / pixelSize).ceil());
        final int rows = math.max(1, (size.height / pixelSize).ceil());
        final Path visible = Path();
        for (int row = 0; row < rows; row++) {
          for (int col = 0; col < cols; col++) {
            final double t = SbPixelDissolveReveal.cellThreshold(
              col: col,
              row: row,
              cols: cols,
              rows: rows,
              seed: seed,
              radialBias: radialBias,
              radialCenter: radialCenter,
            );
            if (progress >= t) {
              visible.addRect(Rect.fromLTWH(
                  col * pixelSize, row * pixelSize, pixelSize, pixelSize));
            }
          }
        }
        return ClipPath(clipper: _CellClipper(visible), child: child);
      },
    );
  }
}

class _CellClipper extends CustomClipper<Path> {
  _CellClipper(this.path);
  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _CellClipper oldClipper) =>
      oldClipper.path != path;
}
