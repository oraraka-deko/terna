import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';
import 'gift_visual_widget.dart';

/// "TARGET GIFT" Card displaying target upgrade gift and target value.
class TargetGiftCard extends StatelessWidget {
  final UpgradeGameViewModel viewModel;
  final VoidCallback onTap;

  const TargetGiftCard({
    super.key,
    required this.viewModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = viewModel.currency == UpgradeCurrency.ton ? '💎' : '⭐';
    final target = viewModel.selectedTargetGift;

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
              color: Colors.white10,
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 2.5, backgroundColor: Colors.white54),
                  SizedBox(width: 4),
                  Text(
                    'TARGET GIFT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              // Content Area: Soft rounded target visual
              Expanded(
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: target != null
                        ? GiftVisualWidget(
                            gift: target,
                            size: 60,
                            animate: true,
                          )
                        : const Center(
                            child: Text(
                              'Select Target',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Footer: Target Gift Price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currencySymbol,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    viewModel.currency == UpgradeCurrency.ton
                        ? viewModel.targetGiftValue.toStringAsFixed(2)
                        : viewModel.targetGiftValue.toInt().toString(),
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
}

