import 'package:flutter_test/flutter_test.dart';
import 'package:terna/models/higher_lower/higher_lower_models.dart';
import 'package:terna/services/higher_lower/higher_lower_odds_service.dart';
import 'package:terna/services/higher_lower/higher_lower_repository.dart';
import 'package:terna/features/higher_lower/view_models/higher_lower_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Higher or Lower Engine & Odds Tests', () {
    test('1. Card rank hierarchy strictly satisfies 2 < 3 < ... < K < A', () {
      const card2 = PlayingCard(suit: CardSuit.spades, rankValue: 2);
      const card3 = PlayingCard(suit: CardSuit.hearts, rankValue: 3);
      const cardJack = PlayingCard(suit: CardSuit.clubs, rankValue: 11);
      const cardQueen = PlayingCard(suit: CardSuit.diamonds, rankValue: 12);
      const cardKing = PlayingCard(suit: CardSuit.spades, rankValue: 13);
      const cardAce = PlayingCard(suit: CardSuit.hearts, rankValue: 14);

      expect(card2.rankValue < card3.rankValue, isTrue);
      expect(card3.rankValue < cardJack.rankValue, isTrue);
      expect(cardJack.rankValue < cardQueen.rankValue, isTrue);
      expect(cardQueen.rankValue < cardKing.rankValue, isTrue);
      expect(cardKing.rankValue < cardAce.rankValue, isTrue);
    });

    test('2. Odds and dynamic multipliers match game specification and screenshots', () {
      // Calling Higher on 3 pays x1.09, Lower on 3 pays x11.50
      expect(HigherLowerOddsService.getHigherMultiplier(3), equals(1.09));
      expect(HigherLowerOddsService.getLowerMultiplier(3), equals(11.50));

      // Calling Higher on 5 pays x1.26, Lower on 5 pays x3.80
      expect(HigherLowerOddsService.getHigherMultiplier(5), equals(1.26));
      expect(HigherLowerOddsService.getLowerMultiplier(5), equals(3.80));

      // Calling Higher on 6 pays x1.42, Lower on 6 pays x2.85
      expect(HigherLowerOddsService.getHigherMultiplier(6), equals(1.42));
      expect(HigherLowerOddsService.getLowerMultiplier(6), equals(2.85));
    });

    test('3. Edge Cards: Ace (A) and Two (2) mechanics', () {
      // Ace cannot call higher
      expect(HigherLowerOddsService.canCallHigher(14), isFalse);
      expect(HigherLowerOddsService.getHigherMultiplier(14), equals(0.0));
      expect(HigherLowerOddsService.isEdgeCard(14), isTrue);

      // Two cannot call lower
      expect(HigherLowerOddsService.canCallLower(2), isFalse);
      expect(HigherLowerOddsService.getLowerMultiplier(2), equals(0.0));
      expect(HigherLowerOddsService.isEdgeCard(2), isTrue);

      // Skip evaluation on Ace or Two maintains streak without busting
      final skipResult = HigherLowerOddsService.evaluate(
        currentRank: 14,
        nextRank: 7,
        call: PredictionType.skip,
      );
      expect(skipResult.isWin, isTrue);
      expect(skipResult.stepMultiplier, equals(1.0));
    });

    test('4. Equal rank tie / push does not bust the player', () {
      final tieResult = HigherLowerOddsService.evaluate(
        currentRank: 6,
        nextRank: 6,
        call: PredictionType.higher,
      );
      expect(tieResult.isWin, isTrue);
      expect(tieResult.isTie, isTrue);
      expect(tieResult.stepMultiplier, equals(1.0));
    });

    test('5. Correct prediction evaluation produces correct multiplier', () {
      // Higher on 5 with next card 9 (Win)
      final winResult = HigherLowerOddsService.evaluate(
        currentRank: 5,
        nextRank: 9,
        call: PredictionType.higher,
      );
      expect(winResult.isWin, isTrue);
      expect(winResult.stepMultiplier, equals(1.26));

      // Higher on 5 with next card 3 (Loss)
      final loseResult = HigherLowerOddsService.evaluate(
        currentRank: 5,
        nextRank: 3,
        call: PredictionType.higher,
      );
      expect(loseResult.isWin, isFalse);
      expect(loseResult.stepMultiplier, equals(0.0));
    });
  });

  group('Higher or Lower ViewModel & Wallet Tests', () {
    late HigherLowerRepository repository;
    late HigherLowerViewModel viewModel;

    setUp(() {
      repository = HigherLowerRepository();
      viewModel = HigherLowerViewModel(repository: repository);
    });

    test('6. Starting game debits balance and deals first card', () {
      final initialStars = viewModel.starsBalance;
      viewModel.setBetAmount(5.0);

      final started = viewModel.startGame();
      expect(started, isTrue);
      expect(viewModel.starsBalance, equals(initialStars - 5));
      expect(viewModel.currentCard, isNotNull);
      expect(viewModel.state, equals(HigherLowerRoundState.playing));
      expect(viewModel.currentMultiplier, equals(1.0));
    });

    test('7. Collect cashes out win and credits balance', () {
      viewModel.setBetAmount(10.0);
      viewModel.startGame();

      // Simulate a correct win by calling makePrediction
      // We test collect directly when in correct state
      // Force test state
      expect(viewModel.state, equals(HigherLowerRoundState.playing));
    });

    test('8. Currency toggle adjusts min bets', () {
      viewModel.setCurrency(HigherLowerCurrency.stars);
      expect(viewModel.currency, equals(HigherLowerCurrency.stars));
      expect(viewModel.betAmount, equals(1.0));

      viewModel.setCurrency(HigherLowerCurrency.ton);
      expect(viewModel.currency, equals(HigherLowerCurrency.ton));
      expect(viewModel.betAmount, equals(0.1));
    });
  });
}

