import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'package:terna/services/bump_game/bump_physics_service.dart';
import 'package:terna/services/bump_game/bump_audio_service.dart';
import 'package:terna/services/bump_game/bump_game_repository.dart';
import 'package:terna/services/territory_game/npc_engine_service.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';

/// ViewModel managing Arena Bump continuous rounds, physics loop and edge hazards
class BumpGameViewModel extends ChangeNotifier {
  final BumpGameRepository _repository;
  final math.Random _random = math.Random();

  int _roundId = 20492;
  int get roundId => _roundId;

  BumpRoundStatus _status = BumpRoundStatus.waitingForPlayers;
  BumpRoundStatus get status => _status;

  String _serverSeedHash = '';
  String get serverSeedHash => _serverSeedHash;

  String? _revealedServerSeed;
  String? get revealedServerSeed => _revealedServerSeed;

  List<BumpPlayerBall> _balls = [];
  List<BumpPlayerBall> get balls => _balls;

  final List<EdgeHazard> _hazards = [];
  List<EdgeHazard> get hazards => _hazards;

  BumpPlayerBall? _winner;
  BumpPlayerBall? get winner => _winner;

  int _countdownMs = 20000;
  final Set<int> _scheduledJoinSeconds = {};
  int get countdownMs => _countdownMs;

  double get userTonBalance => _repository.userTonBalance;
  int get userStarsBalance => _repository.userStarsBalance;
  List<BumpRoundHistory> get historyRecords => _repository.historyRecords;

  // Active top segment tab: 'current' vs 'history'
  String _activeTab = 'current';
  String get activeTab => _activeTab;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  // Selected round for video playback modal
  BumpRoundHistory? _replayRound;
  BumpRoundHistory? get replayRound => _replayRound;

  void openReplay(BumpRoundHistory record) {
    _replayRound = record;
    notifyListeners();
  }

  void closeReplay() {
    _replayRound = null;
    notifyListeners();
  }

  // Provably fair modal
  bool _showProvablyFairModal = false;
  bool get showProvablyFairModal => _showProvablyFairModal;

  void setShowProvablyFairModal(bool show) {
    _showProvablyFairModal = show;
    notifyListeners();
  }

  Timer? _countdownTimer;
  Timer? _physicsTimer;
  Timer? _hazardTimer;
  final List<BumpReplayFrame> _currentReplayFrames = [];
  double _battleElapsedMs = 0.0;

  BumpGameViewModel({BumpGameRepository? repository})
      : _repository = repository ?? BumpGameRepository() {
    _init();
  }

  Future<void> _init() async {
    await NpcEngineService.init();
    _startNewRound();
  }

  /// Calculates total pot across all participants
  double get totalPotTon {
    return _balls.where((b) => b.currency == 'ton').fold<double>(0.0, (s, b) => s + b.betAmount);
  }

  int get totalPotStars {
    return _balls.where((b) => b.currency == 'stars').fold<int>(0, (s, b) => s + b.betAmount.toInt());
  }

  /// Starts a fresh unlimited round
  void _startNewRound() {
    _countdownTimer?.cancel();
    _physicsTimer?.cancel();
    _hazardTimer?.cancel();

    _roundId++;
    _battleElapsedMs = 0.0;
    _currentReplayFrames.clear();
    _hazards.clear();
    _winner = null;

    final rawSeed = 'bump_round_${_roundId}_${_random.nextInt(9999999)}';
    _revealedServerSeed = rawSeed;
    _serverSeedHash = sha256.convert(utf8.encode(rawSeed)).toString();

    // 1. First tiny ball/core: System Bot Player that puts random initial odds in game
    // System bot starts each round placing a random amount of Stars between 10 to 150
    final botStars = (10 + _random.nextInt(141)).toDouble();
    final systemBot = BumpPlayerBall(
      id: 'system_core',
      username: 'Arena Core',
      avatar: '',
      color: const Color(0xFFF97316),
      isSystemBot: true,
      betAmount: botStars,
      currency: 'stars',
      radius: 35.0, // x2.5 starter presence without inflating asset value
      targetRadius: 35.0,
      mass: 35.0 * 35.0,
      // PLACEHOLDER: system bot player
      isPlaceholder: true,
    );

    _balls = [systemBot];
    BumpPhysicsService.arrangePerimeterBalls(_balls);
    BumpAudioService.playCoin(); // Coin sound for bot placement

    _status = BumpRoundStatus.waitingForPlayers;
    _countdownMs = 20000;
    _scheduledJoinSeconds.clear();
    notifyListeners();

    // Automatically spawn an initial challenger NPC after a random delay (1.5s - 4.5s) if user hasn't joined yet
    final initialDelayMs = 1500 + _random.nextInt(3000);
    Future.delayed(Duration(milliseconds: initialDelayMs), () {
      if (_status == BumpRoundStatus.waitingForPlayers && _balls.length == 1) {
        _spawnNpcPlayer();
      }
    });
  }

