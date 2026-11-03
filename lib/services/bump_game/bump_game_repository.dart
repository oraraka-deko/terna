import 'package:terna/services/wallet/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';

/// Repository managing Arena Bump state, mock user wallet balances, and game history
class BumpGameRepository {
  double get userTonBalance => WalletRepository().tonBalance.value;
  int get userStarsBalance => WalletRepository().starsBalance.value;

  final List<BumpRoundHistory> _historyRecords = [];
  List<BumpRoundHistory> get historyRecords => List.unmodifiable(_historyRecords);

  BumpGameRepository() {
    _initDemoHistory();
  }

  void _initDemoHistory() {
    // PLACEHOLDER: Initial historical round for video playback testing
    final demoWinner = BumpPlayerBall(
      id: 'npc_7660412004',
      username: '@amsexyledy',
      firstName: '#святая',
      avatar: 'assets/npc/avatars/7660412004.jpg',
      color: const Color(0xFF2DD4BF),
      betAmount: 1.5,
      currency: 'ton',
      isPlaceholder: true,
    );

    final demoParticipants = [
      demoWinner,
      BumpPlayerBall(
        id: 'npc_1965297855',
        username: '@Jevga22',
        avatar: 'assets/npc/avatars/1965297855.jpg',
        color: const Color(0xFF6366F1),
        betAmount: 1.0,
        currency: 'ton',
        isPlaceholder: true,
      ),
      BumpPlayerBall(
        id: 'system_core',
        username: 'Arena Core',
        avatar: '',
        color: const Color(0xFFF97316),
        isSystemBot: true,
        betAmount: 0.2,
        currency: 'ton',
        isPlaceholder: true,
      ),
    ];

    _historyRecords.add(BumpRoundHistory(
      roundId: 20491,
      winner: demoWinner,
      participants: demoParticipants,
      totalPotTon: 2.7,
      totalPotStars: 0,
      serverSeedHash: '8f4c3a21b0e954d3c2a1b98f4e3d2c1a0b9876543210fedcba9876543210abcd',
      revealedServerSeed: 'arena_bump_round_20491_proven_fair_seed',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isPlaceholder: true,
    ));
  }

  /// Deducts bet from user balance
  bool debitUserBalance(String currency, double amount) {
    if (currency == 'ton') {
      return WalletRepository().debitTon(amount, 'Bump Arena Bet');
    } else {
      return WalletRepository().debitStars(amount.toInt(), 'Bump Arena Bet');
    }
  }

  /// Credits payout to user balance
  void creditUserPayout(double ton, int stars) {
    if (ton > 0) {
      WalletRepository().creditTon(ton, 'Bump Arena Win');
    }
    if (stars > 0) {
      WalletRepository().creditStars(stars, 'Bump Arena Win');
    }
  }

  /// Archives completed round to history
  void archiveRound(BumpRoundHistory record) {
    _historyRecords.insert(0, record);
    if (_historyRecords.length > 50) {
      _historyRecords.removeLast();
    }
  }
}

