import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../components/outfit_card.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  Map<String, dynamic>? _plan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getWeekPlan();
      setState(() { _plan = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.generatePlan();
      setState(() { _plan = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: FloatingActionButton(
        onPressed: _regenerate,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.refresh, color: Color(0xFF1A1208)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final days = (_plan?['days'] as List<dynamic>?) ?? [];
    final washAlert = _plan?['week_wash_alert'];

    return RefreshIndicator(
      onRefresh: _loadPlan,
      color: AppColors.gold,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text('Week', style: AppTheme.title),
          const SizedBox(height: AppSpacing.sm),
          if (_plan?['rotation_score'] != null)
            Text(
              'Rotation: ${((_plan!['rotation_score'] as num) * 100).toStringAsFixed(0)}%',
              style: AppTheme.caption,
            ),
          const SizedBox(height: AppSpacing.md),

          // Wash alert
          if (washAlert != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amberFaint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.amber, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      washAlert['message'] ?? 'Plan a wash this week',
                      style: AppTheme.caption.copyWith(color: AppColors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Day cards - horizontal scroll
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _dayCard(days[i]),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Detailed view for each day
          ...days.map((day) => _dayDetail(day)),
        ],
      ),
    );
  }

  Widget _dayCard(Map<String, dynamic> day) {
    final outfit = day['outfit'];
    final weather = day['weather'];
    final confirmed = day['confirmed'] == true;

    return Container(
      width: 130,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: confirmed ? AppColors.gold : AppColors.borderSubtle,
          width: confirmed ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (day['day_name'] as String? ?? '').substring(0, 3).toUpperCase(),
            style: AppTheme.label.copyWith(fontSize: 12),
          ),
          Text(day['date']?.toString().substring(5) ?? '', style: AppTheme.caption),
          const SizedBox(height: AppSpacing.sm),
          if (weather != null)
            Row(
              children: [
                Icon(Icons.thermostat_outlined, size: 12, color: AppColors.textTertiary),
                Text(' ${weather['temp_c']}°', style: AppTheme.caption.copyWith(fontSize: 10)),
                const SizedBox(width: 4),
                Icon(Icons.water_drop_outlined, size: 12, color: AppColors.textTertiary),
                Text(' ${weather['rain_pct']}%', style: AppTheme.caption.copyWith(fontSize: 10)),
              ],
            ),
          const Spacer(),
          if (outfit != null)
            Text(outfit['headline'] ?? '', style: AppTheme.caption.copyWith(color: AppColors.textPrimary, fontSize: 11), maxLines: 2)
          else
            Text('No outfit', style: AppTheme.caption),
          if (day['wash_warning'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.warning_amber, color: AppColors.amber, size: 14),
            ),
        ],
      ),
    );
  }

  Widget _dayDetail(Map<String, dynamic> day) {
    final outfit = day['outfit'];
    if (outfit == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day['day_name']} — ${day['occasion'] ?? 'casual'}',
            style: AppTheme.label,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutfitCard(
            outfit: outfit,
            showActions: !(day['worn'] == true),
            onWear: day['worn'] == true ? null : () async {
              await ApiService.markDayWorn(day['date']);
              _loadPlan();
            },
          ),
        ],
      ),
    );
  }
}
