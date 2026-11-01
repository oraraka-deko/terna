import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/upgrade_game/telegram_gift_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';

class UpgradeGiftsRepository {
  // Exchange rates matching area_game
  double tonRateUsd = 1.515;
  double starsRateUsd = 0.0130;
  double houseEdge = 0.05;
  double minMultiplier = 1.13;

  List<TelegramGift> _cachedCatalog = [];

  /// Load catalog gifts from assets/telegram/gifts/telegram_gifts.json
  Future<List<TelegramGift>> loadCatalog() async {
    if (_cachedCatalog.isNotEmpty) return _cachedCatalog;

    try {
      final jsonStr = await rootBundle.loadString('assets/telegram/gifts/telegram_gifts.json');
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        _cachedCatalog = decoded
            .map((item) => TelegramGift.fromJson(item as Map<String, dynamic>))
            .where((g) => g.giftId.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Fallback: provide fallback gifts matching known asset IDs
      _cachedCatalog = _fallbackGifts;
    }

    if (_cachedCatalog.isEmpty) {
      _cachedCatalog = _fallbackGifts;
    }

    return _cachedCatalog;
  }

  /// Initial placeholder inventory for frontend development as requested:
  /// - Includes list of all gifts
  /// - 100 stars
  /// - 10 TON
  /// - All clearly flagged as placeholders
  Future<UpgradeUserInventory> loadInitialPlaceholderInventory() async {
    final catalog = await loadCatalog();

    // Map each catalog gift to a user inventory item marked as placeholder
    final placeholderGifts = catalog.map((gift) {
      return gift.copyWith(
        instanceId: 'demo_inst_${gift.giftId}',
        isPlaceholder: true, // FLAG PLACEHOLDER
      );
    }).toList();

    return UpgradeUserInventory(
      tonBalance: 10.0, // PLACEHOLDER: 10 TON
      starsBalance: 100, // PLACEHOLDER: 100 Stars
      gifts: placeholderGifts, // PLACEHOLDER: all gifts
      isPlaceholder: true, // FLAG PLACEHOLDER
    );
  }

  double starsToTon(int stars) {
    if (tonRateUsd <= 0) return 0.0;
    return double.parse((stars * (starsRateUsd / tonRateUsd)).toStringAsFixed(4));
  }

  int tonToStars(double ton) {
    if (starsRateUsd <= 0) return 0;
    return (ton * (tonRateUsd / starsRateUsd)).round();
  }

  static final List<TelegramGift> _fallbackGifts = [
    const TelegramGift(giftId: '5170145012310081615', name: 'Heart Box', priceStars: 15),
    const TelegramGift(giftId: '5168043875654172773', name: 'Silver Chalice', priceStars: 25),
    const TelegramGift(giftId: '5170250947678437525', name: 'Bronze Key', priceStars: 50),
    const TelegramGift(giftId: '5170521118301225164', name: 'Emerald Gem', priceStars: 75),
    const TelegramGift(giftId: '5170233102089322756', name: 'Iron Emblem', priceStars: 100),
    const TelegramGift(giftId: '5170690322832818290', name: 'Silver Compass', priceStars: 150),
    const TelegramGift(giftId: '5170564780938756245', name: 'Cyber Dagger', priceStars: 200),
    const TelegramGift(giftId: '5830323722413671504', name: 'Plasma Core', priceStars: 300),
    const TelegramGift(giftId: '5884080014126745057', name: 'Obsidian Crown', priceStars: 500),
    const TelegramGift(giftId: '6001229799790478558', name: 'Infinity Cube', priceStars: 1000),
  ];
}

