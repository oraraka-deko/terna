import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';
import '../../services/haptic.dart';
import 'inventory_gallery_view.dart';

enum AssetModalTab { ton, stars, gifts }

/// Comprehensive Bet Asset Selector Modal (TON, Stars, Gifts).
class AssetSelectorModal extends StatefulWidget {
  final UpgradeGameViewModel viewModel;

  const AssetSelectorModal({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, UpgradeGameViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssetSelectorModal(viewModel: viewModel),
    );
  }

  @override
  State<AssetSelectorModal> createState() => _AssetSelectorModalState();
}

class _AssetSelectorModalState extends State<AssetSelectorModal> {
  AssetModalTab _currentTab = AssetModalTab.ton;
  late TextEditingController _tonController;
  late TextEditingController _starsController;

  @override
  void initState() {
    super.initState();
    final vm = widget.viewModel;
    _tonController = TextEditingController(
      text: vm.additionalTon > 0 ? vm.additionalTon.toString() : '',
    );
    _starsController = TextEditingController(
      text: vm.additionalStars > 0 ? vm.additionalStars.toString() : '',
    );
  }

  @override
  void dispose() {
    _tonController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D101D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFFA3E635).withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 24,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFA3E635).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFA3E635).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFA3E635),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UPGRADE BET ASSETS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Select TON, Stars, or Gifts from inventory',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tab Bar (TON | Stars | Gifts)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      tab: AssetModalTab.ton,
                      label: '💎 TON',
                      activeColor: const Color(0xFF22D3EE),
                      activeTextColor: Colors.black,
                    ),
                    _buildTabButton(
                      tab: AssetModalTab.stars,
                      label: '⭐ Stars',
                      activeColor: const Color(0xFFFBBF24),
                      activeTextColor: Colors.black,
                    ),
                    _buildTabButton(
                      tab: AssetModalTab.gifts,
                      label: '🎁 Gifts (${vm.selectedInventoryGifts.length}/4)',
                      activeColor: const Color(0xFFA855F7),
                      activeTextColor: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Active Tab Content
              if (_currentTab == AssetModalTab.ton) _buildTonTab(vm),
              if (_currentTab == AssetModalTab.stars) _buildStarsTab(vm),
              if (_currentTab == AssetModalTab.gifts) _buildGiftsTab(vm),

              const SizedBox(height: 16),

              // Bet Total & Win Chance Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CALCULATED BET TOTAL',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vm.totalBetValue} ${vm.currency == UpgradeCurrency.ton ? 'TON' : '⭐'}',
                          style: const TextStyle(
                            color: Color(0xFFA3E635),
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'WIN CHANCE',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${vm.winChancePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Confirm Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedbackService.tap();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8CC63F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'CONFIRM BET SELECTION',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required AssetModalTab tab,
    required String label,
    required Color activeColor,
    required Color activeTextColor,
  }) {
    final isActive = _currentTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedbackService.tap();
          setState(() => _currentTab = tab);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? activeTextColor : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTonTab(UpgradeGameViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your TON Balance:',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              '${vm.inventory.tonBalance.toStringAsFixed(3)} TON',
              style: const TextStyle(
                color: Color(0xFF22D3EE),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input with MAX button
        TextField(
          controller: _tonController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          onChanged: (text) {
            final val = double.tryParse(text) ?? 0.0;
            vm.setAdditionalTon(val);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black38,
            hintText: 'Enter TON bet amount...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF22D3EE)),
            ),
            suffixIcon: TextButton(
              onPressed: () {
                final maxBal = vm.inventory.tonBalance;
                _tonController.text = maxBal.toStringAsFixed(2);
                vm.setAdditionalTon(maxBal);
                HapticFeedbackService.tap();
              },
              child: const Text(
                'MAX',
                style: TextStyle(
                  color: Color(0xFF22D3EE),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Presets row: +0.1, +0.5, +1.0, +2.0, Clear
        Row(
          children: [
            ...[0.1, 0.5, 1.0, 2.0].map((inc) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    onPressed: () {
                      final next = vm.additionalTon + inc;
                      _tonController.text = next.toStringAsFixed(2);
                      vm.setAdditionalTon(next);
                      HapticFeedbackService.tap();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '+$inc',
                      style: const TextStyle(
                        color: Color(0xFF22D3EE),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: OutlinedButton(
                  onPressed: () {
                    _tonController.clear();
                    vm.setAdditionalTon(0);
                    HapticFeedbackService.tap();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStarsTab(UpgradeGameViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Stars Balance:',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              '${vm.inventory.starsBalance} ⭐',
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input with MAX button
        TextField(
          controller: _starsController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          onChanged: (text) {
            final val = int.tryParse(text) ?? 0;
            vm.setAdditionalStars(val);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black38,
            hintText: 'Enter Stars bet amount...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFBBF24)),
            ),
            suffixIcon: TextButton(
              onPressed: () {
                final maxBal = vm.inventory.starsBalance;
                _starsController.text = maxBal.toString();
                vm.setAdditionalStars(maxBal);
                HapticFeedbackService.tap();
              },
              child: const Text(
                'MAX',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Presets row: +25, +50, +100, +250, Clear
        Row(
          children: [
            ...[25, 50, 100, 250].map((inc) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    onPressed: () {
                      final next = vm.additionalStars + inc;
                      _starsController.text = next.toString();
                      vm.setAdditionalStars(next);
                      HapticFeedbackService.tap();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '+$inc',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: OutlinedButton(
                  onPressed: () {
                    _starsController.clear();
                    vm.setAdditionalStars(0);
                    HapticFeedbackService.tap();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGiftsTab(UpgradeGameViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Gifts from Inventory (${vm.inventory.gifts.length}):',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              '${vm.selectedInventoryGifts.length}/4 Selected',
              style: const TextStyle(
                color: Color(0xFFA855F7),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        InventoryGalleryView(
          inventoryGifts: vm.inventory.gifts,
          selectedGifts: vm.selectedInventoryGifts,
          onToggleGift: (gift) => vm.toggleInventoryGift(gift),
          maxHeight: 220,
        ),
      ],
    );
  }
}

