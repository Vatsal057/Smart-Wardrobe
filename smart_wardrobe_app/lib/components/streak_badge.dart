import 'package:flutter/material.dart';
import '../theme.dart';

/// Streak badge with fire icon and count.
class StreakBadge extends StatelessWidget {
  final int streak;
  final String size; // 'sm', 'md', 'lg'

  const StreakBadge({super.key, required this.streak, this.size = 'md'});

  double get _iconSize {
    switch (size) {
      case 'sm': return 12;
      case 'lg': return 28;
      default: return 18;
    }
  }

  double get _fontSize {
    switch (size) {
      case 'sm': return 12;
      case 'lg': return 32;
      default: return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: AppColors.gold, size: _iconSize),
        const SizedBox(width: 4),
        Text(
          '$streak',
          style: size == 'lg'
              ? AppTheme.metricValue.copyWith(fontSize: _fontSize, color: AppColors.gold)
              : AppTheme.body.copyWith(fontSize: _fontSize, color: AppColors.gold, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
