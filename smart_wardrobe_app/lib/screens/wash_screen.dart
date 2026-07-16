import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../components/wash_badge.dart';

class WashScreen extends StatefulWidget {
  const WashScreen({super.key});
  @override
  State<WashScreen> createState() => _WashScreenState();
}

class _WashScreenState extends State<WashScreen> {
  Map<String, dynamic>? _status;
  bool _isLoading = true;
  final Set<int> _selected = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _status = await ApiService.getWashStatus();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _washSelected() async {
    if (_selected.isEmpty) return;
    await ApiService.washItems(_selected.toList());
    _selected.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.bgBase,
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    final urgency = _status?['urgency'] ?? 'low';
    final message = _status?['message'] ?? '';
    final needsWash = (_status?['items_needing_wash'] as List?) ?? [];
    final washSoon = (_status?['wash_soon_items'] as List?) ?? [];
    final urgCol = urgency == 'critical' ? AppColors.red : urgency == 'low' ? AppColors.green : AppColors.amber;
    final urgBg = urgency == 'critical' ? AppColors.redFaint : urgency == 'low' ? AppColors.greenFaint : AppColors.amberFaint;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      bottomNavigationBar: _selected.isEmpty ? null : _washBar(),
      body: SafeArea(child: RefreshIndicator(onRefresh: _load, color: AppColors.gold,
        child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
          Text('Wash', style: AppTheme.title),
          const SizedBox(height: AppSpacing.md),
          _banner(message, urgCol, urgBg),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            _stat('Clean tops', '${_status?['clean_tops'] ?? 0}'),
            const SizedBox(width: 12), _stat('Clean bottoms', '${_status?['clean_bottoms'] ?? 0}'),
            const SizedBox(width: 12), _stat('Needs wash', '${_status?['needs_wash_count'] ?? 0}'),
          ]),
          const SizedBox(height: AppSpacing.lg),
          if (needsWash.isNotEmpty) ...[Text('NEEDS WASH', style: AppTheme.label), const SizedBox(height: 8),
            ...needsWash.map((i) => _item(i))],
          if (washSoon.isNotEmpty) ...[const SizedBox(height: 16), Text('WASH SOON', style: AppTheme.label),
            const SizedBox(height: 8), ...washSoon.map((i) => _item(i))],
          if (needsWash.isEmpty && washSoon.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.only(top: 40),
              child: Column(children: [
                Icon(Icons.check_circle_outline, color: AppColors.green, size: 48),
                const SizedBox(height: 12), Text('All clean!', style: AppTheme.subtitle.copyWith(color: AppColors.green)),
              ]))),
        ]))),
    );
  }

  Widget _banner(String msg, Color col, Color bg) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: col.withValues(alpha: 0.3))),
    child: Row(children: [Icon(Icons.info_outline, color: col, size: 18),
      const SizedBox(width: 8), Expanded(child: Text(msg, style: AppTheme.body.copyWith(fontSize: 13, color: col)))]));

  Widget _stat(String label, String val) => Expanded(child: Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.bgSurface2,
      borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Text(val, style: AppTheme.metricValue.copyWith(fontSize: 22)),
      const SizedBox(height: 2), Text(label.toUpperCase(), style: AppTheme.micro.copyWith(fontSize: 9))])));

  Widget _item(Map<String, dynamic> item) {
    final id = item['id'] as int;
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
      child: Row(children: [
        Checkbox(value: _selected.contains(id), activeColor: AppColors.gold,
          side: const BorderSide(color: AppColors.borderDefault),
          onChanged: (v) => setState(() { v == true ? _selected.add(id) : _selected.remove(id); })),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] ?? '', style: AppTheme.body.copyWith(fontSize: 14)),
          Text(item['category'] ?? '', style: AppTheme.caption)])),
        WashBadge(washCount: item['wash_count'] ?? 0, washThreshold: item['wash_threshold'] ?? 3),
      ]));
  }

  Widget _washBar() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(color: AppColors.bgSurface1,
      border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 0.5))),
    child: SafeArea(child: SizedBox(height: 52, child: InkWell(onTap: _washSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldHi]),
        borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('Mark ${_selected.length} as washed', style: AppTheme.button)))))));
}
