
import 'package:flutter/material.dart';
import 'package:terna/models/roulette/odds.dart';


class RouletteGameState extends ChangeNotifier {
  static const int defaultInitialBalance = 1000;
  
  int _balance = defaultInitialBalance;
  int _selectedChip = 25;
  bool _isSpinning = false;
  String? _statusMessage;
  
  final Map<String, Bet> _placedBets = {};
  final Map<String, Bet> _lastRoundBets = {};
  final List<SpinResult> _spinHistory = [];
  final List<String> _betHistoryStack = []; // for undo

  int get balance => _balance;
  int get selectedChip => _selectedChip;
  bool get isSpinning => _isSpinning;
  String? get statusMessage => _statusMessage;
  Map<String, Bet> get placedBets => Map.unmodifiable(_placedBets);
  List<SpinResult> get spinHistory => List.unmodifiable(_spinHistory);

  int get totalBetAmount =>
      _placedBets.values.fold(0, (sum, bet) => sum + bet.amount);

  int get totalLastRoundAmount =>
      _lastRoundBets.values.fold(0, (sum, bet) => sum + bet.amount);

  bool get isGameOver => _balance == 0 && _placedBets.isEmpty;

  bool get canSpin => _placedBets.isNotEmpty && !_isSpinning;

  bool get canRebet =>
      _lastRoundBets.isNotEmpty &&
      !_isSpinning &&
      _balance >= totalLastRoundAmount;

  bool get canDouble =>
      _placedBets.isNotEmpty &&
      !_isSpinning &&
      _balance >= totalBetAmount;

  void selectChip(int chip) {
    if (_isSpinning) return;
    _selectedChip = chip;
    _statusMessage = null;
    notifyListeners();
  }

  void setSpinning(bool spinning) {
    _isSpinning = spinning;
    if (spinning) _statusMessage = null;
    notifyListeners();
  }

  bool placeBet({
    required String betId,
    required BetType type,
    required Set<String> targets,
  }) {
    if (_isSpinning) return false;

    if (_balance < _selectedChip) {
      _statusMessage = 'Insufficient balance for \$$selectedChip chip!';
      notifyListeners();
      return false;
    }

    _balance -= _selectedChip;
    _statusMessage = null;

    if (_placedBets.containsKey(betId)) {
      final existing = _placedBets[betId]!;
      _placedBets[betId] = Bet(
        id: betId,
        type: type,
        targetPockets: targets,
        amount: existing.amount + _selectedChip,
      );
    } else {
      _placedBets[betId] = Bet(
        id: betId,
        type: type,
        targetPockets: targets,
        amount: _selectedChip,
      );
    }

    _betHistoryStack.add(betId);
    notifyListeners();
    return true;
  }

  void undoLastBet() {
    if (_isSpinning || _betHistoryStack.isEmpty) return;

    final betId = _betHistoryStack.removeLast();
    if (!_placedBets.containsKey(betId)) return;

    final existing = _placedBets[betId]!;
    final refund = existing.amount < _selectedChip ? existing.amount : _selectedChip;

    _balance += refund;

    if (existing.amount <= refund) {
      _placedBets.remove(betId);
    } else {
      _placedBets[betId] = Bet(
        id: betId,
        type: existing.type,
        targetPockets: existing.targetPockets,
        amount: existing.amount - refund,
      );
    }

    _statusMessage = 'Undid bet on $betId';
    notifyListeners();
  }

  void clearBets() {
    if (_isSpinning || _placedBets.isEmpty) return;
    _balance += totalBetAmount;
    _placedBets.clear();
    _betHistoryStack.clear();
    _statusMessage = 'Bets cleared';
    notifyListeners();
  }

  void doubleBets() {
    if (_isSpinning || !canDouble) return;

    final needed = totalBetAmount;
    _balance -= needed;

    _placedBets.forEach((key, bet) {
      _placedBets[key] = Bet(
        id: bet.id,
        type: bet.type,
        targetPockets: bet.targetPockets,
        amount: bet.amount * 2,
      );
    });

    _statusMessage = 'Bets doubled!';
    notifyListeners();
  }

  void rebet() {
    if (_isSpinning || !canRebet) return;

    // Refund current placed bets if any
    _balance += totalBetAmount;
    _placedBets.clear();
    _betHistoryStack.clear();

    _lastRoundBets.forEach((key, bet) {
      _placedBets[key] = Bet(
        id: bet.id,
        type: bet.type,
        targetPockets: bet.targetPockets,
        amount: bet.amount,
      );
    });

    _balance -= totalLastRoundAmount;
    _statusMessage = 'Replaced last round bets!';
    notifyListeners();
  }

  SpinResult evaluateRound(String winningPocket) {
    int totalPayout = 0;
    final winningBets = <Bet>[];

    for (final bet in _placedBets.values) {
      if (bet.targetPockets.contains(winningPocket)) {
        // Payout = original bet returned + (bet * multiplier)
        final winAmount = bet.amount + (bet.amount * bet.payoutMultiplier);
        totalPayout += winAmount;
        winningBets.add(bet);
      }
    }

    final netGain = totalPayout - totalBetAmount;
    _balance += totalPayout;

    // Save for rebet
    _lastRoundBets.clear();
    _lastRoundBets.addAll(_placedBets);

    final result = SpinResult(
      winningPocket: winningPocket,
      totalPayout: totalPayout,
      netGain: netGain,
      winningBets: winningBets,
      timestamp: DateTime.now(),
    );

    _spinHistory.insert(0, result);
    if (_spinHistory.length > 10) {
      _spinHistory.removeLast();
    }

    _placedBets.clear();
    _betHistoryStack.clear();
    _isSpinning = false;

    if (isGameOver) {
      _statusMessage = 'GAME OVER - Out of funds!';
    } else if (netGain > 0) {
      _statusMessage = 'WINNER! +\$$netGain';
    } else if (netGain == 0) {
      _statusMessage = 'PUSH - Break even';
    } else {
      _statusMessage = 'NO WIN - \$$totalBetAmount';
    }

    notifyListeners();
    return result;
  }

  void refillDemoMoney() {
    _balance = defaultInitialBalance;
    _placedBets.clear();
    _betHistoryStack.clear();
    _statusMessage = 'Refilled \$$defaultInitialBalance demo money!';
    notifyListeners();
  }

  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }
}

class SpinResult {
  final String winningPocket;
  final int totalPayout;
  final int netGain;
  final List<Bet> winningBets;
  final DateTime timestamp;

  const SpinResult({
    required this.winningPocket,
    required this.totalPayout,
    required this.netGain,
    required this.winningBets,
    required this.timestamp,
  });
}