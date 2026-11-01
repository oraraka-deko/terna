import 'package:flutter/material.dart';
import '../../models/gift_shop/gift_shop_models.dart';
import '../upgrade_game/gift_visual_widget.dart';

/// Single Gift Card widget matching Image 1:
/// - Squircle container with custom gradient backdrop
/// - Clover & pickaxe badges in top-left
/// - Lottie .tgs / WebP visual in center
/// - Title & edition number
/// - Blue price pill and padlock action button
class GiftShopCardWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetails,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: item.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: item.backgroundGradient.first.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
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
                            color: const Color(0xFF22C55E).withValues(alpha: 0.85),
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
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.85),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.85),
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

                  // Gift visual preview with Lottie / WebP
                  Expanded(
                    child: Center(
                      child: GiftVisualWidget(
                        giftId: item.giftId,
                        name: item.name,
                        size: 96,
                        animate: true,
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
                          onTap: onBuy,
                          child: Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentCurrency == GiftShopCurrency.stars
                                      ? '${item.priceStars}'
                                      : item.priceGram.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  currentCurrency == GiftShopCurrency.stars
                                      ? Icons.star_rounded
                                      : Icons.diamond_rounded,
                                  color: currentCurrency == GiftShopCurrency.stars
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

                      // Lock / Padlock action button (matching screenshot)
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
    );
  }
}

