library;

import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

/// Helper to get appropriate ImageProvider for either network URL or local asset.
ImageProvider? safeImageProvider(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final clean = path.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }
  return AssetImage(clean);
}

/// Resilient Avatar & Image loader that seamlessly handles:
/// - Remote HTTP / HTTPS URLs (e.g. Unsplash avatars, Telegram user photos)
/// - Local Asset paths (e.g. assets/npc/avatars/..., assets/telegram/avatars/...)
/// - Fallback placeholders on offline network failure or missing asset
/// - Never crashes or throws unhandled Flutter image exceptions.
class SafeAvatarImage extends StatelessWidget {
  final String? imageSource;
  final double? width;
  final double? height;
  final double size;
  final BoxFit fit;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final Color? backgroundColor;

  const SafeAvatarImage({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.size = 44,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.fallback,
    this.backgroundColor,
  });

  bool get _isNetwork =>
      imageSource != null &&
      (imageSource!.startsWith('http://') || imageSource!.startsWith('https://'));

  bool get _isValid => imageSource != null && imageSource!.trim().isNotEmpty;

  Widget _buildFallback(BuildContext context, double w, double h) {
    if (fallback != null) return fallback!;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF2C3240),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(8)) : null,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        AppAssets.avatarDino,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          Icons.person_rounded,
          size: w * 0.55,
          color: Colors.white70,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

    if (!_isValid) {
      return _buildFallback(context, w, h);
    }

    Widget content;

    if (_isNetwork) {
      content = Image.network(
        imageSource!.trim(),
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Graceful network drop / offline fallback
          return _buildFallback(context, w, h);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: w,
            height: h,
            color: backgroundColor ?? const Color(0xFF1E2330),
            alignment: Alignment.center,
            child: SizedBox(
              width: w * 0.35,
              height: h * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white38,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      content = Image.asset(
        imageSource!.trim(),
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback(context, w, h);
        },
      );
    }

    if (shape == BoxShape.circle) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? Colors.transparent,
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: backgroundColor ?? Colors.transparent,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
