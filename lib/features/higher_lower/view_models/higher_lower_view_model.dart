import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/higher_lower/higher_lower_models.dart';
import '../../../services/higher_lower/higher_lower_odds_service.dart';
import '../../../services/higher_lower/higher_lower_repository.dart';
import '../../../services/higher_lower/higher_lower_audio_service.dart';

/// ViewModel managing state, deck mechanics, predictions, multipliers, and payouts for Higher or Lower.
class HigherLowerViewModel extends ChangeNotifier {
  final HigherLowerRepository _repository;
  final Random _random;

  HigherLowerRoundState _state = HigherLowerRoundState.idle;
  HigherLowerRoundState get state => _state;

  HigherLowerCurrency _currency = HigherLowerCurrency.stars;
  HigherLowerCurrency get currency => _currency;

  double _betAmount = 1.0;
  double get betAmount => _betAmount;

  PlayingCard? _currentCard;
  PlayingCard? get currentCard => _currentCard;

  final List<PlayingCard> _drawnHistory = [];
  List<PlayingCard> get drawnHistory => List.unmodifiable(_drawnHistory);

  int _totalWins = 0;
  int get totalWins => _totalWins;

  int get remainingCardsCount => _deck.isEmpty ? 52 : _deck.length;

  double _currentMultiplier = 1.0;
  double get currentMultiplier => _currentMultiplier;

  List<PlayingCard> _deck = [];

  HigherLowerViewModel({
    HigherLowerRepository? repository,
    Random? random,
  })  : _repository = repository ?? HigherLowerRepository(),
        _random = random ?? Random();

  HigherLowerRepository get repository => _repository;

  int get starsBalance => _repository.starsBalance;
  double get tonBalance => _repository.tonBalance;

  /// Multiplier for calling Higher on current card
  double get nextHigherMultiplier {
    if (_currentCard == null) return 1.26;
    return HigherLowerOddsService.getHigherMultiplier(_currentCard!.rankValue);
  }

  /// Multiplier for calling Lower on current card
  double get nextLowerMultiplier {
    if (_currentCard == null) return 3.80;
    return HigherLowerOddsService.getLowerMultiplier(_currentCard!.rankValue);
  }

  /// Whether calling Higher is available
  bool get canCallHigher {
    if (_state != HigherLowerRoundState.playing &&
        _state != HigherLowerRoundState.correct) {
      return false;
    }
    if (_currentCard == null) return false;
    return HigherLowerOddsService.canCallHigher(_currentCard!.rankValue);
  }

  /// Whether calling Lower is available
  bool get canCallLower {
    if (_state != HigherLowerRoundState.playing &&
        _state != HigherLowerRoundState.correct) {
      return false;
    }
    if (_currentCard == null) return false;
    return HigherLowerOddsService.canCallLower(_currentCard!.rankValue);
  }

  /// Whether current card is an extreme edge (Ace or Two) allowing Skip
  bool get isEdgeCard {
    if (_currentCard == null) return false;
    return HigherLowerOddsService.isEdgeCard(_currentCard!.rankValue);
  }

  /// Potential payout for current round
  double get potentialPayout {
    if (_currency == HigherLowerCurrency.stars) {
      return (_betAmount * _currentMultiplier).roundToDouble();
    }
    return double.parse((_betAmount * _currentMultiplier).toStringAsFixed(3));
  }

  /// Maximum theoretical win cap display (e.g. 20 Stars / 20 TON)
  double get maxWinPreview {
    return _betAmount * 20.0;
  }

  /// Toggle currency between Stars and TON
  void setCurrency(HigherLowerCurrency currency) {
    if (_state != HigherLowerRoundState.idle &&
        _state != HigherLowerRoundState.wrong &&
        _state != HigherLowerRoundState.collected) {
      return;
    }
    HigherLowerAudioService.playTap();
    _currency = currency;
    _betAmount = currency == HigherLowerCurrency.stars ? 1.0 : 0.1;
    notifyListeners();
  }

  /// Set exact bet amount
  void setBetAmount(double amount) {
    _betAmount = max(currency == HigherLowerCurrency.stars ? 1.0 : 0.05, amount);
    notifyListeners();
  }

