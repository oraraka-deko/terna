import 'package:flutter/material.dart';
import '../../features/tower_game/view_models/tower_game_view_model.dart';
import '../../services/haptic.dart';
import '../../services/tower_game/tower_game_repository.dart';
import '../../widgets/tower_game/tower_action_button.dart';
import '../../widgets/tower_game/tower_board_widget.dart';
import '../../widgets/tower_game/tower_controls_widget.dart';
import '../../widgets/tower_game/tower_header_bar.dart';
import '../../widgets/tower_game/tower_outcome_banner.dart';
import '../../widgets/tower_game/tower_provably_fair_footer.dart';

/// Full Tower Climb Game Screen ported from TowerGame.tsx.
/// Follows responsive layout and clean MVVM architecture.
class TowerGameScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TowerGameScreen({
    super.key,
    this.onBack,
  });

  @override
  State<TowerGameScreen> createState() => _TowerGameScreenState();
}

class _TowerGameScreenState extends State<TowerGameScreen> {
  late final TowerGameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TowerGameViewModel(
      repository: TowerGameRepository(),
    );
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
      backgroundColor: const Color(0xFF090D1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final contentWidth = availableWidth > 420.0 ? 420.0 : availableWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Header Bar
                          TowerHeaderBar(
                            viewModel: _viewModel,
                            onBack: _handleBack,
                          ),

                          const SizedBox(height: 10),

                          // 2. Outcome / Win Alert Banner
                          if (_viewModel.lastOutcome != null) ...[
                            TowerOutcomeBanner(outcome: _viewModel.lastOutcome!),
                            const SizedBox(height: 10),
                          ],

                          // 3. 7-Tier Tower Climb Board
                          TowerBoardWidget(viewModel: _viewModel),

                          const SizedBox(height: 10),

                          // 4. Primary Play or Cash Out Button
                          TowerActionButton(viewModel: _viewModel),

                          const SizedBox(height: 10),

                          // 5. Controls Card (Difficulty, Currency, Chips, Bet adjustments)
                          TowerControlsWidget(viewModel: _viewModel),

                          const SizedBox(height: 10),

                          // 6. Provably Fair Seed Footer
                          if (_viewModel.serverSeedHash != null)
                            TowerProvablyFairFooter(
                              serverSeedHash: _viewModel.serverSeedHash!,
                            ),

                          const SizedBox(height: 20),
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
}

