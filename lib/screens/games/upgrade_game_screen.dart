import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';
import '../../services/haptic.dart';
import '../../services/upgrade_game/upgrade_gifts_repository.dart';
import '../../widgets/upgrade_game/asset_selector_modal.dart';
import '../../widgets/upgrade_game/bet_summary_card.dart';
import '../../widgets/upgrade_game/spin_outcome_banner.dart';
import '../../widgets/upgrade_game/target_gift_card.dart';
import '../../widgets/upgrade_game/target_gift_picker_modal.dart';
import '../../widgets/upgrade_game/upgrade_action_buttons.dart';
import '../../widgets/upgrade_game/upgrade_wheel_widget.dart';

/// Full Upgrade Game Screen ported from UpgradeGame.tsx.
/// Adapts responsively across mobile, web, and desktop windows.
class UpgradeGameScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const UpgradeGameScreen({
    super.key,
    this.onBack,
  });

  @override
  State<UpgradeGameScreen> createState() => _UpgradeGameScreenState();
}

class _UpgradeGameScreenState extends State<UpgradeGameScreen> with SingleTickerProviderStateMixin {
  late final UpgradeGameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = UpgradeGameViewModel(
      repository: UpgradeGiftsRepository(),
      vsync: this,
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleBack() {
    HapticFeedbackService.tap();
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B11),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive width constraint: max 440px centered
            final availableWidth = constraints.maxWidth;
            final contentWidth = availableWidth > 440.0 ? 440.0 : availableWidth;
            final wheelDiameter = contentWidth < 340 ? (contentWidth - 40) : 280.0;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    if (_viewModel.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3E635)),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Header Bar (Back button + Currency balance pill)
                          _buildTopHeader(),

                          const SizedBox(height: 10),

                          // 2. Interactive Wheel Area
                          UpgradeWheelWidget(
                            viewModel: _viewModel,
                            size: wheelDiameter,
                            onOpenTargetPicker: () {
                              TargetGiftPickerModal.show(context, _viewModel);
                            },
                          ),

                          const SizedBox(height: 14),

                          // 3. Symmetric Cards Grid (YOUR BET & TARGET GIFT)
                          Row(
                            children: [
                              Expanded(
                                child: BetSummaryCard(
                                  viewModel: _viewModel,
                                  onTap: () {
                                    AssetSelectorModal.show(context, _viewModel);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TargetGiftCard(
                                  viewModel: _viewModel,
                                  onTap: () {
                                    TargetGiftPickerModal.show(context, _viewModel);
                                  },
                                ),
                              ),
                            ],
                          ),

                          // 4. Target Multiplier Constraint Warning
                          if (!_viewModel.isValidTarget && _viewModel.totalBetValue > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  'Target must be at least ${_viewModel.minMultiplier}x your bet value (currently ${_viewModel.targetRatio}x). Choose a higher target or reduce bet.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFCD34D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // 5. Action Row: Spin button & Demo button
                          UpgradeActionButtons(viewModel: _viewModel),

                          // 6. Outcome Reveal Banner
                          if (_viewModel.lastResult != null)
                            SpinOutcomeBanner(result: _viewModel.lastResult!),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final isTon = _viewModel.currency == UpgradeCurrency.ton;
    final currentBal = isTon
        ? _viewModel.inventory.tonBalance.toStringAsFixed(2)
        : _viewModel.inventory.starsBalance.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _viewModel.isSpinning ? null : _handleBack,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right: Currency Balance Pill (Tap to toggle currency)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _viewModel.isSpinning
                ? null
                : () {
                    HapticFeedbackService.tap();
                    _viewModel.setCurrency(
                      isTon ? UpgradeCurrency.stars : UpgradeCurrency.ton,
                    );
                  },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF112338),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Text(isTon ? '💎' : '⭐', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    currentBal,
                    style: const TextStyle(
                      color: Color(0xFF67E8F9),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

