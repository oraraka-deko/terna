import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/npc_engine_service.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';
import 'package:terna/services/territory_game/territory_physics_service.dart';
import 'package:terna/services/territory_game/territory_audio_service.dart';
import 'package:terna/services/territory_game/territory_game_repository.dart';

/// ViewModel managing Territory PvP game flow, state machine, timers and physics updates
class TerritoryGameViewModel extends ChangeNotifier {
  final TerritoryGameRepository _repository;

  late CurrentRoundState _roundState;
  CurrentRoundState get roundState => _roundState;

  // Active top-level tab: 'current' or 'history'
  String _activeTab = 'current';
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  // Selected round for replay modal
  RoundHistoryRecord? _replayRound;
  RoundHistoryRecord? get replayRound => _replayRound;

  void openReplay(RoundHistoryRecord record) {
    _replayRound = record;
    notifyListeners();
  }

  void closeReplay() {
    _replayRound = null;
    notifyListeners();
  }

  // Provably fair modal inspection
  bool _showProvablyFairModal = false;
  bool get showProvablyFairModal => _showProvablyFairModal;

  void setShowProvablyFairModal(bool show) {
    _showProvablyFairModal = show;
    notifyListeners();
  }

  // Timers & animation tracking
  Timer? _countdownTimer;
  Timer? _flightTicker;
  final Stopwatch _flightStopwatch = Stopwatch();
  final Stopwatch _aimStopwatch = Stopwatch();

  // Cached territory slices for current bets
  List<WatertightPolygon> _cachedTerritories = [];
  List<WatertightPolygon> get cachedTerritories => _cachedTerritories;

  // Real-time puck position and animation state
  double puckX = 230.0;
  double puckY = 230.0;
  bool isAiming = false;
  double currentAimAngle = 0.0;
  double aimOpacity = 1.0;
  bool puckActive = false;
  bool isPuckStopped = false;
  double cameraZoom = 1.0;
  double cameraPanX = 230.0;
  double cameraPanY = 230.0;
  final List<TerritoryPoint> puckTrail = [];
  int _nextWallHitIndex = 0;
  double? _stopTimestampMs;

  double get userTonBalance => _repository.userTonBalance;
  int get userStarsBalance => _repository.userStarsBalance;
  List<RoundHistoryRecord> get historyRecords => _repository.historyRecords;

  TerritoryGameViewModel({TerritoryGameRepository? repository})
      : _repository = repository ?? TerritoryGameRepository() {
    _initGame();
  }

  Future<void> _initGame() async {
    await NpcEngineService.init();
    _startNewRound();
  }

  void _startNewRound() {
    _countdownTimer?.cancel();
    _flightTicker?.cancel();
    _flightStopwatch.reset();
    _aimStopwatch.reset();

    _roundState = _repository.createNewRound();
    _cachedTerritories = TerritorySlicingService.computeProportionalTerritories(_roundState.bets);

    puckX = 230.0;
    puckY = 230.0;
    isAiming = false;
    currentAimAngle = 0.0;
    aimOpacity = 1.0;
    puckActive = false;
    isPuckStopped = false;
    cameraZoom = 1.0;
    cameraPanX = 230.0;
    cameraPanY = 230.0;
    puckTrail.clear();
    _nextWallHitIndex = 0;
    _stopTimestampMs = null;

    notifyListeners();
    _startBettingCountdown();
  }

