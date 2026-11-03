import 'dart:math';
import 'package:flutter/material.dart';
import 'package:terna/models/tower_game/tower_game_models.dart';
import 'package:terna/services/haptic.dart';
import 'package:terna/services/tower_game/tower_audio_service.dart';
import 'package:terna/services/tower_game/tower_game_repository.dart';
import 'package:terna/services/api/gateway_api_service.dart';

class TowerGameViewModel extends ChangeNotifier {
  final TowerGameRepository repository;

  TowerGameViewModel({required this.repository}) {
    _resetBoard();
  }

  // Settings & Toggles
  TowerDifficulty difficulty = TowerDifficulty.medium;
  TowerCurrency currency = TowerCurrency.ton;
  double betAmount = 0.2;

  // Active game state
  bool isPlaying = false;
  bool isProcessing = false;
  int currentRow = 0; // 0 (bottom) to 6 (top)
  double currentMultiplier = 1.0;
  String? serverSeedHash;
  String? _backendRoundId;

  // Visual board: 7 rows x 5 columns
  late List<List<TowerTileState>> board;

  // Secret underlying grid (hidden during active run)
  List<List<TowerTileStatus>> _secretGrid = [];

  // Outcome banner state
  TowerOutcome? lastOutcome;

  double get tonBalance => repository.tonBalance;
  int get starsBalance => repository.starsBalance;

  double get cashoutValue {
    if (currency == TowerCurrency.ton) {
      return double.parse((betAmount * currentMultiplier).toStringAsFixed(2));
    } else {
      return (betAmount * currentMultiplier).roundToDouble();
    }
  }

  void _resetBoard() {
    board = List.generate(
      TowerGameRepository.rows,
      (_) => List.generate(
        TowerGameRepository.cols,
        (_) => const TowerTileState(status: TowerTileStatus.hidden),
      ),
    );
  }

  // --- Setting Actions ---

  void setDifficulty(TowerDifficulty newDiff) {
    if (isPlaying) return;
    difficulty = newDiff;
    HapticFeedbackService.tap();
    TowerAudioService.playClick();
    notifyListeners();
  }

  void setCurrency(TowerCurrency newCurr) {
    if (isPlaying) return;
    currency = newCurr;
    if (currency == TowerCurrency.stars && betAmount < 10) {
      betAmount = 20.0;
    } else if (currency == TowerCurrency.ton && betAmount > 10) {
      betAmount = 0.2;
    }
    HapticFeedbackService.tap();
    TowerAudioService.playClick();
    notifyListeners();
  }

  void setBetAmount(double val) {
    if (isPlaying) return;
    betAmount = max(0.0, val);
    notifyListeners();
  }

  void incrementBet() {
    if (isPlaying) return;
    if (currency == TowerCurrency.ton) {
      betAmount = double.parse((betAmount + 0.1).toStringAsFixed(2));
    } else {
      betAmount = betAmount + 10;
    }
    HapticFeedbackService.tap();
    TowerAudioService.playClick();
    notifyListeners();
  }

  void decrementBet() {
    if (isPlaying) return;
    if (currency == TowerCurrency.ton) {
      betAmount = max(0.1, double.parse((betAmount - 0.1).toStringAsFixed(2)));
    } else {
      betAmount = max(10.0, betAmount - 10);
    }
    HapticFeedbackService.tap();
    TowerAudioService.playClick();
    notifyListeners();
  }

  void setQuickChip(double chip) {
    if (isPlaying) return;
    if (currency == TowerCurrency.ton) {
      betAmount = double.parse((chip / 100.0).toStringAsFixed(2));
    } else {
      betAmount = chip;
    }
    HapticFeedbackService.tap();
    TowerAudioService.playClick();
    notifyListeners();
  }

  void setMaxBet() {
    if (isPlaying) return;
    if (currency == TowerCurrency.ton) {
      betAmount = double.parse(tonBalance.toStringAsFixed(2));
    } else {
      betAmount = starsBalance.toDouble();
    }
    HapticFeedbackService.tap();
    TowerAudioService.playClick();
    notifyListeners();
  }

  // --- Core Gameplay Actions ---

