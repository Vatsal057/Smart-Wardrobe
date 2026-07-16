import 'package:flutter/material.dart';
import '../theme.dart';

/// Color-coded wash status badge.
/// clean = green, wash_soon = amber, needs_wash = red.
class WashBadge extends StatelessWidget {
  final int washCount;
  final int washThreshold;
  final bool compact;

  const WashBadge({
    super.key,
    required this.washCount,
    required this.washThreshold,
    this.compact = false,
  });

  String get _status {
    if (washCount >= washThreshold) return 'needs_wash';
    if (washCount >= washThreshold - 1) return 'wash_soon';
    return 'clean';
  }

  Color get _color {
    switch (_status) {
      case 'needs_wash': return AppColors.red;
      case 'wash_soon': return AppColors.amber;
      default: return AppColors.green;
    }
  }

  Color get _bgColor {
    switch (_status) {
      case 'needs_wash': return AppColors.redFaint;
      case 'wash_soon': return AppColors.amberFaint;
      default: return AppColors.greenFaint;
    }
  }

  IconData get _icon {
    switch (_status) {
      case 'needs_wash': return Icons.local_laundry_service;
      case 'wash_soon': return Icons.access_time;
      default: return Icons.check_circle_outline;
    }
  }

  String get _label {
    if (_status == 'needs_wash') return 'NEEDS WASH';
    return '$washCount / $washThreshold wears';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Icon(_icon, color: _color, size: 14);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 12),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTheme.micro.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
