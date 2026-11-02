/// Suits for standard 52-card deck
enum CardSuit {
  spades, // Pikes
  hearts, // Hearts
  diamonds, // Tiles
  clubs, // Clovers
}

/// Betting currency for Higher or Lower
enum HigherLowerCurrency {
  stars,
  ton,
}

/// Prediction call type
enum PredictionType {
  higher,
  lower,
  skip,
}

/// Round state lifecycle
enum HigherLowerRoundState {
  idle, // Waiting for player to set bet and press Start
  playing, // Active round, waiting for user prediction
  correct, // User guessed correctly, can continue or collect
  wrong, // User guessed wrong, game over (Play again)
  collected, // User cashed out win
}

/// Playing card domain model
class PlayingCard {
  final CardSuit suit;

  /// Rank value from 2 (lowest) to 14 (Ace, highest)
  final int rankValue;

  const PlayingCard({
    required this.suit,
    required this.rankValue,
  });

  String get rankLabel {
    switch (rankValue) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      default:
        return rankValue.toString();
    }
  }

  String get suitSymbol {
    switch (suit) {
      case CardSuit.spades:
        return '♠';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
    }
  }

  bool get isRed => suit == CardSuit.hearts || suit == CardSuit.diamonds;

  /// Path to white deck card PNG asset in assets/cards/white/
  String get assetPathWhite {
    final rankCode = switch (rankValue) {
      14 => 'A',
      13 => 'King',
      12 => 'Queen',
      11 => 'Jack',
      _ => rankValue.toString(),
    };

    switch (suit) {
      case CardSuit.clubs:
        return 'assets/cards/white/Clovers_${rankCode}_white.png';
      case CardSuit.hearts:
        // Notice typo in asset file name: Heats_6_white.png
        if (rankValue == 6) {
          return 'assets/cards/white/Heats_6_white.png';
        }
        return 'assets/cards/white/Hearts_${rankCode}_white.png';
      case CardSuit.spades:
        return 'assets/cards/white/Pikes_${rankCode}_white.png';
      case CardSuit.diamonds:
        return 'assets/cards/white/Tiles_${rankCode}_white.png';
    }
  }

  /// Path to black deck card PNG asset in assets/cards/black/
  String get assetPathBlack {
    final rankCode = switch (rankValue) {
      14 => 'A',
      13 => 'King',
      12 => 'Queen',
      11 => 'Jack',
      _ => rankValue.toString(),
    };

    switch (suit) {
      case CardSuit.clubs:
        return 'assets/cards/black/Clovers_${rankCode}_black.png';
      case CardSuit.hearts:
        return 'assets/cards/black/Hearts_${rankCode}_black.png';
      case CardSuit.spades:
        return 'assets/cards/black/Pikes_${rankCode}_black.png';
      case CardSuit.diamonds:
        return 'assets/cards/black/Tiles_${rankCode}_black.png';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rankValue == other.rankValue;

  @override
  int get hashCode => suit.hashCode ^ rankValue.hashCode;

  @override
  String toString() => '$rankLabel$suitSymbol';
}

/// History record of a single draw in a round
class HigherLowerStepRecord {
  final PlayingCard previousCard;
  final PlayingCard drawnCard;
  final PredictionType call;
  final double stepMultiplier;
  final double cumulativeMultiplier;
  final bool isWin;
  final bool isTie;

  const HigherLowerStepRecord({
    required this.previousCard,
    required this.drawnCard,
    required this.call,
    required this.stepMultiplier,
    required this.cumulativeMultiplier,
    required this.isWin,
    this.isTie = false,
  });
}

/// Complete record of a finished round for the history dialog
class HigherLowerRoundHistory {
  final String roundId;
  final DateTime timestamp;
  final double betAmount;
  final HigherLowerCurrency currency;
  final double finalMultiplier;
  final double payoutAmount;
  final int totalWins;
  final bool isCashOut;
  final List<PlayingCard> cardHistory;
  final bool isPlaceholder;

  const HigherLowerRoundHistory({
    required this.roundId,
    required this.timestamp,
    required this.betAmount,
    required this.currency,
    required this.finalMultiplier,
    required this.payoutAmount,
    required this.totalWins,
    required this.isCashOut,
    required this.cardHistory,
    this.isPlaceholder = true, // PLACEHOLDER: demo history record
  });
}

