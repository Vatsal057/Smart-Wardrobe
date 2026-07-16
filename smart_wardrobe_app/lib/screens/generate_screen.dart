import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../components/outfit_card.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  String _occasion = 'casual';
  List<dynamic> _outfits = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  final _occasions = ['casual','smart_casual','semi_formal','formal','date','outdoor','party'];

  Future<void> _generate() async {
    setState(() { _isLoading = true; _outfits = []; });
    try {
      final data = await ApiService.getRecommendations(occasion: _occasion);
      setState(() { _outfits = data['outfits'] ?? []; _currentIndex = 0; });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.bgBase,
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
        Text('Generate', style: AppTheme.title),
        const SizedBox(height: AppSpacing.md),
        Text('OCCASION', style: AppTheme.label),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _occasions.map((o) {
          final sel = o == _occasion;
          return GestureDetector(onTap: () => setState(() => _occasion = o),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.goldFaint : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? AppColors.gold.withValues(alpha: 0.3) : AppColors.borderDefault)),
              child: Text(o.replaceAll('_', ' '), style: AppTheme.body.copyWith(
                fontSize: 13, color: sel ? AppColors.gold : AppColors.textSecondary))));
        }).toList()),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(width: double.infinity, height: 52, child: InkWell(onTap: _isLoading ? null : _generate,
          borderRadius: BorderRadius.circular(8),
          child: Container(decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldHi]),
            borderRadius: BorderRadius.circular(8)),
            child: Center(child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1208)))
              : Text('Generate Outfits', style: AppTheme.button))))),
        const SizedBox(height: AppSpacing.xl),
        if (_outfits.isNotEmpty && _currentIndex < _outfits.length)
          OutfitCard(outfit: _outfits[_currentIndex],
            onWear: () async {
              final ids = (_outfits[_currentIndex]['item_ids'] as List).map((e) => e as int).toList();
              await ApiService.wearItems(ids, occasion: _occasion);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Wearing this ✦', style: AppTheme.body), backgroundColor: AppColors.bgSurface2));
              }
            },
            onNext: () { if (_currentIndex < _outfits.length - 1) setState(() => _currentIndex++); }),
        if (_outfits.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 12),
            child: Center(child: Text('${_currentIndex + 1} / ${_outfits.length}', style: AppTheme.caption))),
      ])));
  }
}
