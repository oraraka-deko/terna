import 'package:terna/services/wallet/wallet_repository.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';
import 'package:terna/services/territory_game/territory_physics_service.dart';

/// Repository managing Territory PvP rounds, mock user wallet balances, and game history
class TerritoryGameRepository {
  double get userTonBalance => WalletRepository().tonBalance.value;
  int get userStarsBalance => WalletRepository().starsBalance.value;

  int _roundCounter = 10842;
  final List<RoundHistoryRecord> _historyRecords = [];
  final Map<int, String> _serverSeeds = {};

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
    const demoServerSeed = 'territory_seed_round_10841_secret_proven_fair';
    final traj = TerritoryPhysicsService.simulateAirHockeyFlight(
      seed: TerritoryPhysicsService.deriveRoundSeed(demoServerSeed, 10841),
      territories: territories,
      durationMs: 8000.0,
    );
    final demoWinner = demoPlayers.firstWhere((player) => player.playerId == traj.winnerPlayerId);
    final winnerTerritory = territories.firstWhere((territory) => territory.playerId == traj.winnerPlayerId);

    _historyRecords.add(RoundHistoryRecord(
      roundId: 10841,
      winner: RoundWinner(
        playerId: demoWinner.playerId,
        username: demoWinner.username,
        avatar: demoWinner.avatar,
        color: demoWinner.color,
        payoutTon: 2.375,
        payoutStars: 0,
        winnerPercentage: winnerTerritory.winProbability * 100,
      ),
      players: demoPlayers,
      totalPotTon: 2.5,
      totalPotStars: 0,
      trajectory: traj,
      serverSeedHash: sha256.convert(utf8.encode(demoServerSeed)).toString(),
      revealedServerSeed: demoServerSeed,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isPlaceholder: true,
    ));
  }

  /// Creates a new fresh round state
  CurrentRoundState createNewRound() {
    _roundCounter++;
    final random = math.Random.secure();
    final rawSeed = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _serverSeeds.clear();
    _serverSeeds[_roundCounter] = rawSeed;
    final seedHash = sha256.convert(utf8.encode(rawSeed)).toString();

    return CurrentRoundState(
      roundId: _roundCounter,
      status: RoundStatus.waitingForPlayers,
      bets: const [],
      totalPotTon: 0,
      totalPotStars: 0,
      timeRemainingMs: 15000,
      serverSeedHash: seedHash,
      poolTier: 'STANDARD',
      isBettingClosed: false,
    );
  }

  AirHockeyTrajectory simulateRound({
    required int roundId,
    required List<WatertightPolygon> territories,
    required double durationMs,
  }) {
    final serverSeed = _serverSeeds[roundId];
    if (serverSeed == null) {
      throw StateError('No server seed is available for round $roundId.');
    }

    return TerritoryPhysicsService.simulateAirHockeyFlight(
      seed: TerritoryPhysicsService.deriveRoundSeed(serverSeed, roundId),
      territories: territories,
      durationMs: durationMs,
    );
  }

  String revealServerSeed(int roundId) {
    final serverSeed = _serverSeeds[roundId];
    if (serverSeed == null) {
      throw StateError('No server seed is available for round $roundId.');
    }
    return serverSeed;
  }

  /// Deducts bet from user balance
  bool debitUserBalance(String currency, double amount) {
    if (currency == 'ton') {
      return WalletRepository().debitTon(amount, 'Area PVP Bet');
    } else {
      return WalletRepository().debitStars(amount.toInt(), 'Area PVP Bet');
    }
  }

  /// Credits payout to user balance
  void creditUserPayout(double ton, int stars) {
    if (ton > 0) {
      WalletRepository().creditTon(ton, 'Area PVP Payout');
    }
    if (stars > 0) {
      WalletRepository().creditStars(stars, 'Area PVP Payout');
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
