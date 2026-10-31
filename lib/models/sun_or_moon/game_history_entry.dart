import 'coin_side.dart';

class GameHistoryEntry {
  final String id;
  final CoinSide playerChoice;
  final CoinSide systemOutcome;
  final int betAmount;
  final bool won;
  final int netChange;
  final int balanceAfter;
  final DateTime timestamp;

  GameHistoryEntry({
    required this.id,
    required this.playerChoice,
    required this.systemOutcome,
    required this.betAmount,
    required this.won,
    required this.netChange,
    required this.balanceAfter,
    required this.timestamp,
  });
}