  void _startBettingCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_roundState.status != RoundStatus.bettingOpen) {
        timer.cancel();
        return;
      }

      final newTime = _roundState.timeRemainingMs - 1000;
      final secondsLeft = (newTime / 1000).ceil();

      // Audio countdown feedback
      if (secondsLeft == 3) {
        TerritoryAudioService.playBettingClosed();
      } else if (secondsLeft <= 10 && secondsLeft > 3) {
        TerritoryAudioService.playAlertTick();
      } else if (secondsLeft > 10 && secondsLeft % 5 == 0) {
        TerritoryAudioService.playTick();
      }

      // Periodically spawn realistic NPC opponent bets
      if ((secondsLeft == 12 || secondsLeft == 8 || secondsLeft == 4) &&
          _roundState.bets.length < 6) {
        _spawnNpcBet();
      }

      if (newTime <= 0) {
        timer.cancel();
        _resolveRound();
      } else {
        _roundState = _roundState.copyWith(
          timeRemainingMs: newTime,
          isBettingClosed: newTime <= 2500,
        );
        notifyListeners();
      }
    });
  }

  void _spawnNpcBet() {
    final existingIds = _roundState.bets.map((b) => b.playerId).toSet();
    final npcBet = NpcEngineService.generateNpcBet(
      index: _roundState.bets.length,
      existingPlayerIds: existingIds,
    );

    final updatedBets = List<PlayerBet>.from(_roundState.bets)..add(npcBet);
    final addTon = npcBet.currency == 'ton' ? npcBet.amount : 0.0;
    final addStars = npcBet.currency == 'stars' ? npcBet.amount.toInt() : 0;

    _roundState = _roundState.copyWith(
      bets: updatedBets,
      totalPotTon: _roundState.totalPotTon + addTon,
      totalPotStars: _roundState.totalPotStars + addStars,
    );
    _cachedTerritories = TerritorySlicingService.computeProportionalTerritories(updatedBets);
    TerritoryAudioService.playCoin();
    notifyListeners();
  }

  /// Places a bet from the local user
  bool placeUserBet({required String currency, required double amount}) {
    if (_roundState.status != RoundStatus.bettingOpen || _roundState.isBettingClosed) {
      return false;
    }

    final success = _repository.debitUserBalance(currency, amount);
    if (!success) return false;

    // Check if user already has an active bet this round
    const userId = 'current_user';
    final existingIndex = _roundState.bets.indexWhere((b) => b.playerId == userId);

    final List<PlayerBet> updatedBets = List<PlayerBet>.from(_roundState.bets);
    if (existingIndex >= 0) {
      final existing = updatedBets[existingIndex];
      final newAmt = existing.amount + amount;
      final newWeight = currency == 'ton' ? newAmt * 10.0 : newAmt / 10.0;
      updatedBets[existingIndex] = existing.copyWith(
        amount: newAmt,
        totalBet: newWeight,
      );
    } else {
      final userBet = PlayerBet(
        playerId: userId,
        username: '@You',
        firstName: 'You',
        avatar: '', // uses initials
        color: kVibrantTerritoryColors[updatedBets.length % kVibrantTerritoryColors.length],
        currency: currency,
        amount: amount,
        totalBet: currency == 'ton' ? amount * 10.0 : amount / 10.0,
        // PLACEHOLDER: demo user bet
        isPlaceholder: true,
      );
      updatedBets.add(userBet);
    }

    final addTon = currency == 'ton' ? amount : 0.0;
    final addStars = currency == 'stars' ? amount.toInt() : 0;

    _roundState = _roundState.copyWith(
      bets: updatedBets,
      totalPotTon: _roundState.totalPotTon + addTon,
      totalPotStars: _roundState.totalPotStars + addStars,
    );

    _cachedTerritories = TerritorySlicingService.computeProportionalTerritories(updatedBets);
    TerritoryAudioService.playCoin();
    notifyListeners();
    return true;
  }

  /// Executes trajectory calculation, aiming arrow, flight animation and victory resolution
  void _resolveRound() {
    if (_roundState.bets.isEmpty) {
      _startNewRound();
      return;
    }

    _cachedTerritories = TerritorySlicingService.computeProportionalTerritories(_roundState.bets);

    // Pick winner deterministically based on seed and territory win probabilities
    final rand = math.Random(_roundState.roundId);
    final pick = rand.nextDouble();
    double cumulative = 0.0;
    WatertightPolygon winningTerritory = _cachedTerritories.first;

    for (final poly in _cachedTerritories) {
      cumulative += poly.winProbability;
      if (pick <= cumulative) {
        winningTerritory = poly;
        break;
      }
    }

    final winningPlayerId = winningTerritory.playerId;
    const flightDurationMs = 12000.0;

    // Simulate Air Hockey flight
    final trajectory = TerritoryPhysicsService.simulateAirHockeyFlight(
      seed: _roundState.roundId,
      winnerPlayerId: winningPlayerId,
      territories: _cachedTerritories,
      durationMs: flightDurationMs,
    );

    final winnerBet = _roundState.bets.firstWhere(
      (b) => b.playerId == winningPlayerId,
      orElse: () => _roundState.bets.first,
    );

    // Calculate payouts
    final totalTon = _roundState.totalPotTon;
    final totalStars = _roundState.totalPotStars;
    final netPayoutTon = totalTon > 0 ? double.parse((totalTon * 0.95).toStringAsFixed(3)) : 0.0;
    final netPayoutStars = totalStars > 0 ? (totalStars * 0.95).round() : 0;

    final winnerSummary = RoundWinner(
      playerId: winningPlayerId,
      username: winnerBet.username,
      firstName: winnerBet.firstName,
      avatar: winnerBet.avatar,
      color: winnerBet.color,
      payoutTon: netPayoutTon,
      payoutStars: netPayoutStars,
      winnerPercentage: (winningTerritory.winProbability * 100).roundToDouble(),
    );

    _roundState = _roundState.copyWith(
      status: RoundStatus.roundResolving,
      winningPlayerId: winningPlayerId,
      winner: winnerSummary,
      trajectory: trajectory,
    );

    notifyListeners();
    TerritoryAudioService.playTensionRamp();

    // Start 1.4s Aiming Phase
    isAiming = true;
    _aimStopwatch.reset();
    _aimStopwatch.start();
    const aimDurationMs = 1400.0;

    _flightTicker?.cancel();
    _flightTicker = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final aimElapsed = _aimStopwatch.elapsedMilliseconds.toDouble();

      if (isAiming) {
        if (aimElapsed < aimDurationMs) {
          final frac = (aimElapsed / aimDurationMs).clamp(0.0, 1.0);
          final easeOut = 1.0 - math.pow(1.0 - frac, 3);
          const totalAngleSpin = math.pi * 2 * 3;
          currentAimAngle = (totalAngleSpin + trajectory.launchAngle) * easeOut;
          aimOpacity = frac < 0.85 ? 1.0 : (1.0 - (frac - 0.85) / 0.15);
          notifyListeners();
          return;
        } else {
          isAiming = false;
          _aimStopwatch.stop();
          puckActive = true;
          _flightStopwatch.reset();
          _flightStopwatch.start();
          TerritoryAudioService.playSlapShot();
        }
      }

      // Physics flight progression
      final flightElapsed = _flightStopwatch.elapsedMilliseconds.toDouble();
      final progress = (flightElapsed / flightDurationMs).clamp(0.0, 1.0);
      final sample = TerritoryPhysicsService.sampleTrajectory(trajectory, progress);

      puckX = sample.x;
      puckY = sample.y;
      isPuckStopped = sample.isStopped;

      // Play wall hits
      if (trajectory.wallHits.isNotEmpty) {
        while (_nextWallHitIndex < trajectory.wallHits.length &&
            flightElapsed >= trajectory.wallHits[_nextWallHitIndex].timeMs) {
          TerritoryAudioService.playPuckWallHit(trajectory.wallHits[_nextWallHitIndex].intensity);
          _nextWallHitIndex++;
        }
      }

      // Update ribbon trail
      if (!sample.isStopped) {
        puckTrail.add(TerritoryPoint(sample.x, sample.y));
        if (puckTrail.length > 18) puckTrail.removeAt(0);
      } else {
        if (puckTrail.length > 1) puckTrail.removeAt(0);
      }

      // Post-stop camera zoom
      final stopTimeMs = trajectory.stopTimeMs;
      if (flightElapsed >= stopTimeMs || sample.isStopped) {
        _stopTimestampMs ??= flightElapsed;
        final stopElapsed = flightElapsed - _stopTimestampMs!;

        const zoomDuration = 900.0;
        final zoomFrac = (stopElapsed / zoomDuration).clamp(0.0, 1.0);
        final zoomEase = 1.0 - math.pow(1.0 - zoomFrac, 3);

        cameraZoom = 1.0 + zoomEase * 1.2; // 1.0x -> 2.2x
        cameraPanX = 230.0 + (trajectory.finalX - 230.0) * zoomEase;
        cameraPanY = 230.0 + (trajectory.finalY - 230.0) * zoomEase;

        // Hold for 1.2s before celebration modal
        const holdDuration = 1200.0;
        if (stopElapsed >= zoomDuration + holdDuration) {
          t.cancel();
          _triggerWinnerCelebration(winnerSummary, trajectory);
        }
      }

      notifyListeners();
    });
  }

  void _triggerWinnerCelebration(RoundWinner winner, AirHockeyTrajectory traj) {
    _flightTicker?.cancel();
    _roundState = _roundState.copyWith(
      status: RoundStatus.winnerCelebration,
    );
    cameraZoom = 1.0;
    cameraPanX = 230.0;
    cameraPanY = 230.0;

    // Credit payout if local user won
    if (winner.playerId == 'current_user') {
      _repository.creditUserPayout(winner.payoutTon, winner.payoutStars);
    }

    // Archive completed round
    final historyRecord = RoundHistoryRecord(
      roundId: _roundState.roundId,
      winner: winner,
      players: _roundState.bets,
      totalPotTon: _roundState.totalPotTon,
      totalPotStars: _roundState.totalPotStars,
      trajectory: traj,
      serverSeedHash: _roundState.serverSeedHash,
      revealedServerSeed: _roundState.revealedServerSeed ?? '',
      timestamp: DateTime.now(),
      isPlaceholder: true,
    );
    _repository.archiveRound(historyRecord);

    TerritoryAudioService.playVictory();
    notifyListeners();

    // Auto-advance to new round after celebration
    Future.delayed(const Duration(seconds: 5), () {
      if (_roundState.status == RoundStatus.winnerCelebration) {
        _startNewRound();
      }
    });
  }

  /// Manually starts next round immediately from victory modal
  void nextRound() {
    _startNewRound();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flightTicker?.cancel();
    super.dispose();
  }
}

