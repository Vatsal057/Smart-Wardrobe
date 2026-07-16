import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Displays a clothing item photo with status overlay.
/// Supports both local file paths and network URLs.
class ClothingPhoto extends StatelessWidget {
  final String? photoUrl;
  final String? status;
  final double width;
  final double height;
  final double borderRadius;

  const ClothingPhoto({
    super.key,
    this.photoUrl,
    this.status,
    this.width = 80,
    this.height = 100,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSurface2,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoUrl != null && photoUrl!.isNotEmpty)
            _buildImage()
          else
            _placeholder(),
          if (status == 'processing')
            Container(
              color: Colors.black54,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final url = photoUrl!;
    // Check if it's a local file path
    if (url.startsWith('/') || url.startsWith('C:') || url.startsWith('D:') || url.contains('\\')) {
      final file = File(url);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // Network URL
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.bgSurface2,
      child: Icon(
        Icons.checkroom_outlined,
        color: AppColors.textTertiary,
        size: width * 0.4,
      ),
    );
  }
}
