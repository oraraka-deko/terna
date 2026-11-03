import 'package:flutter/material.dart';

import '../../models/gift_shop/gift_shop_models.dart';
import '../upgrade_game/gift_visual_widget.dart';

/// Single Gift Card widget:
/// - Squircle container with custom gradient backdrop
/// - Clover & pickaxe badges in top-left
/// - Interactive optimization: uses static image by default, and plays Lottie .tgs
///   animation automatically when mouse hovers or user touches the card.
/// - Opens full animated details view on tap.
/// - Blue price pill and padlock action button.
class GiftShopCardWidget extends StatefulWidget {
  final GiftShopItem item;
  final GiftShopCurrency currentCurrency;
  final VoidCallback onBuy;
  final VoidCallback onDetails;

  const GiftShopCardWidget({
    super.key,
    required this.item,
    required this.currentCurrency,
    required this.onBuy,
    required this.onDetails,
  });

  @override
  State<GiftShopCardWidget> createState() => _GiftShopCardWidgetState();
}

class _GiftShopCardWidgetState extends State<GiftShopCardWidget> {
  bool _isHoveredOrTouched = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveredOrTouched = true),
      onExit: (_) => setState(() => _isHoveredOrTouched = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHoveredOrTouched = true),
        onTapUp: (_) => setState(() => _isHoveredOrTouched = false),
        onTapCancel: () => setState(() => _isHoveredOrTouched = false),
        onTap: widget.onDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: item.backgroundGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: item.backgroundGradient.first.withValues(
                  alpha: _isHoveredOrTouched ? 0.45 : 0.25,
                ),
                blurRadius: _isHoveredOrTouched ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isHoveredOrTouched
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              width: _isHoveredOrTouched ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle background radial highlight
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Card content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badges row (Clover & Pickaxe)
                    Row(
                      children: [
                        if (item.hasCloverBadge)
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.eco_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (item.hasPickaxeBadge)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.hardware_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (item.releaseTag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.releaseTag!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Gift visual: Plays animation ONLY when hovered/touched, else uses static image
                    Expanded(
                      child: Center(
                        child: GiftVisualWidget(
                          giftId: item.giftId,
                          name: item.name,
                          size: 96,
                          animate: _isHoveredOrTouched,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Gift Title
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Serial / Edition Number (e.g. #135966)
                    Text(
                      item.editionNumber,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bottom action row: Blue price pill + Lock button
                    Row(
                      children: [
                        // Blue price button
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onBuy,
                            child: Container(
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                borderRadius: BorderRadius.circular(17),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E88E5)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.currentCurrency ==
                                            GiftShopCurrency.stars
                                        ? '${item.priceStars}'
                                        : item.priceTon.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    widget.currentCurrency ==
                                            GiftShopCurrency.stars
                                        ? Icons.star_rounded
                                        : Icons.diamond_rounded,
                                    color:
                                        widget.currentCurrency ==
                                            GiftShopCurrency.stars
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Lock / Padlock action button
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
