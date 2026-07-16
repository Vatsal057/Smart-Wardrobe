import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../components/health_ring.dart';
import '../components/streak_badge.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _health;
  Map<String, dynamic>? _capsule;
  Map<String, dynamic>? _streak;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getHealthScore(),
        ApiService.getCapsule(),
        ApiService.getStreak(),
      ]);
      _health = results[0]; _capsule = results[1]; _streak = results[2];
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.bgBase,
      body: const Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }

    return Scaffold(backgroundColor: AppColors.bgBase,
      body: SafeArea(child: RefreshIndicator(onRefresh: _load, color: AppColors.gold,
        child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
          Text('Insights', style: AppTheme.title), const SizedBox(height: AppSpacing.lg),
          // Streak
          if (_streak != null) ...[
            Row(children: [StreakBadge(streak: _streak!['current_streak'] ?? 0, size: 'lg'),
              const SizedBox(width: 12),
              Expanded(child: Text(_streak!['message'] ?? '', style: AppTheme.body.copyWith(color: AppColors.textSecondary, fontSize: 13)))]),
            const SizedBox(height: AppSpacing.xl)],
          // Health ring
          if (_health != null) ...[
            Center(child: HealthRing(score: _health!['score'] ?? 0)),
            const SizedBox(height: AppSpacing.md),
            // Component breakdown
            _components(),
            const SizedBox(height: AppSpacing.xl)],
          // Capsule analysis
          if (_capsule != null) ...[
            Text('CAPSULE ANALYSIS', style: AppTheme.label), const SizedBox(height: 12),
            _capsuleCard('Most Versatile', Icons.star_outline,
              (_capsule!['most_versatile'] as List?)?.map((i) => i['name'].toString()).join(', ') ?? 'Not enough data'),
            _capsuleCard('Orphan Items', Icons.help_outline,
              (_capsule!['orphans'] as List?)?.map((i) => '${i['name']}: ${i['reason']}').join('\n') ?? 'None found'),
            _capsuleCard('Wardrobe Gaps', Icons.lightbulb_outline,
              (_capsule!['gaps'] as List?)?.join('\n') ?? 'No gaps'),
            _capsuleCard('Color Story', Icons.palette_outlined,
              (_capsule!['color_story'] as List?)?.map((c) => '${c['colors']}: ${c['description']}').join('\n') ?? 'Wear more outfits'),
          ],
        ]))));
  }

  Widget _components() {
    final comp = (_health?['components'] as Map<String, dynamic>?) ?? {};
    return Row(children: [
      _compChip('Utilization', comp['utilization'] ?? 0),
      const SizedBox(width: 8), _compChip('Rotation', comp['rotation'] ?? 0),
      const SizedBox(width: 8), _compChip('Freshness', comp['freshness'] ?? 0),
      const SizedBox(width: 8), _compChip('Wash', comp['wash'] ?? 0),
    ]);
  }

  Widget _compChip(String label, num value) => Expanded(child: Container(
    padding: const EdgeInsets.all(10), decoration: BoxDecoration(
      color: AppColors.bgSurface2, borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text('${(value * 100).toInt()}%', style: AppTheme.body.copyWith(fontSize: 14, color: AppColors.gold)),
      const SizedBox(height: 2), Text(label.toUpperCase(), style: AppTheme.micro.copyWith(fontSize: 8))])));

  Widget _capsuleCard(String title, IconData icon, String content) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: AppColors.gold, size: 18), const SizedBox(width: 8),
        Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w500))]),
      const SizedBox(height: 8),
      Text(content, style: AppTheme.body.copyWith(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
    ]));
}
