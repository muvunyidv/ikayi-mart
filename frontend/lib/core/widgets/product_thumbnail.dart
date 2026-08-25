import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/cloudinary_image.dart';

/// Rounded product photo used by storefront tiles and order line items.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final size = (width ?? height ?? 200).round().clamp(48, 800);
    final src = CloudinaryImage.thumbnail(imageUrl, size: size);

    Widget image;
    if (src.isEmpty) {
      image = const _ThumbnailFallback();
    } else {
      image = Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _ThumbnailFallback(busy: true);
        },
        errorBuilder: (_, _, _) => const _ThumbnailFallback(),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: AppColors.surfaceHigh,
        child: width == null && height == null
            ? SizedBox.expand(child: image)
            : SizedBox(width: width, height: height, child: image),
      ),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({this.busy = false});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceHigh,
      child: Center(
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_outlined, color: AppColors.secondary),
      ),
    );
  }
}
