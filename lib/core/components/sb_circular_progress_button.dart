import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCircularProgressButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;

  const SbCircularProgressButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.icon = Icons.arrow_forward_rounded,
    this.size = 56.0,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final buttonColor = color ?? colorScheme.primary;
    final fgColor = iconColor ?? colorScheme.onPrimary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                color: buttonColor,
                valueColor: AlwaysStoppedAnimation<Color>(buttonColor.withValues(alpha: 0.5)),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: isLoading ? size - 12 : size,
            height: isLoading ? size - 12 : size,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: isLoading ? null : onPressed,
              elevation: isLoading ? 0 : 4,
              backgroundColor: buttonColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SBRadius.full),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: fgColor,
                      ),
                    )
                  : Icon(icon),
            ),
          ),
        ],
      ),
    );
  }
}
