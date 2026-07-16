import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try { _stats = await ApiService.getStats(); } catch (_) {}
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
          Text('Stats', style: AppTheme.title), const SizedBox(height: AppSpacing.lg),
          // Main metrics
          Row(children: [
            _metric('Total Items', '${_stats?['total'] ?? 0}'),
            const SizedBox(width: 12), _metric('Total Wears', '${_stats?['total_wears'] ?? 0}'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _metric('Never Worn', '${_stats?['never_worn'] ?? 0}'),
            const SizedBox(width: 12), _metric('With Photos', '${_stats?['with_photos'] ?? 0}'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _metric('Clean', '${_stats?['clean_items_count'] ?? 0}'),
            const SizedBox(width: 12), _metric('Needs Wash', '${_stats?['needs_wash_count'] ?? 0}'),
          ]),
          const SizedBox(height: AppSpacing.xl),
          // By category
          Text('BY CATEGORY', style: AppTheme.label), const SizedBox(height: 12),
          ...((_stats?['by_category'] as Map<String, dynamic>?) ?? {}).entries.map((e) =>
            _catBar(e.key, e.value as int, _stats?['total'] ?? 1)),
          const SizedBox(height: AppSpacing.xl),
          // Top worn
          Text('MOST WORN', style: AppTheme.label), const SizedBox(height: 12),
          ...((_stats?['top_worn'] as List?) ?? []).map((i) => _rankItem(i['name'], '${i['wear_count']} wears')),
          const SizedBox(height: AppSpacing.xl),
          // Top preference
          Text('HIGHEST PREFERENCE', style: AppTheme.label), const SizedBox(height: 12),
          ...((_stats?['top_preference'] as List?) ?? []).map((i) =>
            _rankItem(i['name'], '${(i['preference'] as num).toStringAsFixed(0)}%')),
        ]))));
  }

  Widget _metric(String label, String value) => Expanded(child: Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(
      color: AppColors.bgSurface2, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTheme.micro),
      const SizedBox(height: 4), Text(value, style: AppTheme.metricValue)])));

  Widget _catBar(String cat, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(cat[0].toUpperCase() + cat.substring(1), style: AppTheme.body.copyWith(fontSize: 13)),
          Text('$count', style: AppTheme.caption)]),
        const SizedBox(height: 4),
        Container(height: 4, decoration: BoxDecoration(color: AppColors.bgSurface2, borderRadius: BorderRadius.circular(2)),
          child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: pct,
            child: Container(decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)))))]));
  }

  Widget _rankItem(String? name, String value) => Container(
    margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(child: Text(name ?? '', style: AppTheme.body.copyWith(fontSize: 14))),
      Text(value, style: AppTheme.caption.copyWith(color: AppColors.gold))]));
}
