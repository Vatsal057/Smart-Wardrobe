import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key});
  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final _destController = TextEditingController();
  int _days = 3;
  Map<String, dynamic>? _result;
  bool _isLoading = false;

  Future<void> _generate() async {
    if (_destController.text.trim().isEmpty) return;
    setState(() { _isLoading = true; _result = null; });
    try {
      _result = await ApiService.generatePackingList(
        destination: _destController.text.trim(), days: _days);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.bgBase,
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
        Text('Packing', style: AppTheme.title),
        const SizedBox(height: AppSpacing.lg),
        Text('DESTINATION', style: AppTheme.label), const SizedBox(height: 8),
        TextField(controller: _destController, style: AppTheme.body,
          decoration: const InputDecoration(hintText: 'e.g. Goa, a business trip')),
        const SizedBox(height: AppSpacing.lg),
        Text('DAYS', style: AppTheme.label), const SizedBox(height: 8),
        Row(children: [3, 5, 7, 10].map((d) {
          final sel = d == _days;
          return Padding(padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(onTap: () => setState(() => _days = d),
              child: Container(width: 48, height: 48,
                decoration: BoxDecoration(color: sel ? AppColors.goldFaint : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? AppColors.gold.withValues(alpha: 0.3) : AppColors.borderDefault)),
                child: Center(child: Text('$d', style: AppTheme.body.copyWith(
                  color: sel ? AppColors.gold : AppColors.textSecondary))))));
        }).toList()),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(width: double.infinity, height: 52, child: InkWell(onTap: _isLoading ? null : _generate,
          borderRadius: BorderRadius.circular(8),
          child: Container(decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldHi]),
            borderRadius: BorderRadius.circular(8)),
            child: Center(child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1208)))
              : Text('Generate Packing List', style: AppTheme.button))))),
        if (_result != null) ...[
          const SizedBox(height: AppSpacing.xl),
          if (_result!['tip'] != null)
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.goldFaint, borderRadius: BorderRadius.circular(12)),
              child: Text(_result!['tip'], style: AppTheme.body.copyWith(fontSize: 13, color: AppColors.gold))),
          const SizedBox(height: AppSpacing.md),
          ...((_result!['packing_list'] as List?) ?? []).map((cat) => _catSection(cat)),
        ],
      ])));
  }

  Widget _catSection(Map<String, dynamic> cat) {
    final items = (cat['items'] as List?) ?? [];
    return Padding(padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${(cat['category'] as String).toUpperCase()} (${cat['count']})', style: AppTheme.label),
        const SizedBox(height: 8),
        ...items.map((i) => Container(margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
          child: Text(i['name'] ?? '', style: AppTheme.body.copyWith(fontSize: 14)))),
      ]));
  }
}
