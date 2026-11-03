library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../models/tower_game/tower_game_models.dart';
import '../wallet/wallet_repository.dart';

class TowerGameRepository {
  double get tonBalance => WalletRepository().tonBalance.value;
  int get starsBalance => WalletRepository().starsBalance.value;

  static const int rows = 7;
  static const int cols = 5;

  /// Generate a 7x5 grid with traps according to difficulty.
  /// Row 0 is Level 1 (bottom), Row 6 is Level 7 (top).
  List<List<TowerTileStatus>> generateGrid(TowerDifficulty difficulty) {
    final random = Random();
    final trapCount = difficulty.trapCount;

    final grid = <List<TowerTileStatus>>[];

    for (var r = 0; r < rows; r++) {
      final row = List<TowerTileStatus>.filled(cols, TowerTileStatus.safe);

      // Pick unique trap columns
      final trapIndices = <int>{};
      while (trapIndices.length < trapCount) {
        trapIndices.add(random.nextInt(cols));
      }

      for (final trapCol in trapIndices) {
        row[trapCol] = TowerTileStatus.trap;
      }

      grid.add(row);
    }

    return grid;
  }

  /// Generate SHA-256 Provably Fair seed hash
  String generateSeedHash(String seed) {
    final bytes = utf8.encode(seed);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void deductBalance(TowerCurrency currency, double amount) {
    if (currency == TowerCurrency.ton) {
      WalletRepository().debitTon(amount, 'Tower Climb Bet');
    } else {
      WalletRepository().debitStars(amount.toInt(), 'Tower Climb Bet');
    }
  }

  void creditBalance(TowerCurrency currency, double amount) {
    if (currency == TowerCurrency.ton) {
      WalletRepository().creditTon(amount, 'Tower Climb Payout');
    } else {
      WalletRepository().creditStars(amount.toInt(), 'Tower Climb Payout');
    }
  }
}
