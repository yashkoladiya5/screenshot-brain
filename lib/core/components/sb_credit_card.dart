import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCreditCard extends StatelessWidget {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final Color? colorStart;
  final Color? colorEnd;
  final bool isMasked;
  final Widget? logo;

  const SbCreditCard({
    super.key,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    this.colorStart,
    this.colorEnd,
    this.isMasked = true,
    this.logo,
  });

  String _formatCardNumber(String number, bool mask) {
    // Remove all non-digits
    final clean = number.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '•••• •••• •••• ••••';

    String formatted = '';
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      
      // Mask all but last 4
      if (mask && i < clean.length - 4) {
        formatted += '•';
      } else {
        formatted += clean[i];
      }
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final start = colorStart ?? colorScheme.primary;
    final end = colorEnd ?? colorScheme.tertiary;

    return AspectRatio(
      aspectRatio: 1.586, // Standard credit card aspect ratio (85.6mm / 53.98mm)
      child: Container(
        padding: const EdgeInsets.all(SBSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SBRadius.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start, end],
          ),
          boxShadow: [
            BoxShadow(
              color: start.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Chip and Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // EMV Chip
                    Container(
                      width: 45,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(SBRadius.sm),
                        border: Border.all(
                          color: Colors.amber.shade400,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ChipPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (logo != null) logo!,
                  ],
                ),
                
                // Card Number
                Text(
                  _formatCardNumber(cardNumber, isMasked),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace', // Gives that fixed-width card number look
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                
                // Bottom Row: Holder and Expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cardHolder.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiryDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw chip contact lines
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      paint,
    );
    
    // Middle horizontal line
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
    
    // Rounded inner rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.4,
          height: size.height * 0.6,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
