import 'package:flutter/material.dart';
import '../../models/upgrade_game/telegram_gift_model.dart';
import 'gift_visual_widget.dart';

/// Performance-optimized item in the Target Gift Picker grid:
/// - By default renders fast static image.
/// - Automatically plays animated .tgs Lottie when hovered with mouse, touched,
///   or if this gift is the active target.
class TargetGiftGridItem extends StatefulWidget {
  final TelegramGift gift;
  final bool isCurrentlyTarget;
  final String priceText;
  final VoidCallback onTap;

  const TargetGiftGridItem({
    super.key,
    required this.gift,
    required this.isCurrentlyTarget,
    required this.priceText,
    required this.onTap,
  });

  @override
  State<TargetGiftGridItem> createState() => _TargetGiftGridItemState();
}

class _TargetGiftGridItemState extends State<TargetGiftGridItem> {
  bool _isHoveredOrTouched = false;

  @override
  Widget build(BuildContext context) {
    final gift = widget.gift;
    final isTarget = widget.isCurrentlyTarget;
    final shouldAnimate = isTarget || _isHoveredOrTouched;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveredOrTouched = true),
      onExit: (_) => setState(() => _isHoveredOrTouched = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHoveredOrTouched = true),
        onTapUp: (_) => setState(() => _isHoveredOrTouched = false),
        onTapCancel: () => setState(() => _isHoveredOrTouched = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isTarget
                ? const Color(0xFFA3E635).withValues(alpha: 0.15)
                : _isHoveredOrTouched
                    ? const Color(0xFF1E2336)
                    : const Color(0xFF161928),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTarget
                  ? const Color(0xFFA3E635)
                  : _isHoveredOrTouched
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
              width: isTarget || _isHoveredOrTouched ? 1.5 : 1.0,
            ),
            boxShadow: _isHoveredOrTouched
                ? [
                    BoxShadow(
                      color: const Color(0xFFA3E635).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rounded gift icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1735),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: shouldAnimate
                        ? const Color(0xFFA3E635).withValues(alpha: 0.4)
                        : Colors.white10,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: GiftVisualWidget(
                  gift: gift,
                  size: 40,
                  animate: shouldAnimate,
                ),
              ),
              const SizedBox(height: 4),

              // Name
              Text(
                gift.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Price
              Text(
                widget.priceText,
                style: const TextStyle(
                  color: Color(0xFFA3E635),
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

