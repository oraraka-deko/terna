import 'package:flutter/material.dart';
import '../../models/gift_shop/gift_shop_models.dart';

/// Category sub-navigation tabs matching Image 1 (All, Collections, Stars, Craft).
class GiftShopCategoryTabsWidget extends StatelessWidget {
  final GiftShopCategory activeCategory;
  final ValueChanged<GiftShopCategory> onCategorySelected;
  final VoidCallback? onOpenCollectionsModal;

  const GiftShopCategoryTabsWidget({
    super.key,
    required this.activeCategory,
    required this.onCategorySelected,
    this.onOpenCollectionsModal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabItem(
            category: GiftShopCategory.all,
            title: 'All',
            icon: Icons.card_giftcard_rounded,
          ),
          const SizedBox(width: 10),
          _buildTabItem(
            category: GiftShopCategory.collections,
            title: 'Collections',
            icon: Icons.apps_rounded,
            onTapOverride: onOpenCollectionsModal,
          ),
          const SizedBox(width: 10),
          _buildTabItem(
            category: GiftShopCategory.stars,
            title: 'Stars',
            icon: Icons.star_rounded,
          ),
          const SizedBox(width: 10),
          _buildTabItem(
            category: GiftShopCategory.craft,
            title: 'Craft',
            icon: Icons.hardware_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required GiftShopCategory category,
    required String title,
    required IconData icon,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = activeCategory == category;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onTapOverride != null) {
            onTapOverride();
          } else {
            onCategorySelected(category);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF262A36) : const Color(0xFF16181F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.white38,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

