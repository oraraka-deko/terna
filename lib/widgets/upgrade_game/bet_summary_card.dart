import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';
import 'gift_visual_widget.dart';

/// "YOUR BET" Card displaying current wager assets (gifts, TON, Stars).
class BetSummaryCard extends StatelessWidget {
  final UpgradeGameViewModel viewModel;
  final VoidCallback onTap;

  const BetSummaryCard({
    super.key,
    required this.viewModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = viewModel.currency == UpgradeCurrency.ton ? '💎' : '⭐';
    final hasBet = viewModel.totalBetValue > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: viewModel.isSpinning ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 165,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF11141F),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasBet ? const Color(0xFF00F0FF).withValues(alpha: 0.35) : Colors.white10,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              const Text(
                'YOUR BET',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),

              // Content Area
              Expanded(
                child: Center(
                  child: !hasBet
                      ? _buildEmptyPlaceholder()
                      : _buildActiveBetContent(),
                ),
              ),

              // Footer: Total Bet Value
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currencySymbol,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    viewModel.totalBetValue > 0
                        ? (viewModel.currency == UpgradeCurrency.ton
                            ? viewModel.totalBetValue.toStringAsFixed(2)
                            : viewModel.totalBetValue.toInt().toString())
                        : '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white24,
          style: BorderStyle.solid,
          width: 1.2,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: Color(0xFFA3E635), size: 22),
          SizedBox(height: 2),
          Text(
            'Add bet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBetContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Selected Gifts Icons Row
        if (viewModel.selectedInventoryGifts.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: viewModel.selectedInventoryGifts.map((gift) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                    ),
                    child: GiftVisualWidget(
                      gift: gift,
                      size: 26,
                      animate: false,
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => viewModel.toggleInventoryGift(gift),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 9, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

        // Currency Chips
        if (viewModel.additionalTon > 0 || viewModel.additionalStars > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Wrap(
              spacing: 4,
              children: [
                if (viewModel.additionalTon > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '💎 +${viewModel.additionalTon} TON',
                      style: const TextStyle(
                        color: Color(0xFF67E8F9),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                if (viewModel.additionalStars > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '⭐ +${viewModel.additionalStars}',
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
              ],
            ),
          ),

        const SizedBox(height: 4),
        const Text(
          'Edit Bet',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}

