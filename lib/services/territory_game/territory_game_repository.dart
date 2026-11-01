import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/npc_engine_service.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';
import 'package:terna/services/territory_game/territory_physics_service.dart';

/// Repository managing Territory PvP rounds, mock user wallet balances, and game history
class TerritoryGameRepository {
  // PLACEHOLDER: Demo user wallet balances until real backend integration
  double _userTonBalance = 10.0;
  int _userStarsBalance = 100;

  double get userTonBalance => _userTonBalance;
  int get userStarsBalance => _userStarsBalance;

  int _roundCounter = 10842;
  final List<RoundHistoryRecord> _historyRecords = [];

  List<RoundHistoryRecord> get historyRecords => List.unmodifiable(_historyRecords);

  TerritoryGameRepository() {
    _initDemoHistory();
  }

  void _initDemoHistory() {
    // PLACEHOLDER: Initial historical rounds for instant video playback testing
    final demoPlayers = [
      PlayerBet(
        playerId: 'user_demo_1',
        username: '@amsexyledy',
        avatar: 'assets/npc/avatars/7660412004.jpg',
        color: kVibrantTerritoryColors[0],
        currency: 'ton',
        amount: 1.5,
        totalBet: 15.0,
        winProbability: 0.60,
        isPlaceholder: true,
      ),
      PlayerBet(
        playerId: 'user_demo_2',
        username: '@Jevga22',
        avatar: 'assets/npc/avatars/1965297855.jpg',
        color: kVibrantTerritoryColors[1],
        currency: 'ton',
        amount: 1.0,
        totalBet: 10.0,
        winProbability: 0.40,
        isPlaceholder: true,
      ),
    ];

    final territories = TerritorySlicingService.computeProportionalTerritories(demoPlayers);
    final traj = TerritoryPhysicsService.simulateAirHockeyFlight(
      seed: 10841,
      winnerPlayerId: 'user_demo_1',
      territories: territories,
      durationMs: 8000.0,
    );

    _historyRecords.add(RoundHistoryRecord(
      roundId: 10841,
      winner: RoundWinner(
        playerId: 'user_demo_1',
        username: '@amsexyledy',
        avatar: 'assets/npc/avatars/7660412004.jpg',
        color: kVibrantTerritoryColors[0],
        payoutTon: 2.375,
        payoutStars: 0,
        winnerPercentage: 60.0,
      ),
      players: demoPlayers,
      totalPotTon: 2.5,
      totalPotStars: 0,
      trajectory: traj,
      serverSeedHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      revealedServerSeed: 'territory_seed_round_10841_secret_proven_fair',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isPlaceholder: true,
    ));
  }

  /// Creates a new fresh round state
  CurrentRoundState createNewRound() {
    _roundCounter++;
    final rawSeed = 'territory_round_${_roundCounter}_${math.Random().nextInt(9999999)}';
    final seedHash = sha256.convert(utf8.encode(rawSeed)).toString();

    // Initial table with 1 or 2 NPC bets to keep the arena warm
    final initialNpcBet = NpcEngineService.generateNpcBet(index: 0);

    return CurrentRoundState(
      roundId: _roundCounter,
      status: RoundStatus.bettingOpen,
      bets: [initialNpcBet],
      totalPotTon: initialNpcBet.currency == 'ton' ? initialNpcBet.amount : 0.0,
      totalPotStars: initialNpcBet.currency == 'stars' ? initialNpcBet.amount.toInt() : 0,
      timeRemainingMs: 15000,
      serverSeedHash: seedHash,
      revealedServerSeed: rawSeed,
      poolTier: 'STANDARD',
      isBettingClosed: false,
    );
  }

  /// Deducts bet from user balance
  bool debitUserBalance(String currency, double amount) {
    if (currency == 'ton') {
      if (_userTonBalance < amount) return false;
      _userTonBalance = double.parse((_userTonBalance - amount).toStringAsFixed(3));
      return true;
    } else {
      final intStars = amount.toInt();
      if (_userStarsBalance < intStars) return false;
      _userStarsBalance -= intStars;
      return true;
    }
  }

  /// Credits payout to user balance
  void creditUserPayout(double ton, int stars) {
    if (ton > 0) {
      _userTonBalance = double.parse((_userTonBalance + ton).toStringAsFixed(3));
    }
    if (stars > 0) {
      _userStarsBalance += stars;
    }
  }

  /// Archives completed round to history
  void archiveRound(RoundHistoryRecord record) {
    _historyRecords.insert(0, record);
    if (_historyRecords.length > 50) {
      _historyRecords.removeLast();
    }
  }
}
