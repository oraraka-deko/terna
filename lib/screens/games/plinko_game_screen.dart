import 'package:flutter/material.dart';
import '../../features/plinko_game/view_models/plinko_game_view_model.dart';
import '../../services/haptic.dart';
import '../../services/plinko_game/plinko_game_repository.dart';
import '../../widgets/plinko_game/plinko_bet_controls_widget.dart';
import '../../widgets/plinko_game/plinko_board_widget.dart';
import '../../widgets/plinko_game/plinko_drop_button.dart';
import '../../widgets/plinko_game/plinko_header_bar.dart';
import '../../widgets/plinko_game/plinko_history_strip.dart';

/// Full Plinko Game Screen ported from PlinkoGame.tsx.
/// Follows responsive layout and clean MVVM architecture.
class PlinkoGameScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const PlinkoGameScreen({
    super.key,
    this.onBack,
  });

  @override
  State<PlinkoGameScreen> createState() => _PlinkoGameScreenState();
}

class _PlinkoGameScreenState extends State<PlinkoGameScreen> with SingleTickerProviderStateMixin {
  late final PlinkoGameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlinkoGameViewModel(
      repository: PlinkoGameRepository(),
      vsync: this,
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
      backgroundColor: const Color(0xFF060812),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final contentWidth = availableWidth > 440.0 ? 440.0 : availableWidth;

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
                          // 1. Top Header Bar (Back button, Currency switch, Risk selector)
                          PlinkoHeaderBar(
                            viewModel: _viewModel,
                            onBack: _handleBack,
                          ),

                          const SizedBox(height: 10),

                          // 2. Recent Multipliers History Strip
                          if (_viewModel.recentMultipliers.isNotEmpty) ...[
                            PlinkoHistoryStrip(
                              recentMultipliers: _viewModel.recentMultipliers,
                            ),
                            const SizedBox(height: 10),
                          ],

                          // 3. Main Pinboard Frame & Canvas
                          PlinkoBoardWidget(viewModel: _viewModel),

                          const SizedBox(height: 12),

                          // 4. Betting & Presets Controls Panel
                          PlinkoBetControlsWidget(viewModel: _viewModel),

                          const SizedBox(height: 12),

                          // 5. Drop Ball Action Button
                          PlinkoDropButton(viewModel: _viewModel),

                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _viewModel.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFF7B7B),
                                fontSize: 12,
                              ),
                            ),
                          ],

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
}
