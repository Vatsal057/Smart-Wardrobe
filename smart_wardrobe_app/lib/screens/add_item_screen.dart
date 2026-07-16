import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  String _category = 'top';
  String _color = 'black';
  int _warmth = 5;
  int _formality = 5;
  bool _waterproof = false;
  String _season = 'all';
  File? _photo;
  bool _isLoading = false;

  final _colors = ['black', 'white', 'grey', 'navy', 'blue', 'red', 'green', 'brown', 'beige', 'cream', 'pink', 'purple', 'orange', 'yellow', 'teal', 'maroon', 'khaki', 'denim', 'olive', 'burgundy', 'coral'];

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name', style: AppTheme.body), backgroundColor: AppColors.bgSurface2),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.addWardrobeItem(
        name: _nameController.text.trim(),
        category: _category,
        color: _color,
        warmth: _warmth,
        formality: _formality,
        waterproof: _waterproof,
        season: _season,
        photo: _photo,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: AppTheme.body), backgroundColor: AppColors.bgSurface2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: Text('Add Item', style: AppTheme.title.copyWith(fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            GestureDetector(
              onTap: () => _showPhotoOptions(),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface2,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                  image: _photo != null ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover) : null,
                ),
                child: _photo == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.textTertiary, size: 36),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Add photo', style: AppTheme.body.copyWith(color: AppColors.textTertiary)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Name
            Text('NAME', style: AppTheme.label),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameController,
              style: AppTheme.body,
              decoration: const InputDecoration(hintText: 'e.g. Blue Oxford Shirt'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category
            Text('CATEGORY', style: AppTheme.label),
            const SizedBox(height: AppSpacing.sm),
            _buildSegmented(['top', 'bottom', 'shoes', 'accessory'], _category, (v) => setState(() => _category = v)),
            const SizedBox(height: AppSpacing.lg),

            // Color
            Text('COLOR', style: AppTheme.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) => _colorChip(c)).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Warmth slider
            _sliderField('WARMTH', 'Cool / breathable', 'Very warm', _warmth, (v) => setState(() => _warmth = v)),
            const SizedBox(height: AppSpacing.lg),

            // Formality slider
            _sliderField('FORMALITY', 'Very casual', 'Very formal', _formality, (v) => setState(() => _formality = v)),
            const SizedBox(height: AppSpacing.lg),

            // Season
            Text('SEASON', style: AppTheme.label),
            const SizedBox(height: AppSpacing.sm),
            _buildSegmented(['all', 'summer', 'monsoon', 'winter'], _season, (v) => setState(() => _season = v)),
            const SizedBox(height: AppSpacing.lg),

            // Waterproof
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgSurface1,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.borderSubtle, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.water_drop_outlined, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Waterproof', style: AppTheme.body)),
                  Switch(
                    value: _waterproof,
                    onChanged: (v) => setState(() => _waterproof = v),
                    activeThumbColor: AppColors.gold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _save,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldHi]),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1208)))
                          : Text('Add to Wardrobe', style: AppTheme.button),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmented(List<String> options, String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final active = opt == selected;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.goldFaint : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: active ? AppColors.gold.withValues(alpha: 0.3) : AppColors.borderDefault),
            ),
            child: Text(
              opt[0].toUpperCase() + opt.substring(1),
              style: AppTheme.body.copyWith(
                fontSize: 13,
                color: active ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorChip(String colorName) {
    final active = _color == colorName;
    final colorMap = {
      'black': Colors.black, 'white': Colors.white, 'grey': Colors.grey,
      'navy': const Color(0xFF001F3F), 'blue': Colors.blue, 'red': Colors.red,
      'green': Colors.green, 'brown': Colors.brown, 'beige': const Color(0xFFF5F5DC),
      'cream': const Color(0xFFFFFDD0), 'pink': Colors.pink, 'purple': Colors.purple,
      'orange': Colors.orange, 'yellow': Colors.yellow, 'teal': Colors.teal,
      'maroon': const Color(0xFF800000), 'khaki': const Color(0xFFC3B091),
      'denim': const Color(0xFF1560BD), 'olive': const Color(0xFF808000),
      'burgundy': const Color(0xFF800020), 'coral': const Color(0xFFFF6F61),
    };

    return GestureDetector(
      onTap: () => setState(() => _color = colorName),
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: colorMap[colorName] ?? Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.gold : AppColors.borderDefault,
            width: active ? 2 : 0.5,
          ),
        ),
        child: active
            ? Icon(Icons.check, size: 16, color: colorName == 'white' || colorName == 'cream' || colorName == 'beige' ? Colors.black : Colors.white)
            : null,
      ),
    );
  }

  Widget _sliderField(String label, String minLabel, String maxLabel, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.label),
            Text('$value / 10', style: AppTheme.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.gold,
            inactiveTrackColor: AppColors.bgSurface2,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.goldFaint,
            trackHeight: 4,
          ),
          child: Slider(
            min: 1, max: 10,
            divisions: 9,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: AppTheme.caption.copyWith(fontSize: 10)),
            Text(maxLabel, style: AppTheme.caption.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderDefault, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
              title: Text('Take photo', style: AppTheme.body),
              onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.textSecondary),
              title: Text('Choose from gallery', style: AppTheme.body),
              onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }
}
