library;

import '../../models/higher_lower/higher_lower_models.dart';
import '../wallet/wallet_repository.dart';

/// Repository managing user balance, betting transactions, and round history for Higher or Lower.
class HigherLowerRepository {
  int get starsBalance => WalletRepository().starsBalance.value;
  double get tonBalance => WalletRepository().tonBalance.value;

  final List<HigherLowerRoundHistory> _history = [];
  List<HigherLowerRoundHistory> get history => List.unmodifiable(_history);

  /// Deducts bet amount from the specified currency balance
  bool debitBet(double amount, HigherLowerCurrency currency) {
    if (currency == HigherLowerCurrency.stars) {
      final stars = amount.round();
      return WalletRepository().debitStars(stars, 'Higher/Lower Bet');
    } else {
      return WalletRepository().debitTon(amount, 'Higher/Lower Bet');
    }
  }

  /// Credits collected winnings to user balance
  void creditWin(double amount, HigherLowerCurrency currency) {
    if (currency == HigherLowerCurrency.stars) {
      WalletRepository().creditStars(amount.round(), 'Higher/Lower Win');
    } else {
      WalletRepository().creditTon(amount, 'Higher/Lower Win');
    }
  }

  /// Records finished round into history
  void archiveRound(HigherLowerRoundHistory record) {
    _history.insert(0, record);
    if (_history.length > 50) {
      _history.removeLast();
    }
  }

  Future<Map<String, dynamic>?> syncStartOnGateway(double betAmount, HigherLowerCurrency currency) async {
    return null;
  }

  Future<Map<String, dynamic>?> syncGuessOnGateway(String call) async {
    return null;
  }

  Future<Map<String, dynamic>?> syncCashOutOnGateway() async {
    return null;
  }
}
