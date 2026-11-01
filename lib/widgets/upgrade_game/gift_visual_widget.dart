import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:terna/models/upgrade_game/telegram_gift_model.dart';

/// Reusable widget for rendering Telegram Gifts.
/// Uses the Lottie package with GZip decoding for animated .tgs assets,
/// with graceful fallback to high-res WebP/PNG images and icons.
class GiftVisualWidget extends StatelessWidget {
  final TelegramGift? gift;
  final String? giftId;
  final String? name;
  final double size;
  final bool animate;
  final BoxFit fit;

  const GiftVisualWidget({
    super.key,
    this.gift,
    this.giftId,
    this.name,
    this.size = 56.0,
    this.animate = true,
    this.fit = BoxFit.contain,
  });

  String get _effectiveGiftId => gift?.giftId ?? giftId ?? '';

  @override
  Widget build(BuildContext context) {
    final id = _effectiveGiftId;
    if (id.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.card_giftcard_rounded,
          size: size * 0.65,
          color: Colors.white38,
        ),
      );
    }

    final tgsPath = 'assets/telegram/gifts/tgs/gift_$id.tgs';
    final webpPath = 'assets/telegram/gifts/webp/gift_$id.webp';
    final pngPath = 'assets/telegram/gifts/png/gift_$id.png';

    return SizedBox(
      width: size,
      height: size,
      child: animate
          ? Lottie.asset(
              tgsPath,
              decoder: LottieComposition.decodeGZip,
              width: size,
              height: size,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackImage(webpPath, pngPath);
              },
            )
          : _buildFallbackImage(webpPath, pngPath),
    );
  }

  Widget _buildFallbackImage(String webpPath, String pngPath) {
    return Image.asset(
      webpPath,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          pngPath,
          width: size,
          height: size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                size: size * 0.65,
                color: Colors.white54,
              ),
            );
          },
        );
      },
    );
  }
}
