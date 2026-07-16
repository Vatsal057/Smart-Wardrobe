import 'package:flutter/material.dart';
import '../theme.dart';
import 'clothing_photo.dart';

/// Full outfit card with photo grid, score, headline, notes, and actions.
class OutfitCard extends StatelessWidget {
  final Map<String, dynamic> outfit;
  final VoidCallback? onWear;
  final VoidCallback? onNext;
  final bool showActions;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onWear,
    this.onNext,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = (outfit['items'] as List<dynamic>?) ?? [];
    final headline = outfit['headline'] as String? ?? 'Today\'s Look';
    final score = (outfit['score'] as num?)?.toDouble() ?? 0;
    final scoreLabels = (outfit['score_labels'] as List<dynamic>?) ?? [];

    final tops = items.where((i) => i['category'] == 'top').toList();
    final bottoms = items.where((i) => i['category'] == 'bottom').toList();
    final shoes = items.where((i) => i['category'] == 'shoes').toList();
    final accessories = items.where((i) => i['category'] == 'accessory').toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface1,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo grid
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _photoCell(tops.isNotEmpty ? tops.first : null),
                          ),
                          Expanded(
                            flex: 2,
                            child: _photoCell(bottoms.isNotEmpty ? bottoms.first : null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _photoCell(shoes.isNotEmpty ? shoes.first : null),
                          ),
                          Expanded(
                            flex: 2,
                            child: _photoCell(accessories.isNotEmpty ? accessories.first : null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Score badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      score.toStringAsFixed(0),
                      style: AppTheme.body.copyWith(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(headline, style: AppTheme.outfitHeadline),
                const SizedBox(height: AppSpacing.md),

                // Score labels / AI notes
                ...scoreLabels.map((label) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label.toString(),
                          style: AppTheme.body.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

                // Item thumbnail strip
                if (items.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return Column(
                          children: [
                            ClothingPhoto(
                              photoUrl: item['photo_template_url'] ?? item['photo_url'],
                              width: 44,
                              height: 56,
                              borderRadius: AppSpacing.radiusMd,
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              width: 44,
                              child: Text(
                                item['name'] ?? '',
                                style: AppTheme.caption.copyWith(fontSize: 9),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],

                // Action buttons
                if (showActions) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (onNext != null)
                        Expanded(
                          child: _ghostButton('Next look →', onNext!),
                        ),
                      if (onNext != null && onWear != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (onWear != null)
                        Expanded(
                          child: _primaryButton('✓ Wearing this', onWear!),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCell(Map<String, dynamic>? item) {
    if (item == null) {
      return Container(
        color: AppColors.bgSurface2,
        child: const Center(
          child: Icon(Icons.add, color: AppColors.textTertiary, size: 20),
        ),
      );
    }
    return item['photo_url'] != null
        ? ClothingPhoto(
            photoUrl: item['photo_template_url'] ?? item['photo_url'],
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          )
        : Container(
            color: AppColors.bgSurface2,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checkroom, color: AppColors.textTertiary, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    item['name'] ?? '',
                    style: AppTheme.caption.copyWith(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gold, AppColors.goldHi],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Center(
            child: Text(label, style: AppTheme.button),
          ),
        ),
      ),
    );
  }

  Widget _ghostButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
