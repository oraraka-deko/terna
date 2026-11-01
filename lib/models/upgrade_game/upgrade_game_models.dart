import 'telegram_gift_model.dart';

enum UpgradeCurrency {
  ton,
  stars,
}

/// User balances and placeholder inventory state.
/// Flagged as placeholders until backend integration is active.
class UpgradeUserInventory {
  final double tonBalance;
  final int starsBalance;
  final List<TelegramGift> gifts;
  final bool isPlaceholder;

  const UpgradeUserInventory({
    required this.tonBalance,
    required this.starsBalance,
    required this.gifts,
    this.isPlaceholder = true,
  });

  UpgradeUserInventory copyWith({
    double? tonBalance,
    int? starsBalance,
    List<TelegramGift>? gifts,
    bool? isPlaceholder,
  }) {
    return UpgradeUserInventory(
      tonBalance: tonBalance ?? this.tonBalance,
      starsBalance: starsBalance ?? this.starsBalance,
      gifts: gifts ?? this.gifts,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }
}

/// Spin result from upgrade attempt.
class UpgradeSpinResult {
  final bool won;
  final double rollPercentile; // 0.0 - 100.0
  final double winChancePercent; // calculated win chance
  final TelegramGift? grantedGift;
  final List<TelegramGift> consumedGifts;
  final double consumedTon;
  final int consumedStars;
  final String? clientSeed;
  final int nonce;

  const UpgradeSpinResult({
    required this.won,
    required this.rollPercentile,
    required this.winChancePercent,
    this.grantedGift,
    this.consumedGifts = const [],
    this.consumedTon = 0,
    this.consumedStars = 0,
    this.clientSeed,
    this.nonce = 1,
  });
}

