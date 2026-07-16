import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../components/clothing_photo.dart';
import '../components/wash_badge.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _filter = 'all';

  final _categories = ['all', 'top', 'bottom', 'shoes', 'accessory'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try { _items = await ApiService.getWardrobe(); } catch (_) {}
    setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered =>
    _filter == 'all' ? _items : _items.where((i) => i['category'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.bgBase,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Closet', style: AppTheme.title),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.gold),
              onPressed: () async {
                final added = await Navigator.pushNamed(context, '/add-item');
                if (added == true) _load();
              }),
          ])),
        const SizedBox(height: AppSpacing.sm),
        // Category filter
        SizedBox(height: 38, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final active = cat == _filter;
            return GestureDetector(onTap: () => setState(() => _filter = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.goldFaint : AppColors.bgSurface1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? AppColors.gold.withValues(alpha: 0.4) : AppColors.borderSubtle, width: 0.5)),
                child: Text(cat[0].toUpperCase() + cat.substring(1),
                  style: AppTheme.body.copyWith(fontSize: 13, color: active ? AppColors.gold : AppColors.textSecondary))));
          })),
        const SizedBox(height: AppSpacing.md),
        // Grid
        Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.checkroom_outlined, color: AppColors.textTertiary, size: 48),
                const SizedBox(height: 12),
                Text('No items yet', style: AppTheme.body.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 8),
                TextButton(onPressed: () async {
                  final added = await Navigator.pushNamed(context, '/add-item');
                  if (added == true) _load();
                }, child: Text('Add your first item', style: AppTheme.body.copyWith(color: AppColors.gold)))]))
            : RefreshIndicator(onRefresh: _load, color: AppColors.gold,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _itemCard(_filtered[i])))),
      ])));
  }

  Widget _itemCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Photo
        Expanded(child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
          child: Stack(fit: StackFit.expand, children: [
            ClothingPhoto(photoUrl: item['photo_template_url'] ?? item['photo_url'],
              status: item['photo_status'] ?? 'none'),
            // Polish action — top-right
            if (item['photo_url'] != null)
              Positioned(top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => _promptPolish(item),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: AppColors.bgSurface2.withValues(alpha: 0.85), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold)))),
          ]))),
        // Info
        Padding(padding: const EdgeInsets.all(10), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'] ?? '', style: AppTheme.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              WashBadge(
                washCount: item['wash_count'] as int? ?? 0,
                washThreshold: item['wash_threshold'] as int? ?? 3,
                compact: true,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _confirmDelete(item),
                child: const Icon(Icons.delete_outline, size: 16, color: AppColors.textTertiary)),
            ]),
            // Gemini description if available
            if (item['gemini_description'] != null)
              Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(item['gemini_description'],
                  style: AppTheme.micro.copyWith(color: AppColors.textTertiary, fontSize: 10),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
          ])),
      ]));
  }

  Future<void> _promptPolish(Map<String, dynamic> item) async {

    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface1,
        title: Text('Polish Photo', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: Text('Use Gemini AI to enhance "${item['name']}" into a showroom-quality product photo?\n\nThis requires your Gemini API key to be set in Settings.',
          style: AppTheme.body.copyWith(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.body.copyWith(color: AppColors.textSecondary))),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            await _polish(item);
          }, child: Text('Polish ✦', style: AppTheme.body.copyWith(color: AppColors.gold))),
        ]));
  }

  Future<void> _polish(Map<String, dynamic> item) async {
    // Show progress indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Polishing photo with Gemini AI…', style: AppTheme.body), duration: const Duration(seconds: 10),
        backgroundColor: AppColors.bgSurface2));

    try {
      final result = await ApiService.polishPhoto(item['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final ok = result['status'] == 'done';
        final msg = ok ? 'Photo polished ✦' : (result['description'] ?? 'Polish failed.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg, style: AppTheme.body), backgroundColor: AppColors.bgSurface2));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Polish failed: $e', style: AppTheme.body), backgroundColor: AppColors.bgSurface2));
      }
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface1,
        title: Text('Delete', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        content: Text('Remove "${item['name']}" from your wardrobe?', style: AppTheme.body.copyWith(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.body.copyWith(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: AppTheme.body.copyWith(color: AppColors.red))),
        ]));
    if (ok == true) {
      await ApiService.deleteWardrobeItem(item['id'] as int);
      _load();
    }
  }
}