  /// Spawns an authentic NPC player from dataset
  void _spawnNpcPlayer() {
    if (_status == BumpRoundStatus.battle || _status == BumpRoundStatus.roundOver) return;

    final existingIds = _balls.map((b) => b.id).toSet();
    final npc = NpcEngineService.getRandomNpc(existingIds);
    final color = kVibrantTerritoryColors[_balls.length % kVibrantTerritoryColors.length];

    final isTon = _random.nextDouble() > 0.3;
    final amount = isTon
        ? double.parse((0.3 + (_random.nextInt(18) * 0.1)).toStringAsFixed(2))
        : (25 + _random.nextInt(175)).toDouble();

    final newBall = BumpPlayerBall(
      id: 'npc_${npc.userId}',
      username: npc.displayName,
      firstName: npc.firstName,
      avatar: npc.avatarAssetPath,
      color: color,
      betAmount: amount,
      currency: isTon ? 'ton' : 'stars',
      isPlaceholder: true,
    );

    _balls.add(newBall);
    BumpPhysicsService.updateBallMetrics(_balls);
    BumpPhysicsService.arrangePerimeterBalls(_balls);
    BumpAudioService.playCoin();

    // If >= 2 players and waiting, start countdown
    if (_balls.length >= 2 && _status == BumpRoundStatus.waitingForPlayers) {
      _startCountdown();
    }

    notifyListeners();
  }

  /// Begins 20s pre-round betting countdown with organic join scheduling
  void _startCountdown() {
    _status = BumpRoundStatus.countdown;
    _countdownMs = 20000; // 20s countdown
    _scheduledJoinSeconds.clear();

    // Pick 0 to 3 additional organic joins at random countdown seconds (between 2s and 18s)
    final extraJoins = _random.nextInt(4);
    while (_scheduledJoinSeconds.length < extraJoins) {
      _scheduledJoinSeconds.add(2 + _random.nextInt(17));
    }

    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_status != BumpRoundStatus.countdown) {
        timer.cancel();
        return;
      }

      _countdownMs -= 1000;
      final s = (_countdownMs / 1000).ceil();

      if (s == 3) {
        BumpAudioService.playBettingClosed();
      } else if (s <= 5 && s > 0) {
        BumpAudioService.playWarningBeep();
      }

      // Trigger scheduled organic challenger joins
      if (_scheduledJoinSeconds.contains(s) && _balls.length < 8) {
        _spawnNpcPlayer();
      }

