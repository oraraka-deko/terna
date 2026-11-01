import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:terna/models/upgrade_game/telegram_gift_model.dart';

/// Reusable widget for rendering Telegram Gifts.
/// Performance-optimized:
/// - By default renders fast, lightweight static image (WebP / PNG) to conserve CPU/GPU.
/// - Only instantiates and plays GZip Lottie .tgs animation when explicitly requested
///   (e.g. details view) or when hovered/touched via [animateOnHover].
class GiftVisualWidget extends StatefulWidget {
  final TelegramGift? gift;
  final String? giftId;
  final String? name;
  final double size;

  /// Explicit animation control:
  /// - `true`: force animated Lottie playback (e.g. details modal).
  /// - `false`: force static image.
  /// - `null`: relies on [animateOnHover] or active state.
  final bool? animate;

  /// When true, plays Lottie animation on mouse hover or touch down,
  /// otherwise displays static WebP/PNG image to save CPU/GPU resources.
  final bool animateOnHover;

  final BoxFit fit;

  const GiftVisualWidget({
    super.key,
    this.gift,
    this.giftId,
    this.name,
    this.size = 56.0,
    this.animate,
    this.animateOnHover = false,
    this.fit = BoxFit.contain,
  });

  @override
  State<GiftVisualWidget> createState() => _GiftVisualWidgetState();
}

class _GiftVisualWidgetState extends State<GiftVisualWidget> {
  bool _isHoveredOrTouched = false;

  String get _effectiveGiftId => widget.gift?.giftId ?? widget.giftId ?? '';

  bool get _shouldAnimate {
    if (widget.animate != null) {
      return widget.animate!;
    }
    if (widget.animateOnHover) {
      return _isHoveredOrTouched;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final id = _effectiveGiftId;
    if (id.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Icon(
          Icons.card_giftcard_rounded,
          size: widget.size * 0.65,
          color: Colors.white38,
        ),
      );
    }

    final tgsPath = 'assets/telegram/gifts/tgs/gift_$id.tgs';
    final webpPath = 'assets/telegram/gifts/webp/gift_$id.webp';
    final pngPath = 'assets/telegram/gifts/png/gift_$id.png';

    final content = SizedBox(
      width: widget.size,
      height: widget.size,
      child: _shouldAnimate
          ? Lottie.asset(
              tgsPath,
              decoder: LottieComposition.decodeGZip,
              width: widget.size,
              height: widget.size,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackImage(webpPath, pngPath);
              },
            )
          : _buildFallbackImage(webpPath, pngPath),
    );

    if (widget.animateOnHover && widget.animate == null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHoveredOrTouched = true),
        onExit: (_) => setState(() => _isHoveredOrTouched = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isHoveredOrTouched = true),
          onTapUp: (_) => setState(() => _isHoveredOrTouched = false),
          onTapCancel: () => setState(() => _isHoveredOrTouched = false),
          behavior: HitTestBehavior.translucent,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildFallbackImage(String webpPath, String pngPath) {
    return Image.asset(
      webpPath,
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          pngPath,
          width: widget.size,
          height: widget.size,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                size: widget.size * 0.65,
                color: Colors.white54,
              ),
            );
          },
        );
      },
    );
  }
}
