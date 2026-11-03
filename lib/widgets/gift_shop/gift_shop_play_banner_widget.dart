import 'package:flutter/material.dart';

import '../../models/gift_shop/gift_shop_models.dart';

/// Hero banner matching Image 1: "Play With" currency selector (Stars vs TON)
class GiftShopPlayBannerWidget extends StatelessWidget {
  final GiftShopCurrency currentCurrency;
  final ValueChanged<GiftShopCurrency> onCurrencyChanged;

  const GiftShopPlayBannerWidget({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2E0854), Color(0xFF4A0E78), Color(0xFF6B21A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B21A8).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "Play With" bold title
          const Text(
            'Play With',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),

          // Interactive Currency Toggle Capsule (matching screenshot)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stars option
                GestureDetector(
                  onTap: () => onCurrencyChanged(GiftShopCurrency.stars),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentCurrency == GiftShopCurrency.stars
                          ? const Color(0xFFFBBF24)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: currentCurrency == GiftShopCurrency.stars
                              ? Colors.black
                              : Colors.white70,
                          size: 20,
                        ),
                        if (currentCurrency == GiftShopCurrency.stars) ...[
                          const SizedBox(width: 4),
                          const Text(
                            'Stars',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // TON diamond option
                GestureDetector(
                  onTap: () => onCurrencyChanged(GiftShopCurrency.ton),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentCurrency == GiftShopCurrency.ton
                          ? const Color(0xFF38BDF8)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond_rounded,
                          color: currentCurrency == GiftShopCurrency.ton
                              ? Colors.black
                              : Colors.white60,
                          size: 20,
                        ),
                        if (currentCurrency == GiftShopCurrency.ton) ...[
                          const SizedBox(width: 4),
                          const Text(
                            'TON',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
