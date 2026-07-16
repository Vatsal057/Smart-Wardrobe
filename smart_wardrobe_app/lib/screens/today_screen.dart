import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../components/outfit_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Map<String, dynamic>? _recommendation;
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getRecommendations();
      setState(() { _recommendation = data; _isLoading = false; _currentIndex = 0; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _wearOutfit() async {
    if (_recommendation == null) return;
    final outfits = _recommendation!['outfits'] as List<dynamic>? ?? [];
    if (_currentIndex >= outfits.length) return;

    final outfit = outfits[_currentIndex];
    final itemIds = (outfit['item_ids'] as List<dynamic>).map((e) => e as int).toList();

    try {
      await ApiService.wearItems(itemIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wearing this look ✦', style: AppTheme.body.copyWith(color: AppColors.textPrimary)),
            backgroundColor: AppColors.bgSurface2,
          ),
        );
        _loadRecommendation();
      }
    } catch (e) {
      /* ignore */
    }
  }

  void _nextOutfit() {
    final outfits = _recommendation?['outfits'] as List<dynamic>? ?? [];
    if (_currentIndex < outfits.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _loadRecommendation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Could not load recommendations', style: AppTheme.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: _loadRecommendation, child: Text('Retry', style: AppTheme.body.copyWith(color: AppColors.gold))),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final outfits = _recommendation?['outfits'] as List<dynamic>? ?? [];
    final weather = _recommendation?['weather'];
    final washWarning = _recommendation?['wash_warning'];

    return RefreshIndicator(
      onRefresh: _loadRecommendation,
      color: AppColors.gold,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // Header
          Text('Today', style: AppTheme.title),
          const SizedBox(height: AppSpacing.sm),

          // Weather
          if (weather != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.thermostat_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${weather['temp_c'] ?? 25}°C',
                    style: AppTheme.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.water_drop_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${weather['rain_pct'] ?? 0}%',
                    style: AppTheme.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // Wash warning
          if (washWarning != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.amberFaint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.amber, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(washWarning, style: AppTheme.caption.copyWith(color: AppColors.amber)),
                  ),
                ],
              ),
            ),

          // Outfit card
          if (outfits.isNotEmpty && _currentIndex < outfits.length)
            OutfitCard(
              outfit: outfits[_currentIndex],
              onWear: _wearOutfit,
              onNext: _nextOutfit,
            )
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.bgSurface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.checkroom, color: AppColors.textTertiary, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text('Add items to your wardrobe', style: AppTheme.subtitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add at least one top and one bottom to get outfit recommendations.',
            style: AppTheme.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
