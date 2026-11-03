import 'package:flutter/material.dart';
import '../../models/gift_shop/gift_shop_models.dart';
import '../upgrade_game/gift_visual_widget.dart';

/// Modal dialog showing full 3D animated preview of a gift, its attributes, and buy options.
class GiftShopDetailsModal extends StatelessWidget {
  final GiftShopItem item;
  final GiftShopCurrency currentCurrency;
  final ValueChanged<GiftShopItem> onBuy;
  final ValueChanged<GiftShopItem>? onLuckySpin;

  const GiftShopDetailsModal({
    super.key,
    required this.item,
    required this.currentCurrency,
    required this.onBuy,
    this.onLuckySpin,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141721),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Preview Area with custom gradient
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: item.backgroundGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Close button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                  // Large animated gift preview
                  GiftVisualWidget(
                    giftId: item.giftId,
                    name: item.name,
                    size: 150,
                    animate: true,
                  ),
                ],
              ),
            ),

            // Content Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        item.editionNumber,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Attribute chips: Models, Backdrops, Symbols
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAttrChip(
                        icon: Icons.auto_awesome_rounded,
                        label: '${item.modelCount} Models',
                      ),
                      _buildAttrChip(
                        icon: Icons.palette_rounded,
                        label: '${item.backdropCount} Backdrops',
                      ),
                      _buildAttrChip(
                        icon: Icons.token_rounded,
                        label: '${item.symbolCount} Symbols',
                      ),
                      if (item.isUpgradeable)
                        _buildAttrChip(
                          icon: Icons.hardware_rounded,
                          label: 'Craftable',
                          color: const Color(0xFF8B5CF6),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Price and Buy CTA
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          Row(
                            children: [
                              Text(
                                currentCurrency == GiftShopCurrency.stars
                                    ? '${item.priceStars} Stars'
                                    : '${item.priceGram.toStringAsFixed(2)} GRAM',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
                                    : const Color(0xFF38BDF8),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Primary Buy Button
                      if (onLuckySpin != null) ...[
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onLuckySpin!(item);
                          },
                          icon: const Icon(Icons.casino_rounded, size: 16, color: Color(0xFF2DD4BF)),
                          label: const Text('Lucky Spin', style: TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2DD4BF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onBuy(item);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Buy with ${currentCurrency == GiftShopCurrency.stars ? "Stars" : "GRAM"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
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

  Widget _buildAttrChip({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF222634),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

