library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../services/api/gateway_api_service.dart';
import '../../services/wallet/wallet_repository.dart';
import 'coin_side.dart';
import 'game_history_entry.dart';

class GameEngine extends ChangeNotifier {
  int _playerBalance = 0;
  int _systemLockedVault = 0;
  int _currentBet = 20;
  CoinSide _selectedSide = CoinSide.sun;
  CoinSide? _lastOutcome;
  bool? _lastGameWon;
  int _winStreak = 0;
  int _bestStreak = 0;
  int _highestBalance = 0;
  int _totalGamesPlayed = 0;
  int _totalWins = 0;
  int _totalLosses = 0;
  bool _isFlipping = false;
  int _nextNonce = 1;
  String? _pendingRoundId;
  int? _pendingBetAmount;
  CoinSide? _pendingSelectedSide;

  final List<GameHistoryEntry> _history = [];
  final Random _random;
  final WalletRepository _wallet = WalletRepository();

  GameEngine({Random? random}) : _random = random ?? Random() {
    _playerBalance = _wallet.starsBalance.value;
    _highestBalance = _playerBalance;
    _currentBet = _playerBalance.clamp(0, 20);
    _wallet.starsBalance.addListener(_onWalletChanged);
    _wallet.tonBalance.addListener(_onWalletChanged);
  }

  @override
  void dispose() {
    _wallet.starsBalance.removeListener(_onWalletChanged);
    _wallet.tonBalance.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    _playerBalance = _wallet.starsBalance.value;
    if (_playerBalance == 0) {
      _currentBet = 0;
    } else if (_currentBet == 0) {
      _currentBet = _playerBalance.clamp(1, 20);
    } else if (_currentBet > _playerBalance) {
      _currentBet = _playerBalance;
    }
    notifyListeners();
  }

  // Getters
  int get playerBalance => _playerBalance;
  double get tonBalance => _wallet.tonBalance.value;
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
    if (_isFlipping || _pendingRoundId != null) return;
    _selectedSide = side;
    notifyListeners();
  }

  void selectSide(CoinSide side) => setSelectedSide(side);

  void setBet(int amount) {
    if (_isFlipping || _pendingRoundId != null) return;
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

  void setBetRatio(double ratio) => setQuickBetRatio(ratio);

  void setAllIn() {
    setBet(_playerBalance);
  }

  void setMaxBet() => setAllIn();

  void startFlipping() {
    if (_isFlipping || _playerBalance <= 0 || _currentBet <= 0) return;
    if (_pendingRoundId == null) {
      _pendingRoundId =
          'sun_moon_${DateTime.now().microsecondsSinceEpoch}_$_nextNonce';
      _pendingBetAmount = _currentBet;
      _pendingSelectedSide = _selectedSide;
      _nextNonce++;
    }
    _isFlipping = true;
    notifyListeners();
  }

  Future<CoinSide> requestFlip() async {
    if (!_isFlipping ||
        _pendingRoundId == null ||
        _pendingBetAmount == null ||
        _pendingSelectedSide == null) {
      throw StateError('Start a coin flip before requesting its result.');
    }

    final response = await GatewayApiService().flipSunOrMoon(
      roundId: _pendingRoundId!,
      betAmount: _pendingBetAmount!,
      selectedSide: _pendingSelectedSide!.name,
      clientSeed: 'sun_moon_client',
      nonce: _nextNonce - 1,
    );
    final outcomeName = response['outcome'];
    if (response['success'] != true ||
        outcomeName is! String ||
        !CoinSide.values.any((side) => side.name == outcomeName)) {
      throw StateError(
        response['error']?.toString() ??
            'The backend returned an invalid coin result.',
      );
    }

    await _wallet.refreshBalances();
    return CoinSide.values.firstWhere((side) => side.name == outcomeName);
  }

  void cancelFlip() {
    _isFlipping = false;
    notifyListeners();
  }

  CoinSide resolveFlip({CoinSide? forcedOutcome, int? settledBet}) {
    final outcome =
        forcedOutcome ?? (_random.nextBool() ? CoinSide.sun : CoinSide.moon);

    final won = outcome == _selectedSide;
    final bet = settledBet ?? _currentBet;

    _totalGamesPlayed++;
    _lastOutcome = outcome;
    _lastGameWon = won;

    int netChange;
    if (won) {
      // Player wins 2x the bet (net profit is +bet)
      netChange = bet;
      _totalWins++;
      _winStreak++;
      if (_winStreak > _bestStreak) {
        _bestStreak = _winStreak;
      }
      if (_playerBalance > _highestBalance) {
        _highestBalance = _playerBalance;
      }
    } else {
      // The server settles the wager; this counter is only a game statistic.
      netChange = -bet;
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
    _pendingRoundId = null;
    _pendingBetAmount = null;
    _pendingSelectedSide = null;
    notifyListeners();

    return outcome;
  }

  void resetFullGame() {
    if (_pendingRoundId != null) return;
    _systemLockedVault = 0;
    _playerBalance = _wallet.starsBalance.value;
    _currentBet = _playerBalance.clamp(0, 20);
    _selectedSide = CoinSide.sun;
    _lastOutcome = null;
    _lastGameWon = null;
    _winStreak = 0;
    _bestStreak = 0;
    _highestBalance = _playerBalance;
    _totalGamesPlayed = 0;
    _totalWins = 0;
    _totalLosses = 0;
    _isFlipping = false;
    _history.clear();
    notifyListeners();
  }

  void resetGame() => resetFullGame();
}
