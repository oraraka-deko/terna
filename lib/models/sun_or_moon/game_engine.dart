import 'dart:math';
import 'package:flutter/foundation.dart';
import 'coin_side.dart';
import 'game_history_entry.dart';

class GameEngine extends ChangeNotifier {
  static const int defaultStartingBalance = 100;

  int _playerBalance = defaultStartingBalance;
  int _systemLockedVault = 0;
  int _currentBet = 20;
  CoinSide _selectedSide = CoinSide.sun;
  CoinSide? _lastOutcome;
  bool? _lastGameWon;
  int _winStreak = 0;
  int _bestStreak = 0;
  int _highestBalance = defaultStartingBalance;
  int _totalGamesPlayed = 0;
  int _totalWins = 0;
  int _totalLosses = 0;
  bool _isFlipping = false;

  final List<GameHistoryEntry> _history = [];
  final Random _random;

  GameEngine({Random? random}) : _random = random ?? Random();

  // Getters
  int get playerBalance => _playerBalance;
  int get systemLockedVault => _systemLockedVault;
  int get currentBet => _currentBet;
  CoinSide get selectedSide => _selectedSide;
  CoinSide? get lastOutcome => _lastOutcome;
  bool? get lastGameWon => _lastGameWon;
  int get winStreak => _winStreak;
  int get bestStreak => _bestStreak;
  int get highestBalance => _highestBalance;
  int get totalGamesPlayed => _totalGamesPlayed;
  int get totalWins => _totalWins;
  int get totalLosses => _totalLosses;
  bool get isFlipping => _isFlipping;
  bool get isBankrupt => _playerBalance <= 0;
  List<GameHistoryEntry> get history => List.unmodifiable(_history);

  double get winRate =>
      _totalGamesPlayed == 0 ? 0.0 : (_totalWins / _totalGamesPlayed) * 100;

  void setSelectedSide(CoinSide side) {
    if (_isFlipping) return;
    _selectedSide = side;
    notifyListeners();
  }

  void setBet(int amount) {
    if (_isFlipping) return;
    if (_playerBalance <= 0) {
      _currentBet = 0;
    } else {
      _currentBet = amount.clamp(1, _playerBalance);
    }
    notifyListeners();
  }

  void setQuickBetRatio(double ratio) {
    if (_isFlipping || _playerBalance <= 0) return;
    final calculated = (_playerBalance * ratio).round();
    setBet(calculated.clamp(1, _playerBalance));
  }

  void setAllIn() {
    setBet(_playerBalance);
  }

  void startFlipping() {
    _isFlipping = true;
    notifyListeners();
  }

  /// Resolves the flip with a given outcome or generates a random outcome
  CoinSide resolveFlip({CoinSide? forcedOutcome}) {
    final outcome = forcedOutcome ??
        (_random.nextBool() ? CoinSide.sun : CoinSide.moon);

    final won = outcome == _selectedSide;
    final bet = _currentBet;

    _totalGamesPlayed++;
    _lastOutcome = outcome;
    _lastGameWon = won;

    int netChange;
    if (won) {
      // Player wins 2x the bet (net profit is +bet)
      netChange = bet;
      _playerBalance += bet;
      _totalWins++;
      _winStreak++;
      if (_winStreak > _bestStreak) {
        _bestStreak = _winStreak;
      }
      if (_playerBalance > _highestBalance) {
        _highestBalance = _playerBalance;
      }
    } else {
      // Player loses bet, which is locked into the System Vault
      netChange = -bet;
      _playerBalance -= bet;
      _systemLockedVault += bet;
      _totalLosses++;
      _winStreak = 0;
    }

    _history.insert(
      0,
      GameHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        playerChoice: _selectedSide,
        systemOutcome: outcome,
        betAmount: bet,
        won: won,
        netChange: netChange,
        balanceAfter: _playerBalance,
        timestamp: DateTime.now(),
      ),
    );

    // Auto-adjust current bet if it exceeds new balance
    if (_playerBalance > 0 && _currentBet > _playerBalance) {
      _currentBet = _playerBalance;
    } else if (_playerBalance <= 0) {
      _currentBet = 0;
    }

    _isFlipping = false;
    notifyListeners();

    return outcome;
  }

  void claimBankruptcyRestart() {
    if (_playerBalance <= 0) {
      _playerBalance = defaultStartingBalance;
      _currentBet = 20;
      _winStreak = 0;
      _lastGameWon = null;
      _lastOutcome = null;
      notifyListeners();
    }
  }

  void resetFullGame() {
    _playerBalance = defaultStartingBalance;
    _systemLockedVault = 0;
    _currentBet = 20;
    _selectedSide = CoinSide.sun;
    _lastOutcome = null;
    _lastGameWon = null;
    _winStreak = 0;
    _bestStreak = 0;
    _highestBalance = defaultStartingBalance;
    _totalGamesPlayed = 0;
    _totalWins = 0;
    _totalLosses = 0;
    _isFlipping = false;
    _history.clear();
    notifyListeners();
  }
}
