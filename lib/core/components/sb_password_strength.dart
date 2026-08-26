import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbPasswordStrength { none, weak, fair, good, strong }

class SbPasswordStrengthMeter extends StatefulWidget {
  final String password;
  final double width;
  final int minLength;
  final bool requireUppercase;
  final bool requireNumbers;
  final bool requireSpecialChars;

  const SbPasswordStrengthMeter({
    super.key,
    required this.password,
    this.width = double.infinity,
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireNumbers = true,
    this.requireSpecialChars = true,
  });

  @override
  State<SbPasswordStrengthMeter> createState() => _SbPasswordStrengthMeterState();
}

class _SbPasswordStrengthMeterState extends State<SbPasswordStrengthMeter> {
  SbPasswordStrength _strength = SbPasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _calculateStrength(widget.password);
  }

  @override
  void didUpdateWidget(SbPasswordStrengthMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.password != oldWidget.password) {
      _calculateStrength(widget.password);
    }
  }

  void _calculateStrength(String password) {
    if (password.isEmpty) {
      setState(() => _strength = SbPasswordStrength.none);
      return;
    }

    int score = 0;

    // Length check
    if (password.length >= widget.minLength) score++;
    if (password.length >= widget.minLength + 4) score++; // Bonus for extra length

    // Character variety checks
    if (widget.requireUppercase && RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (widget.requireNumbers && RegExp(r'[0-9]').hasMatch(password)) score++;
    if (widget.requireSpecialChars && RegExp(r'[!@#\$&*~%]').hasMatch(password)) score++;

    SbPasswordStrength newStrength;
    if (score <= 1) {
      newStrength = SbPasswordStrength.weak;
    } else if (score == 2 || score == 3) {
      newStrength = SbPasswordStrength.fair;
    } else if (score == 4) {
      newStrength = SbPasswordStrength.good;
    } else {
      newStrength = SbPasswordStrength.strong;
    }

    if (newStrength != _strength) {
      setState(() {
        _strength = newStrength;
      });
    }
  }

  Color _getStrengthColor() {
    switch (_strength) {
      case SbPasswordStrength.none:
        return Colors.transparent;
      case SbPasswordStrength.weak:
        return Colors.red.shade400;
      case SbPasswordStrength.fair:
        return Colors.orange.shade400;
      case SbPasswordStrength.good:
        return Colors.blue.shade400;
      case SbPasswordStrength.strong:
        return Colors.green.shade400;
    }
  }

  String _getStrengthLabel() {
    switch (_strength) {
      case SbPasswordStrength.none:
        return '';
      case SbPasswordStrength.weak:
        return 'Weak';
      case SbPasswordStrength.fair:
        return 'Fair';
      case SbPasswordStrength.good:
        return 'Good';
      case SbPasswordStrength.strong:
        return 'Strong';
    }
  }
  
  double _getStrengthPercentage() {
    switch (_strength) {
      case SbPasswordStrength.none: return 0.0;
      case SbPasswordStrength.weak: return 0.25;
      case SbPasswordStrength.fair: return 0.5;
      case SbPasswordStrength.good: return 0.75;
      case SbPasswordStrength.strong: return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.colorScheme.surfaceContainerHighest;
    final activeColor = _getStrengthColor();

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _getStrengthLabel(),
                  key: ValueKey<SbPasswordStrength>(_strength),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SBSpacing.xs),
          Row(
            children: List.generate(4, (index) {
              final threshold = (index + 1) * 0.25;
              final currentPct = _getStrengthPercentage();
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < 3 ? SBSpacing.xs : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: currentPct >= threshold ? activeColor : inactive,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
