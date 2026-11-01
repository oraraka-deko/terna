import 'package:flutter/material.dart';
import 'package:terna/features/bump_game/view_models/bump_game_view_model.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'package:terna/services/bump_game/bump_audio_service.dart';
import 'package:terna/widgets/bump_game/bump_canvas_widget.dart';
import 'package:terna/widgets/bump_game/bump_pool_info_widget.dart';
import 'package:terna/widgets/bump_game/bump_player_roster_widget.dart';
import 'package:terna/widgets/bump_game/bump_betting_controls.dart';
import 'package:terna/widgets/bump_game/bump_history_tab.dart';
import 'package:terna/widgets/bump_game/bump_victory_modal.dart';
import 'package:terna/widgets/bump_game/bump_replay_modal.dart';
import 'package:terna/widgets/bump_game/bump_provably_fair_modal.dart';

/// Flagship Arena Bump (Bump Arena) Game Screen
class BumpGameScreen extends StatefulWidget {
  const BumpGameScreen({super.key});

  @override
  State<BumpGameScreen> createState() => _BumpGameScreenState();
}

class _BumpGameScreenState extends State<BumpGameScreen> {
  late final BumpGameViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BumpGameViewModel();
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
                  'Arena Bump',
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
                    color: Color(0xFF8B5CF6),
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
                  BumpAudioService.soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    BumpAudioService.toggleSound();
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
                              // 1. Top Tabs & Pool Header
                              BumpPoolInfoWidget(
                                roundId: _viewModel.roundId,
                                status: _viewModel.status,
                                totalPotTon: _viewModel.totalPotTon,
                                totalPotStars: _viewModel.totalPotStars,
                                countdownMs: _viewModel.countdownMs,
                                activeTab: _viewModel.activeTab,
                                onTabChanged: _viewModel.setActiveTab,
                              ),
                              const SizedBox(height: 12),

                              if (_viewModel.activeTab == 'current') ...[
                                // 2. 460x460 Arena Canvas
                                BumpCanvasWidget(
                                  balls: _viewModel.balls,
                                  hazards: _viewModel.hazards,
                                  status: _viewModel.status,
                                  winner: _viewModel.winner,
                                ),
                                const SizedBox(height: 12),

                                // 3. Betting Controls
                                BumpBettingControls(
                                  status: _viewModel.status,
                                  userTonBalance: _viewModel.userTonBalance,
                                  userStarsBalance: _viewModel.userStarsBalance,
                                  onPlaceBet: (curr, amt) {
                                    _viewModel.placeUserBet(currency: curr, amount: amt);
                                  },
                                ),
                                const SizedBox(height: 12),

                                // 4. Player Roster & Provably Fair Accordion
                                BumpPlayerRosterWidget(
                                  balls: _viewModel.balls,
                                  serverSeedHash: _viewModel.serverSeedHash,
                                  onOpenProvablyFair: () => _viewModel.setShowProvablyFairModal(true),
                                ),
                                const SizedBox(height: 24),
                              ] else ...[
                                // History Tab
                                BumpHistoryTab(
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
              if (_viewModel.status == BumpRoundStatus.roundOver && _viewModel.winner != null)
                Positioned.fill(
                  child: BumpVictoryModal(
                    roundId: _viewModel.roundId,
                    winner: _viewModel.winner!,
                    totalPotTon: _viewModel.totalPotTon,
                    totalPotStars: _viewModel.totalPotStars,
                    serverSeedHash: _viewModel.serverSeedHash,
                    revealedServerSeed: _viewModel.revealedServerSeed ?? '',
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
                  child: BumpReplayModal(
                    record: _viewModel.replayRound!,
                    onClose: _viewModel.closeReplay,
                  ),
                ),

              // Provably Fair Modal Overlay
              if (_viewModel.showProvablyFairModal)
                Positioned.fill(
                  child: BumpProvablyFairModal(
                    serverSeedHash: _viewModel.serverSeedHash,
                    revealedServerSeed: _viewModel.revealedServerSeed,
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

