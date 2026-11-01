import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';
import '../../services/haptic.dart';
import 'target_gift_grid_item.dart';

/// Modal dialog allowing the user to search and pick a target gift from the catalog.
class TargetGiftPickerModal extends StatefulWidget {
  final UpgradeGameViewModel viewModel;

  const TargetGiftPickerModal({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, UpgradeGameViewModel viewModel) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => TargetGiftPickerModal(viewModel: viewModel),
    );
  }

  @override
  State<TargetGiftPickerModal> createState() => _TargetGiftPickerModalState();
}

class _TargetGiftPickerModalState extends State<TargetGiftPickerModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final filteredGifts = vm.catalogGifts.where((g) {
      if (_searchQuery.isEmpty) return true;
      return g.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 440,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF111422),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 28,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SELECT TARGET GIFT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                hintText: 'Search gifts...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFA3E635)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Catalog Gifts Grid
            Expanded(
              child: filteredGifts.isEmpty
                  ? const Center(
                      child: Text(
                        'No gifts found',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.84,
                      ),
                      itemCount: filteredGifts.length,
                      itemBuilder: (context, index) {
                        final gift = filteredGifts[index];
                        final isCurrentlyTarget =
                            vm.selectedTargetGift?.giftId == gift.giftId;
                        final priceText = vm.currency == UpgradeCurrency.ton
                            ? '${vm.starsToTon(gift.priceStars)} TON'
                            : '${gift.priceStars} ⭐';

                        return TargetGiftGridItem(
                          gift: gift,
                          isCurrentlyTarget: isCurrentlyTarget,
                          priceText: priceText,
                          onTap: () {
                            HapticFeedbackService.tap();
                            vm.setSelectedTargetGift(gift);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
