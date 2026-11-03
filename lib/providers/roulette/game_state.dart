library;

import 'package:flutter/material.dart';
import 'package:terna/models/roulette/odds.dart';
import 'package:terna/services/api/gateway_api_service.dart';
import 'package:terna/services/wallet/wallet_repository.dart';

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

class RouletteGameState extends ChangeNotifier {
  int _selectedChip = 25;
  bool _isSpinning = false;
  String? _statusMessage;

  final Map<String, Bet> _placedBets = {};
  final Map<String, Bet> _lastRoundBets = {};
  final List<SpinResult> _spinHistory = [];
  final List<String> _betHistoryStack = []; // for undo
  final WalletRepository _wallet = WalletRepository();
  int _nextNonce = 1;
  String? _pendingRoundId;

  RouletteGameState() {
    _wallet.starsBalance.addListener(_onWalletChanged);
    _wallet.tonBalance.addListener(_onWalletChanged);
  }

  @override
  void dispose() {
    _wallet.starsBalance.removeListener(_onWalletChanged);
    _wallet.tonBalance.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() => notifyListeners();

  int get balance => _wallet.starsBalance.value;
  double get tonBalance => _wallet.tonBalance.value;
  int get selectedChip => _selectedChip;
  bool get isSpinning => _isSpinning;
  String? get statusMessage => _statusMessage;
  Map<String, Bet> get placedBets => Map.unmodifiable(_placedBets);
  List<SpinResult> get spinHistory => List.unmodifiable(_spinHistory);

  int get totalBetAmount =>
      _placedBets.values.fold(0, (sum, bet) => sum + bet.amount);

  int get totalLastRoundAmount =>
      _lastRoundBets.values.fold(0, (sum, bet) => sum + bet.amount);

  bool get isGameOver => balance == 0 && _placedBets.isEmpty;

  bool get canSpin => _placedBets.isNotEmpty && !_isSpinning;

  bool get canRebet =>
      _lastRoundBets.isNotEmpty &&
      !_isSpinning &&
      balance >= totalLastRoundAmount;

  bool get canDouble =>
      _placedBets.isNotEmpty && !_isSpinning && balance >= totalBetAmount;

  void selectChip(int chip) {
    if (_isSpinning || _pendingRoundId != null) return;
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
    if (_isSpinning || _pendingRoundId != null) return false;

    if (balance < totalBetAmount + _selectedChip) {
      _statusMessage = 'Insufficient balance for ★$selectedChip Stars chip!';
      notifyListeners();
      return false;
    }

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
    if (_isSpinning || _pendingRoundId != null || _betHistoryStack.isEmpty) {
      return;
    }

    final betId = _betHistoryStack.removeLast();
    if (!_placedBets.containsKey(betId)) return;

    final existing = _placedBets[betId]!;
    final refund = existing.amount < _selectedChip
        ? existing.amount
        : _selectedChip;

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
    if (_isSpinning || _pendingRoundId != null || _placedBets.isEmpty) return;

    _placedBets.clear();
    _betHistoryStack.clear();
    _statusMessage = 'Bets cleared';
    notifyListeners();
  }

  void doubleBets() {
    if (_isSpinning || _pendingRoundId != null || !canDouble) return;

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
    if (_isSpinning || _pendingRoundId != null || !canRebet) return;

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

    _statusMessage = 'Replaced last round bets!';
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestSpin() async {
    if (_placedBets.isEmpty || !_isSpinning) {
      throw StateError('Place a bet before spinning.');
    }
    _pendingRoundId ??=
        'roulette_${DateTime.now().microsecondsSinceEpoch}_$_nextNonce';
    final response = await GatewayApiService().spinRoulette(
      roundId: _pendingRoundId!,
      clientSeed: 'roulette_client',
      nonce: _nextNonce,
      bets: _placedBets.values
          .map(
            (bet) => {
              'id': bet.id,
              'type': bet.type.name,
              'targets': bet.targetPockets.toList(),
              'amount': bet.amount,
            },
          )
          .toList(),
    );
    if (response['success'] != true ||
        response['winningPocket'] is! String ||
        response['payout'] is! num) {
      throw StateError(
        response['error']?.toString() ??
            'The backend did not return a valid spin result.',
      );
    }

    await _wallet.refreshBalances();
    return response;
  }

  SpinResult evaluateRound(String winningPocket, {required int serverPayout}) {
    int totalPayout = 0;
    final winningBets = <Bet>[];

    for (final bet in _placedBets.values) {
      if (bet.targetPockets.contains(winningPocket)) {
        final winAmount = bet.amount + (bet.amount * bet.payoutMultiplier);
        totalPayout += winAmount;
        winningBets.add(bet);
      }
    }

    if (totalPayout != serverPayout) {
      throw StateError('The roulette payout does not match the server result.');
    }
    final netGain = serverPayout - totalBetAmount;

    _lastRoundBets.clear();
    _lastRoundBets.addAll(_placedBets);

    final result = SpinResult(
      winningPocket: winningPocket,
      totalPayout: serverPayout,
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
    _pendingRoundId = null;
    _nextNonce++;

    if (isGameOver) {
      _statusMessage = 'GAME OVER - Out of funds!';
    } else if (netGain > 0) {
      _statusMessage = 'WINNER! +★$netGain Stars';
    } else if (netGain == 0) {
      _statusMessage = 'PUSH - Break even';
    } else {
      _statusMessage = 'NO WIN - ★$totalBetAmount';
    }

    notifyListeners();
    return result;
  }

  void cancelSpin(String message) {
    _isSpinning = false;
    _statusMessage = message;
    notifyListeners();
  }

  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }
}
