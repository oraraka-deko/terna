import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../models/tower_game/tower_game_models.dart';

class TowerGameRepository {
  double tonBalance = 10.0; // Placeholder demo balance
  int starsBalance = 100; // Placeholder demo balance

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
      tonBalance = max(0.0, tonBalance - amount);
    } else {
      starsBalance = max(0, starsBalance - amount.toInt());
    }
  }

  void creditBalance(TowerCurrency currency, double amount) {
    if (currency == TowerCurrency.ton) {
      tonBalance += amount;
    } else {
      starsBalance += amount.toInt();
    }
  }
}