  void startGame() {
    if (isPlaying || isProcessing) return;

    final currentBal = currency == TowerCurrency.ton ? tonBalance : starsBalance.toDouble();
    if (currentBal < betAmount || betAmount <= 0) {
      TowerAudioService.playBust();
      HapticFeedbackService.error();
      return;
    }

    isProcessing = true;
    lastOutcome = null;
    _resetBoard();

    // Deduct bet
    repository.deductBalance(currency, betAmount);

    // Generate secret grid
    _secretGrid = repository.generateGrid(difficulty);

    // Seed hash
    final seedString = 'tower_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
    serverSeedHash = repository.generateSeedHash(seedString);

    currentRow = 0;
    currentMultiplier = 1.0;
    isPlaying = true;
    isProcessing = false;

    _backendRoundId = null;
    GatewayApiService().startTower(
      betAmount: betAmount,
      currency: currency == TowerCurrency.ton ? 'ton' : 'stars',
      difficulty: difficulty.name.toUpperCase(),
    ).then((res) {
      if (res['success'] == true && res['roundId'] != null) {
        _backendRoundId = res['roundId'].toString();
      }
    }).catchError((_) {});

    TowerAudioService.playClick();
    HapticFeedbackService.lightImpact();
    notifyListeners();
  }

  void pickTile(int rowIndex, int colIndex) {
    if (!isPlaying || isProcessing || rowIndex != currentRow) return;

    isProcessing = true;
    HapticFeedbackService.tap();

    if (_backendRoundId != null) {
      GatewayApiService().stepTower(
        roundId: _backendRoundId!,
        rowIndex: rowIndex,
        tileIndex: colIndex,
      ).catchError((_) => <String, dynamic>{});
    }

    final isTrap = _secretGrid[rowIndex][colIndex] == TowerTileStatus.trap;

    if (isTrap) {
      // 1. Trap / Bust
      TowerAudioService.playBust();
      HapticFeedbackService.error();

      isPlaying = false;
      lastOutcome = TowerOutcome(
        won: false,
        amount: betAmount,
        currency: currency,
      );

      // Reveal full board
      _revealFullBoard(pickedRow: rowIndex, pickedCol: colIndex);
      isProcessing = false;
      notifyListeners();
    } else {
      // 2. Safe Tile Revealed
      final multipliers = difficulty.multipliers;
      currentMultiplier = multipliers[rowIndex];

      // Mark this tile safe and picked
      board[rowIndex][colIndex] = const TowerTileState(
        status: TowerTileStatus.safe,
        isPicked: true,
      );

      if (rowIndex == TowerGameRepository.rows - 1) {
        // Cleared Row 6 (Level 7) - GRAND WIN!
        TowerAudioService.playGrandWin();
        HapticFeedbackService.heavyImpact();
        HapticFeedbackService.success();

        final payout = cashoutValue;
        repository.creditBalance(currency, payout);

        isPlaying = false;
        lastOutcome = TowerOutcome(
          won: true,
          amount: payout,
          currency: currency,
          isGrandWin: true,
        );

        _revealFullBoard();
        isProcessing = false;
        notifyListeners();
      } else {
        // Step progression
        TowerAudioService.playStepSafe();
        HapticFeedbackService.lightImpact();
        currentRow = rowIndex + 1;
        isProcessing = false;
        notifyListeners();
      }
    }
  }

  void cashOut() {
    if (!isPlaying || isProcessing || currentRow == 0) return;

    isProcessing = true;
    final payout = cashoutValue;
    repository.creditBalance(currency, payout);

    if (_backendRoundId != null) {
      GatewayApiService().cashoutTower(roundId: _backendRoundId!).catchError((_) => <String, dynamic>{});
    }

    TowerAudioService.playCashOut();
    HapticFeedbackService.success();

    isPlaying = false;
    lastOutcome = TowerOutcome(
      won: true,
      amount: payout,
      currency: currency,
    );

    _revealFullBoard();
    isProcessing = false;
    notifyListeners();
  }

  void _revealFullBoard({int? pickedRow, int? pickedCol}) {
    for (var r = 0; r < TowerGameRepository.rows; r++) {
      for (var c = 0; c < TowerGameRepository.cols; c++) {
        final isSelectedPick = (r == pickedRow && c == pickedCol) || board[r][c].isPicked;
        board[r][c] = TowerTileState(
          status: _secretGrid[r][c],
          isPicked: isSelectedPick,
        );
      }
    }
  }
}

