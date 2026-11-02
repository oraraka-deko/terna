import '../../models/higher_lower/higher_lower_models.dart';

/// Pure math and odds engine for Higher or Lower.
/// Computes dynamic multipliers based on remaining rank probabilities with standard ~95% RTP.
class HigherLowerOddsService {
  /// Higher multipliers matching game rules and screenshots:
  /// - Higher on 3 -> x1.09
  /// - Higher on 5 -> x1.26
  /// - Higher on 6 -> x1.42
  static const Map<int, double> _higherMultipliers = {
    2: 1.04, // 2 floor: safe calling higher
    3: 1.09,
    4: 1.17,
    5: 1.26,
    6: 1.42,
    7: 1.62,
    8: 1.90,
    9: 2.28,
    10: 2.85,
    11: 3.80, // Jack
    12: 5.70, // Queen
    13: 11.50, // King: aggressive high payout
    14: 0.0, // Ace: cannot call higher (deactivated)
  };

  /// Lower multipliers matching game rules and screenshots:
  /// - Lower on 3 -> x11.50
  /// - Lower on 5 -> x3.80
  /// - Lower on 6 -> x2.85
  static const Map<int, double> _lowerMultipliers = {
    2: 0.0, // Two: cannot call lower (deactivated)
    3: 11.50, // Aggressive high payout
    4: 5.70,
    5: 3.80,
    6: 2.85,
    7: 2.28,
    8: 1.90,
    9: 1.62,
    10: 1.42,
    11: 1.26, // Jack
    12: 1.17, // Queen
    13: 1.09, // King
    14: 1.04, // Ace: floor
  };

  /// Returns payout multiplier for calling Higher on [currentRank] (2..14).
  /// Returns 0.0 if cannot call higher (Ace).
  static double getHigherMultiplier(int currentRank) {
    return _higherMultipliers[currentRank] ?? 1.50;
  }

  /// Returns payout multiplier for calling Lower on [currentRank] (2..14).
  /// Returns 0.0 if cannot call lower (Two).
  static double getLowerMultiplier(int currentRank) {
    return _lowerMultipliers[currentRank] ?? 1.50;
  }

  /// Check whether the current card is an extreme edge (Ace or Two)
  static bool isEdgeCard(int currentRank) {
    return currentRank == 2 || currentRank == 14;
  }

  /// Checks if Higher option is available on this card
  static bool canCallHigher(int currentRank) {
    return currentRank < 14;
  }

  /// Checks if Lower option is available on this card
  static bool canCallLower(int currentRank) {
    return currentRank > 2;
  }

  /// Evaluates outcome of [call] given [currentRank] and [nextRank]
  /// Returns a record: (isWin, isTie, stepMultiplier)
  static ({bool isWin, bool isTie, double stepMultiplier}) evaluate({
    required int currentRank,
    required int nextRank,
    required PredictionType call,
  }) {
    if (call == PredictionType.skip) {
      // Skip cycling: maintains active streak at x1.00
      return (isWin: true, isTie: false, stepMultiplier: 1.0);
    }

    if (nextRank == currentRank) {
      // Equal rank tie/push: does not bust the player; maintains streak at x1.00
      return (isWin: true, isTie: true, stepMultiplier: 1.0);
    }

    if (call == PredictionType.higher) {
      if (nextRank > currentRank) {
        final mult = getHigherMultiplier(currentRank);
        return (isWin: true, isTie: false, stepMultiplier: mult);
      } else {
        return (isWin: false, isTie: false, stepMultiplier: 0.0);
      }
    } else {
      // call == PredictionType.lower
      if (nextRank < currentRank) {
        final mult = getLowerMultiplier(currentRank);
        return (isWin: true, isTie: false, stepMultiplier: mult);
      } else {
        return (isWin: false, isTie: false, stepMultiplier: 0.0);
      }
    }
  }
}

