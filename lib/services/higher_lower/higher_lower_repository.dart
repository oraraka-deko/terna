import '../../models/higher_lower/higher_lower_models.dart';
import '../api/gateway_api_service.dart';

/// Repository managing user balance, betting transactions, and round history for Higher or Lower.
/// Supports edge Cloudflare Worker Gateway API synchronization with graceful local offline demo fallback.
class HigherLowerRepository {
  final GatewayApiService _api = GatewayApiService();

  int _starsBalance = 100;
  double _tonBalance = 10.0;

  int get starsBalance => _starsBalance;
  double get tonBalance => _tonBalance;

  final List<HigherLowerRoundHistory> _history = [];
  List<HigherLowerRoundHistory> get history => List.unmodifiable(_history);

  /// Deducts bet amount from the specified currency balance
  bool debitBet(double amount, HigherLowerCurrency currency) {
    if (currency == HigherLowerCurrency.stars) {
      final stars = amount.round();
      if (_starsBalance >= stars) {
        _starsBalance -= stars;
        return true;
      }
      return false;
    } else {
      if (_tonBalance >= amount) {
        _tonBalance = double.parse((_tonBalance - amount).toStringAsFixed(3));
        return true;
      }
      return false;
    }
  }

  /// Credits collected winnings to user balance
  void creditWin(double amount, HigherLowerCurrency currency) {
    if (currency == HigherLowerCurrency.stars) {
      _starsBalance += amount.round();
    } else {
      _tonBalance = double.parse((_tonBalance + amount).toStringAsFixed(3));
    }
  }

  /// Records finished round into history
  void archiveRound(HigherLowerRoundHistory record) {
    _history.insert(0, record);
    if (_history.length > 50) {
      _history.removeLast();
    }
  }

  /// Optional remote sync with Cloudflare Edge Gateway
  Future<Map<String, dynamic>?> syncStartOnGateway(double betAmount, HigherLowerCurrency currency) async {
    try {
      final res = await _api.startHigherLower(
        currency: currency == HigherLowerCurrency.stars ? 'stars' : 'ton',
        betAmount: betAmount,
      );
      if (res['starsBalance'] != null) {
        _starsBalance = (res['starsBalance'] as num).toInt();
      }
      if (res['tonBalance'] != null) {
        _tonBalance = (res['tonBalance'] as num).toDouble();
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> syncGuessOnGateway(String call) async {
    try {
      return await _api.guessHigherLower(call);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> syncCashOutOnGateway() async {
    try {
      final res = await _api.cashOutHigherLower();
      if (res['starsBalance'] != null) {
        _starsBalance = (res['starsBalance'] as num).toInt();
      }
      if (res['tonBalance'] != null) {
        _tonBalance = (res['tonBalance'] as num).toDouble();
      }
      return res;
    } catch (_) {
      return null;
    }
  }
}
