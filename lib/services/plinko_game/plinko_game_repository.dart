import 'dart:math';
import '../../models/plinko_game/plinko_models.dart';

class PlinkoGameRepository {
  /// FLAG: isPlaceholder marks simulated demo wallet balances
  static const bool isPlaceholder = true;

  double tonBalance = 10.0; // PLACEHOLDER: 10 TON demo balance
  int starsBalance = 100; // PLACEHOLDER: 100 Stars demo balance

  static const int rows = 12; // 12 tiers = 13 landing buckets
  static const int bucketCount = 13;

  /// Generate deterministic binary path (0 = left, 1 = right) for 12 peg tiers
  List<int> generatePath() {
    final random = Random();
    return List.generate(rows, (_) => random.nextBool() ? 1 : 0);
  }

  /// Deduct bet from balance
  void deductBalance(PlinkoCurrency currency, double amount) {
    if (currency == PlinkoCurrency.ton) {
      tonBalance = max(0.0, double.parse((tonBalance - amount).toStringAsFixed(4)));
    } else {
      starsBalance = max(0, starsBalance - amount.toInt());
    }
  }

  /// Credit payout to balance
  void creditBalance(PlinkoCurrency currency, double payout) {
    if (currency == PlinkoCurrency.ton) {
      tonBalance = double.parse((tonBalance + payout).toStringAsFixed(4));
    } else {
      starsBalance = starsBalance + payout.toInt();
    }
  }
}