  /// Adjust bet by delta
  void adjustBet(double delta) {
    HigherLowerAudioService.playTap();
    final minBet = currency == HigherLowerCurrency.stars ? 1.0 : 0.05;
    _betAmount = max(minBet, _betAmount + delta);
    notifyListeners();
  }

  /// Multiply bet by factor (e.g. 2x, 0.5x)
  void multiplyBet(double factor) {
    HigherLowerAudioService.playTap();
    final minBet = currency == HigherLowerCurrency.stars ? 1.0 : 0.05;
    _betAmount = max(minBet, _betAmount * factor);
    if (currency == HigherLowerCurrency.stars) {
      _betAmount = _betAmount.roundToDouble();
    } else {
      _betAmount = double.parse(_betAmount.toStringAsFixed(2));
    }
    notifyListeners();
  }

  /// Start a new game round
  bool startGame() {
    final debited = _repository.debitBet(_betAmount, _currency);
    if (!debited) {
      return false;
    }

    _initFreshDeck();
    _drawnHistory.clear();
    _totalWins = 0;
    _currentMultiplier = 1.0;

    // Deal first card
    _currentCard = _drawCard();
    _state = HigherLowerRoundState.playing;

    HigherLowerAudioService.playFlip();
    notifyListeners();
    return true;
  }

  /// Make a prediction: Higher, Lower, or Skip
  void makePrediction(PredictionType call) {
    if (_state != HigherLowerRoundState.playing &&
        _state != HigherLowerRoundState.correct) {
      return;
    }
    if (_currentCard == null) return;

    final prevCard = _currentCard!;
    final nextCard = _drawCard();

    final result = HigherLowerOddsService.evaluate(
      currentRank: prevCard.rankValue,
      nextRank: nextCard.rankValue,
      call: call,
    );

    // Save previous card in history
    _drawnHistory.add(prevCard);
    _currentCard = nextCard;

    if (result.isWin) {
      if (!result.isTie && call != PredictionType.skip) {
        _currentMultiplier = double.parse(
          (_currentMultiplier * result.stepMultiplier).toStringAsFixed(2),
        );
        _totalWins++;
      }
      _state = HigherLowerRoundState.correct;
      HigherLowerAudioService.playWin();
    } else {
      _state = HigherLowerRoundState.wrong;
      HigherLowerAudioService.playWrong();

      // Record finished round loss
      _repository.archiveRound(
        HigherLowerRoundHistory(
          roundId: 'HL_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          betAmount: _betAmount,
          currency: _currency,
          finalMultiplier: 0.0,
          payoutAmount: 0.0,
          totalWins: _totalWins,
          isCashOut: false,
          cardHistory: List.from(_drawnHistory)..add(nextCard),
        ),
      );
    }

    notifyListeners();
  }

  /// Cash out accumulated winnings
  void collect() {
    if (_state != HigherLowerRoundState.correct) return;

    final winAmount = potentialPayout;
    _repository.creditWin(winAmount, _currency);

    _state = HigherLowerRoundState.collected;
    HigherLowerAudioService.playCollect();

    // Record win in history
    _repository.archiveRound(
      HigherLowerRoundHistory(
        roundId: 'HL_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        betAmount: _betAmount,
        currency: _currency,
        finalMultiplier: _currentMultiplier,
        payoutAmount: winAmount,
        totalWins: _totalWins,
        isCashOut: true,
        cardHistory: List.from(_drawnHistory)..add(_currentCard!),
      ),
    );

    notifyListeners();
  }

  /// Reset to idle for another round
  void playAgain() {
    _state = HigherLowerRoundState.idle;
    notifyListeners();
  }

  /// Generates a standard shuffled 52-card deck
  void _initFreshDeck() {
    _deck = [];
    for (final suit in CardSuit.values) {
      for (int rank = 2; rank <= 14; rank++) {
        _deck.add(PlayingCard(suit: suit, rankValue: rank));
      }
    }
    _deck.shuffle(_random);
  }

  /// Draws a card from deck, reshuffling if low
  PlayingCard _drawCard() {
    if (_deck.isEmpty) {
      _initFreshDeck();
    }
    return _deck.removeLast();
  }
}

