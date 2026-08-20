import 'package:flutter/material.dart';

class SbExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String expandText;
  final String collapseText;

  const SbExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.expandText = 'Read More',
    this.collapseText = 'Show Less',
  });

  @override
  State<SbExpandableText> createState() => _SbExpandableTextState();
}

class _SbExpandableTextState extends State<SbExpandableText> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final defaultStyle = widget.style ?? theme.textTheme.bodyMedium!;
    final linkStyle = defaultStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    return LayoutBuilder(
      builder: (context, size) {
        // Build a TextSpan to see if it exceeds maxLines
        final span = TextSpan(text: widget.text, style: defaultStyle);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: size.maxWidth);

        if (tp.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: defaultStyle,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Text(
                  _isExpanded ? widget.collapseText : widget.expandText,
                  style: linkStyle,
                ),
              ),
            ],
          );
        } else {
          return Text(widget.text, style: defaultStyle);
        }
      },
    );
  }
}