      if (_countdownMs <= 0) {
        timer.cancel();
        _launchBattle();
      } else {
        notifyListeners();
      }
    });
  }

  /// Places a bet from the local user
  bool placeUserBet({required String currency, required double amount}) {
    if (_status != BumpRoundStatus.waitingForPlayers && _status != BumpRoundStatus.countdown) {
      return false;
    }

    final success = _repository.debitUserBalance(currency, amount);
    if (!success) return false;

    const userId = 'current_user';
    final existingIdx = _balls.indexWhere((b) => b.id == userId);

    if (existingIdx >= 0) {
      final existing = _balls[existingIdx];
      existing.betAmount += amount;
    } else {
      final userBall = BumpPlayerBall(
        id: userId,
        username: '@You',
        firstName: 'You',
        avatar: '', // uses initials
        color: const Color(0xFFC084FC), // Neon lavender
        isUser: true,
        betAmount: amount,
        currency: currency,
        isPlaceholder: true,
      );
      _balls.add(userBall);
    }

    BumpPhysicsService.updateBallMetrics(_balls);
    BumpPhysicsService.arrangePerimeterBalls(_balls);
    BumpAudioService.playCoin();

    if (_balls.length >= 2 && _status == BumpRoundStatus.waitingForPlayers) {
      _startCountdown();
    }

    notifyListeners();
    return true;
  }

  /// Starts the battle! Pushes balls to center & activates edge hazard cycle
  void _launchBattle() {
    _status = BumpRoundStatus.battle;
    _battleElapsedMs = 0.0;
    _hazards.clear();
    _currentReplayFrames.clear();

    BumpPhysicsService.applyLaunchImpulse(_balls);
    BumpAudioService.playLaunchImpulse();
    notifyListeners();

    // Start 60fps physics simulation
    _startPhysicsLoop();

    // Schedule dynamic edge hazards
    _scheduleNextHazard(initialDelayMs: 1600);
  }

  void _startPhysicsLoop() {
    _physicsTimer?.cancel();
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_status != BumpRoundStatus.battle) return;

      const dt = 0.016;
      _battleElapsedMs += 16.0;

      // Update active edge hazards
      _updateHazards(16.0);

      // Physics tick (zero gravity + elastic bump + edge elimination)
      BumpPhysicsService.updatePhysicsStep(
        dt: dt,
        balls: _balls,
        hazards: _hazards,
        onBallBump: (intensity) => BumpAudioService.playBallBump(intensity),
        onWallBump: (intensity) => BumpAudioService.playWallBump(intensity),
        onEliminated: (ball) => BumpAudioService.playEliminated(),
      );

      // Record frame for video replay (every 2nd tick for compactness)
      if (_battleElapsedMs.toInt() % 32 == 0) {
        _recordReplayFrame();
      }

      // Check win condition: Last remaining alive ball
      final aliveBalls = _balls.where((b) => b.state == BallState.alive || b.state == BallState.exiting).toList();
      final trulyAlive = _balls.where((b) => b.state == BallState.alive).toList();

      if (aliveBalls.length <= 1) {
        final winnerBall = trulyAlive.isNotEmpty ? trulyAlive.first : (aliveBalls.isNotEmpty ? aliveBalls.first : _balls.first);
        _resolveWinner(winnerBall);
      }

      notifyListeners();
    });
  }

  void _recordReplayFrame() {
    final frame = BumpReplayFrame(
      timeMs: _battleElapsedMs,
      ballStates: _balls.map((b) => (
        x: b.x,
        y: b.y,
        radius: b.radius,
        state: b.state,
        opacity: b.exitOpacity,
      )).toList(),
      hazards: _hazards.map((h) => (
        side: h.side,
        start: h.startCoord,
        end: h.endCoord,
        status: h.status,
      )).toList(),
    );
    _currentReplayFrames.add(frame);
  }

  /// Updates edge hazards: warning countdown, open duration, and transitions
  void _updateHazards(double deltaMs) {
    for (int i = _hazards.length - 1; i >= 0; i--) {
      final h = _hazards[i];
      h.remainingTimeMs -= deltaMs;

      if (h.status == EdgeHazardStatus.warning && h.remainingTimeMs <= 0) {
        // Warning finished -> Open gap!
        h.status = EdgeHazardStatus.open;
        h.remainingTimeMs = h.totalOpenTimeMs;
        BumpAudioService.playEdgeOpen();

        // When open, schedule next warning to start before this one closes
        _scheduleNextHazard(initialDelayMs: 3800);
      } else if (h.status == EdgeHazardStatus.open && h.remainingTimeMs <= 0) {
        // Open duration finished -> close and remove
        _hazards.removeAt(i);
      }
    }
  }

  /// Schedules a random edge segment hazard (or larger sudden death hazard)
  void _scheduleNextHazard({required int initialDelayMs}) {
    _hazardTimer?.cancel();
    _hazardTimer = Timer(Duration(milliseconds: initialDelayMs), () {
      if (_status != BumpRoundStatus.battle) return;

      // Select a wall side not currently warning or open
      final busySides = _hazards.map((h) => h.side).toSet();
      final availableSides = WallSide.values.where((s) => !busySides.contains(s)).toList();
      final side = availableSides.isNotEmpty
          ? availableSides[_random.nextInt(availableSides.length)]
          : WallSide.values[_random.nextInt(WallSide.values.length)];

      // Late game sudden death: larger openings
      final isSuddenDeath = _battleElapsedMs > 20000.0;
      final gapSize = isSuddenDeath ? (160.0 + _random.nextInt(80)) : (90.0 + _random.nextInt(50));

      // Choose start and end coordinate along wall
      const wallMin = 54.0;
      const wallMax = 406.0;
      final maxStart = wallMax - gapSize;
      final start = wallMin + _random.nextDouble() * (maxStart - wallMin);
      final end = start + gapSize;

      final hazard = EdgeHazard(
        side: side,
        startCoord: start,
        endCoord: end,
        status: EdgeHazardStatus.warning,
        remainingTimeMs: 2800.0,
      );

      _hazards.add(hazard);
      BumpAudioService.playWarningBeep();
      notifyListeners();
    });
  }

  /// Concludes round with winner announcement, payouts & history archiving
  void _resolveWinner(BumpPlayerBall winningBall) {
    _physicsTimer?.cancel();
    _hazardTimer?.cancel();
    _status = BumpRoundStatus.roundOver;
    _winner = winningBall;

    final potTon = totalPotTon;
    final potStars = totalPotStars;
    final netPayoutTon = potTon > 0 ? double.parse((potTon * 0.95).toStringAsFixed(3)) : 0.0;
    final netPayoutStars = potStars > 0 ? (potStars * 0.95).round() : 0;

    // Credit payout if local user won
    if (winningBall.isUser) {
      _repository.creditUserPayout(netPayoutTon, netPayoutStars);
    }

    // Archive round to history
    final history = BumpRoundHistory(
      roundId: _roundId,
      winner: winningBall,
      participants: _balls.map((b) => b.copy()).toList(),
      totalPotTon: potTon,
      totalPotStars: potStars,
      replayFrames: List.from(_currentReplayFrames),
      serverSeedHash: _serverSeedHash,
      revealedServerSeed: _revealedServerSeed ?? '',
      timestamp: DateTime.now(),
      isPlaceholder: true,
    );
    _repository.archiveRound(history);

    BumpAudioService.playVictory();
    notifyListeners();

    // Continuous infinite cycle: automatically start next round after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (_status == BumpRoundStatus.roundOver) {
        _startNewRound();
      }
    });
  }

  /// Manually starts next round immediately
  void nextRound() {
    _startNewRound();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _physicsTimer?.cancel();
    _hazardTimer?.cancel();
    super.dispose();
  }
}

