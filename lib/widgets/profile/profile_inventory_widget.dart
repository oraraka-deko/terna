library;

import 'package:flutter/material.dart';
import '../../models/inventory/inventory_models.dart';
import '../../services/inventory/inventory_repository.dart';
import '../../screens/inventory/inventory_screen.dart';

class ProfileInventoryWidget extends StatelessWidget {
  final VoidCallback? onOpenShop;

  const ProfileInventoryWidget({super.key, this.onOpenShop});

  @override
  Widget build(BuildContext context) {
    final invRepo = InventoryRepository();

    return ValueListenableBuilder<List<InventoryItem>>(
      valueListenable: invRepo.userItems,
      builder: (ctx, items, _) {
        final totalTon = invRepo.totalTonValue.toStringAsFixed(2);
        final totalStars = invRepo.totalStarsValue;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1035), Color(0xFF0F0B1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22A855F7),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFC084FC), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SHOWCASE & VAULT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$totalTon TON • $totalStars Stars Value',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InventoryScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View All', style: TextStyle(color: Color(0xFFC084FC), fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFC084FC), size: 10),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('No assets in vault yet.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                )
              else
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];
                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF090D15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            item.webpPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, color: Colors.purpleAccent),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

