import 'package:flutter/material.dart';
import '../../features/higher_lower/view_models/higher_lower_view_model.dart';
import '../../models/higher_lower/higher_lower_models.dart';
import '../../widgets/higher_lower/higher_lower_header_widget.dart';
import '../../widgets/higher_lower/higher_lower_status_widget.dart';
import '../../widgets/higher_lower/higher_lower_table_widget.dart';
import '../../widgets/higher_lower/higher_lower_bet_controls_widget.dart';
import '../../widgets/higher_lower/higher_lower_prediction_buttons_widget.dart';
import '../../widgets/higher_lower/higher_lower_action_button_widget.dart';
import '../../widgets/higher_lower/higher_lower_rules_dialog.dart';
import '../../widgets/higher_lower/higher_lower_history_dialog.dart';

/// Screen for the Higher or Lower card guessing game.
/// Single-player, turn-based streak-multiplier card game supporting TON and Stars.
class HigherLowerGameScreen extends StatefulWidget {
  const HigherLowerGameScreen({super.key});

  @override
  State<HigherLowerGameScreen> createState() => _HigherLowerGameScreenState();
}

class _HigherLowerGameScreenState extends State<HigherLowerGameScreen> {
  late final HigherLowerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HigherLowerViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _handleStartGame() {
    final started = _viewModel.startGame();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient ${_viewModel.currency == HigherLowerCurrency.stars ? "Stars" : "TON"} balance!',
          ),
          backgroundColor: const Color(0xFF7F1D1D),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final isInteractive = _viewModel.state == HigherLowerRoundState.playing ||
            _viewModel.state == HigherLowerRoundState.correct;

        return Scaffold(
          backgroundColor: const Color(0xFF13060E),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF3B0B1F), // Deep wine felt highlight
                  Color(0xFF1D050F),
                  Color(0xFF0D0207),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Header
                  HigherLowerHeaderWidget(
                    deckCount: _viewModel.remainingCardsCount,
                    historyCount: _viewModel.drawnHistory.length,
                    onBack: () => Navigator.of(context).maybePop(),
                    onShowRules: () => HigherLowerRulesDialog.show(context),
                    onShowHistory: () => HigherLowerHistoryDialog.show(
                      context,
                      history: _viewModel.repository.history,
                      currentRoundDrawn: _viewModel.drawnHistory,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Dynamic Outcome / Instruction Status Banner
                  HigherLowerStatusWidget(
                    state: _viewModel.state,
                    potentialPayout: _viewModel.potentialPayout,
                    currency: _viewModel.currency,
                  ),

                  // Center Felt Table with Stacked Cards and Multiplier Ladder
                  Expanded(
                    child: Center(
                      child: HigherLowerTableWidget(
                        currentCard: _viewModel.currentCard,
                        drawnHistory: _viewModel.drawnHistory,
                        state: _viewModel.state,
                        higherMultiplier: _viewModel.nextHigherMultiplier,
                        currentMultiplier: _viewModel.currentMultiplier,
                        lowerMultiplier: _viewModel.nextLowerMultiplier,
                        canCallHigher: _viewModel.canCallHigher,
                        canCallLower: _viewModel.canCallLower,
                        isEdgeCard: _viewModel.isEdgeCard,
                      ),
                    ),
                  ),

                  // Bottom Controls Panel
                  Container(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bet and Max Win Cards
                        HigherLowerBetControlsWidget(
                          betAmount: _viewModel.betAmount,
                          currency: _viewModel.currency,
                          maxWin: _viewModel.maxWinPreview,
                          isInteractive: _viewModel.state == HigherLowerRoundState.idle ||
                              _viewModel.state == HigherLowerRoundState.wrong ||
                              _viewModel.state == HigherLowerRoundState.collected,
                          onBetChanged: _viewModel.setBetAmount,
                          onCurrencyChanged: _viewModel.setCurrency,
                        ),

                        const SizedBox(height: 10),

                        // Prediction Buttons (Higher & Lower / Skip)
                        HigherLowerPredictionButtonsWidget(
                          isInteractive: isInteractive,
                          canCallHigher: _viewModel.canCallHigher,
                          canCallLower: _viewModel.canCallLower,
                          isEdgeCard: _viewModel.isEdgeCard,
                          higherMultiplier: _viewModel.nextHigherMultiplier,
                          lowerMultiplier: _viewModel.nextLowerMultiplier,
                          onCall: (call) => _viewModel.makePrediction(call),
                        ),

                        const SizedBox(height: 10),

                        // Main Action Button (Start game / Collect / Play again)
                        HigherLowerActionButtonWidget(
                          state: _viewModel.state,
                          betAmount: _viewModel.betAmount,
                          potentialPayout: _viewModel.potentialPayout,
                          currency: _viewModel.currency,
                          wins: _viewModel.totalWins,
                          onStartGame: _handleStartGame,
                          onCollect: _viewModel.collect,
                          onPlayAgain: _viewModel.playAgain,
                          onSwitchWallet: () {
                            _viewModel.setCurrency(
                              _viewModel.currency == HigherLowerCurrency.stars
                                  ? HigherLowerCurrency.ton
                                  : HigherLowerCurrency.stars,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

