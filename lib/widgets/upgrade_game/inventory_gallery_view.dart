import 'package:flutter/material.dart';
import '../../models/upgrade_game/telegram_gift_model.dart';
import 'gift_visual_widget.dart';

/// Interactive gallery view displaying user inventory gifts for bet selection.
class InventoryGalleryView extends StatelessWidget {
  final List<TelegramGift> inventoryGifts;
  final List<TelegramGift> selectedGifts;
  final ValueChanged<TelegramGift> onToggleGift;
  final double maxHeight;

  const InventoryGalleryView({
    super.key,
    required this.inventoryGifts,
    required this.selectedGifts,
    required this.onToggleGift,
    this.maxHeight = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (inventoryGifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            'No gifts in your inventory yet. You can wager TON or Stars directly!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
      );
    }

    final selectedKeys = selectedGifts.map((g) => g.instanceId).toSet();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: inventoryGifts.length,
        itemBuilder: (context, index) {
          final gift = inventoryGifts[index];
          final isSelected = selectedKeys.contains(gift.instanceId);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onToggleGift(gift),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.22)
                      : const Color(0xFF141728),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFA855F7)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gift Animated / WebP render
                    GiftVisualWidget(
                      gift: gift,
                      size: 44,
                      animate: isSelected,
                    ),
                    const SizedBox(height: 4),

                    // Gift Name
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

                    // Value
                    Text(
                      '${gift.priceStars} ⭐',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
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
        },
      ),
    );
  }
}

