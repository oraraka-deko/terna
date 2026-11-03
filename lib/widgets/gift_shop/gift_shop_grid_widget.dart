import 'package:flutter/material.dart';

import '../../models/gift_shop/gift_shop_models.dart';
import 'gift_shop_card_widget.dart';
import 'gift_shop_promo_card_widget.dart';

/// Responsive Grid / List displaying Gift items and promotional cards.
class GiftShopGridWidget extends StatelessWidget {
  final List<GiftShopItem> items;
  final GiftShopCurrency currentCurrency;
  final GiftShopViewMode viewMode;
  final ValueChanged<GiftShopItem> onBuy;
  final ValueChanged<GiftShopItem> onDetails;
  final VoidCallback onResetFilters;

  const GiftShopGridWidget({
    super.key,
    required this.items,
    required this.currentCurrency,
    required this.viewMode,
    required this.onBuy,
    required this.onDetails,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Colors.white24,
              ),
              const SizedBox(height: 12),
              const Text(
                'No gifts found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching for another keyword or clear current filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (viewMode == GiftShopViewMode.list) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                height: 110,
                child: GiftShopCardWidget(
                  item: item,
                  currentCurrency: currentCurrency,
                  onBuy: () => onBuy(item),
                  onDetails: () => onDetails(item),
                ),
              );
            },
          );
        }

        // Responsive grid column count
        int crossAxisCount;
        if (viewMode == GiftShopViewMode.grid3 || screenWidth >= 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        // Child aspect ratio tuned for squircle cards (approx 0.72)
        final childAspectRatio = crossAxisCount == 3 ? 0.75 : 0.76;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length + 1, // +1 for the promo card
          itemBuilder: (context, index) {
            // Insert the "TON at Work" promo card at index 5.
            if (index == 5 || (index == items.length && items.length < 5)) {
              return GiftShopPromoCardWidget(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('TON staking is not available yet.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            }

            final itemIndex = index > 5 ? index - 1 : index;
            if (itemIndex >= items.length) {
              return const SizedBox.shrink();
            }

            final item = items[itemIndex];
            return GiftShopCardWidget(
              item: item,
              currentCurrency: currentCurrency,
              onBuy: () => onBuy(item),
              onDetails: () => onDetails(item),
            );
          },
        );
      },
    );
  }
}
