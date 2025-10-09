import 'package:flutter/material.dart';

/// Displays a product image that can come from either a Supabase public URL or
/// a bundled asset. Falls back to [placeholderAsset] when no image is provided
/// or when loading fails.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderAsset = 'assets/icons/logo.png',
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String placeholderAsset;

  bool get _isNetwork {
    if (imageUrl == null) {
      return false;
    }
    final String value = imageUrl!.toLowerCase();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (_isNetwork) {
      image = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 1.6),
            ),
          );
        },
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
      );
    } else {
      image = _fallbackImage();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _fallbackImage() {
    return Image.asset(
      placeholderAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
