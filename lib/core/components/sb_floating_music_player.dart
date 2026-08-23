import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbFloatingMusicPlayer extends StatefulWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final bool initialPlayingState;
  final VoidCallback onPlayPauseToggle;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final double progress; // 0.0 to 1.0

  const SbFloatingMusicPlayer({
    super.key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.onPlayPauseToggle,
    required this.onNext,
    required this.onPrevious,
    this.initialPlayingState = false,
    this.progress = 0.0,
  }) : assert(progress >= 0.0 && progress <= 1.0);

  @override
  State<SbFloatingMusicPlayer> createState() => _SbFloatingMusicPlayerState();
}

class _SbFloatingMusicPlayerState extends State<SbFloatingMusicPlayer> with SingleTickerProviderStateMixin {
  late bool _isPlaying;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.initialPlayingState;
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (_isPlaying) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(SbFloatingMusicPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPlayingState != oldWidget.initialPlayingState) {
      setState(() {
        _isPlaying = widget.initialPlayingState;
        if (_isPlaying) {
          _spinController.repeat();
        } else {
          _spinController.stop();
        }
      });
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _handlePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    });
    widget.onPlayPauseToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SBSpacing.md, vertical: SBSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(SBRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SBRadius.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(SBSpacing.md),
              child: Row(
                children: [
                  // Spinning Record Avatar
                  RotationTransition(
                    turns: _spinController,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.music_note_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: SBSpacing.md),
                  // Track Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.artist,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        color: colorScheme.onSurface,
                        onPressed: widget.onPrevious,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              key: ValueKey(_isPlaying),
                            ),
                          ),
                          color: colorScheme.primary,
                          onPressed: _handlePlayPause,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        color: colorScheme.onSurface,
                        onPressed: widget.onNext,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom Progress Bar
            Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 4,
                  width: MediaQuery.sizeOf(context).width * widget.progress,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
