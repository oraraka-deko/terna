import 'package:flutter/material.dart';
import 'package:terna/features/territory_game/view_models/territory_game_view_model.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_audio_service.dart';
import 'package:terna/widgets/territory_game/territory_canvas_widget.dart';
import 'package:terna/widgets/territory_game/pool_info_widget.dart';
import 'package:terna/widgets/territory_game/player_roster_widget.dart';
import 'package:terna/widgets/territory_game/territory_betting_controls.dart';
import 'package:terna/widgets/territory_game/territory_history_tab.dart';
import 'package:terna/widgets/territory_game/territory_victory_modal.dart';
import 'package:terna/widgets/territory_game/territory_replay_modal.dart';
import 'package:terna/widgets/territory_game/territory_provably_fair_modal.dart';

/// Flagship Territory Jackpot / PvP Territory Screen
class TerritoryGameScreen extends StatefulWidget {
  const TerritoryGameScreen({super.key});

  @override
  State<TerritoryGameScreen> createState() => _TerritoryGameScreenState();
}

class _TerritoryGameScreenState extends State<TerritoryGameScreen> {
  late final TerritoryGameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TerritoryGameViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final roundState = _viewModel.roundState;

        return Scaffold(
          backgroundColor: const Color(0xFF090A10),
          appBar: AppBar(
            backgroundColor: const Color(0xFF090A10),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Territory Jackpot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'PvP',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  TerritoryAudioService.soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    TerritoryAudioService.toggleSound();
                  });
                },
                tooltip: 'Toggle Audio',
              ),
              IconButton(
                icon: const Icon(
                  Icons.verified_user,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                onPressed: () => _viewModel.setShowProvablyFairModal(true),
                tooltip: 'Provably Fair Verification',
              ),
            ],
          ),
          body: Stack(
            children: [
              // Main Scrollable Area with responsive max-width 440px
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Top Tabs & Pool Info Header
                              PoolInfoWidget(
                                roundState: roundState,
                                activeTab: _viewModel.activeTab,
                                onTabChanged: _viewModel.setActiveTab,
                              ),
                              const SizedBox(height: 12),

                              if (_viewModel.activeTab == 'current') ...[
                                // 2. 460x460 Arena Canvas
                                TerritoryCanvasWidget(
                                  territories: _viewModel.cachedTerritories,
                                  puckX: _viewModel.puckX,
                                  puckY: _viewModel.puckY,
                                  puckActive: _viewModel.puckActive,
                                  isPuckStopped: _viewModel.isPuckStopped,
                                  puckTrail: _viewModel.puckTrail,
                                  isAiming: _viewModel.isAiming,
                                  currentAimAngle: _viewModel.currentAimAngle,
                                  aimOpacity: _viewModel.aimOpacity,
                                  cameraZoom: _viewModel.cameraZoom,
                                  cameraPanX: _viewModel.cameraPanX,
                                  cameraPanY: _viewModel.cameraPanY,
                                  winnerPlayerId: roundState.winningPlayerId,
                                  isCelebrating: roundState.status == RoundStatus.winnerCelebration,
                                ),
                                const SizedBox(height: 12),

                                // 3. Betting Controls
                                TerritoryBettingControls(
                                  roundState: roundState,
                                  userTonBalance: _viewModel.userTonBalance,
                                  userStarsBalance: _viewModel.userStarsBalance,
                                  onPlaceBet: (curr, amt) {
                                    _viewModel.placeUserBet(currency: curr, amount: amt);
                                  },
                                ),
                                const SizedBox(height: 12),

                                // 4. Player Roster & Provably Fair Accordion
                                PlayerRosterWidget(
                                  bets: roundState.bets,
                                  serverSeedHash: roundState.serverSeedHash,
                                  onOpenProvablyFair: () => _viewModel.setShowProvablyFairModal(true),
                                ),
                                const SizedBox(height: 24),
                              ] else ...[
                                // History Tab
                                TerritoryHistoryTab(
                                  historyRecords: _viewModel.historyRecords,
                                  onWatchReplay: _viewModel.openReplay,
                                  onBackToGame: () => _viewModel.setActiveTab('current'),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Victory Celebration Modal Overlay
              if (roundState.status == RoundStatus.winnerCelebration)
                Positioned.fill(
                  child: TerritoryVictoryModal(
                    roundState: roundState,
                    onClose: _viewModel.nextRound,
                    onWatchReplay: () {
                      if (_viewModel.historyRecords.isNotEmpty) {
                        _viewModel.openReplay(_viewModel.historyRecords.first);
                      }
                    },
                  ),
                ),

              // Video Replay Modal Overlay
              if (_viewModel.replayRound != null)
                Positioned.fill(
                  child: TerritoryReplayModal(
                    record: _viewModel.replayRound!,
                    onClose: _viewModel.closeReplay,
                  ),
                ),

              // Provably Fair Modal Overlay
              if (_viewModel.showProvablyFairModal)
                Positioned.fill(
                  child: TerritoryProvablyFairModal(
                    roundState: roundState,
                    onClose: () => _viewModel.setShowProvablyFairModal(false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

