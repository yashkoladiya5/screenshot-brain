import 'package:flutter/material.dart';
import '../design/tokens.dart';

class SbCreditCardDisplay extends StatelessWidget {
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final bool isMasked;
  final Color? startColor;
  final Color? endColor;
  final Widget? customLogo;

  const SbCreditCardDisplay({
    super.key,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    this.isMasked = true,
    this.startColor,
    this.endColor,
    this.customLogo,
  });

  String get _displayCardNumber {
    if (cardNumber.isEmpty) return '**** **** **** ****';
    
    // Remove all non-digits
    final digitsOnly = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    // Mask logic
    if (isMasked && digitsOnly.length >= 4) {
      final last4 = digitsOnly.substring(digitsOnly.length - 4);
      return '**** **** **** $last4';
    }

    // Add spaces every 4 digits for formatting if not masked
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      if ((i + 1) % 4 == 0 && i != digitsOnly.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString().padRight(19, '*').replaceAll('*', '* ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final gradientStart = startColor ?? colorScheme.primary;
    final gradientEnd = endColor ?? colorScheme.tertiary;

    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(SBSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SBRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decor elements
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
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          // Card Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // EMV Chip mock
                  Container(
                    width: 45,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(SBRadius.sm),
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade200, Colors.amber.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            width: 25,
                            height: 15,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12, width: 1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (customLogo != null)
                    customLogo!
                  else
                    const Icon(
                      Icons.credit_card_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayCardNumber,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SBSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cardHolderName.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VALID THRU',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expiryDate,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
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
        ],
      ),
    );
  }
}
