import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbRangeSlider extends StatefulWidget {
  final double min;
  final double max;
  final double initialStart;
  final double initialEnd;
  final ValueChanged<RangeValues> onChanged;
  final String? prefixLabel;
  final String? suffixLabel;
  final Color? activeColor;
  final Color? inactiveColor;

  const SbRangeSlider({
    super.key,
    required this.min,
    required this.max,
    required this.initialStart,
    required this.initialEnd,
    required this.onChanged,
    this.prefixLabel,
    this.suffixLabel,
    this.activeColor,
    this.inactiveColor,
  }) : assert(min < max),
       assert(initialStart >= min && initialStart <= max),
       assert(initialEnd >= min && initialEnd <= max),
       assert(initialStart <= initialEnd);

  @override
  State<SbRangeSlider> createState() => _SbRangeSliderState();
}

class _SbRangeSliderState extends State<SbRangeSlider> {
  late RangeValues _currentValues;

  @override
  void initState() {
    super.initState();
    _currentValues = RangeValues(widget.initialStart, widget.initialEnd);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final active = widget.activeColor ?? colorScheme.primary;
    final inactive = widget.inactiveColor ?? colorScheme.surfaceContainerHighest;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.prefixLabel ?? ''}${_currentValues.start.toInt()}${widget.suffixLabel ?? ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: active,
              ),
            ),
            Text(
              '${widget.prefixLabel ?? ''}${_currentValues.end.toInt()}${widget.suffixLabel ?? ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: active,
              ),
            ),
          ],
        ),
        const SizedBox(height: SBSpacing.sm),
        
        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: active,
            inactiveTrackColor: inactive,
            thumbColor: colorScheme.surface,
            overlayColor: active.withValues(alpha: 0.2),
            trackHeight: 8.0,
            rangeThumbShape: _CustomRangeThumbShape(
              thumbRadius: 12.0,
              borderColor: active,
              borderWidth: 3.0,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            values: _currentValues,
            min: widget.min,
            max: widget.max,
            onChanged: (RangeValues values) {
              setState(() {
                _currentValues = values;
              });
              widget.onChanged(values);
            },
          ),
        ),
        
        // Min/Max Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.min.toInt()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${widget.max.toInt()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomRangeThumbShape extends RangeSliderThumbShape {
  final double thumbRadius;
  final Color borderColor;
  final double borderWidth;

  const _CustomRangeThumbShape({
    required this.thumbRadius,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    SliderThemeData? sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;

    // Draw shadow
    final Path shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: thumbRadius));
    canvas.drawShadow(shadowPath, Colors.black, 4.0, true);

    // Draw fill
    final fillPaint = Paint()
      ..color = sliderTheme?.thumbColor ?? Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, thumbRadius, borderPaint);
  }
}
