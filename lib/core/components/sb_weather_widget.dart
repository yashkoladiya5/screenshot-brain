import 'package:flutter/material.dart';
import '../design/tokens.dart';

enum SbWeatherType { sunny, cloudy, rainy, stormy, snowy }

class SbWeatherWidget extends StatelessWidget {
  final String locationName;
  final int currentTemp;
  final int highTemp;
  final int lowTemp;
  final SbWeatherType weatherType;
  final String description;

  const SbWeatherWidget({
    super.key,
    required this.locationName,
    required this.currentTemp,
    required this.highTemp,
    required this.lowTemp,
    required this.weatherType,
    required this.description,
  });

  Color _getBgColor() {
    switch (weatherType) {
      case SbWeatherType.sunny:
        return Colors.orange.shade400;
      case SbWeatherType.cloudy:
        return Colors.blueGrey.shade400;
      case SbWeatherType.rainy:
        return Colors.blue.shade600;
      case SbWeatherType.stormy:
        return Colors.indigo.shade800;
      case SbWeatherType.snowy:
        return Colors.lightBlue.shade200;
    }
  }

  IconData _getIcon() {
    switch (weatherType) {
      case SbWeatherType.sunny:
        return Icons.wb_sunny_rounded;
      case SbWeatherType.cloudy:
        return Icons.cloud_rounded;
      case SbWeatherType.rainy:
        return Icons.water_drop_rounded;
      case SbWeatherType.stormy:
        return Icons.thunderstorm_rounded;
      case SbWeatherType.snowy:
        return Icons.ac_unit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _getBgColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SBSpacing.xl),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SBRadius.xl),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background abstract icon
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              _getIcon(),
              size: 150,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
              const SizedBox(height: SBSpacing.xxl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currentTemp°',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'H:$highTemp°',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: SBSpacing.md),
                        Text(
                          'L:$lowTemp°',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
