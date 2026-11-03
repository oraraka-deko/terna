library;

import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/upgrade_game/telegram_gift_model.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';
import '../api/gateway_api_service.dart';
import '../inventory/inventory_repository.dart';
import '../wallet/wallet_repository.dart';

class UpgradeGiftsRepository {
  // Exchange rates matching area_game
  double tonRateUsd = 1.515;
  double starsRateUsd = 0.0130;
  double houseEdge = 0.05;
  double minMultiplier = 1.13;

  List<TelegramGift> _cachedCatalog = [];

  /// Load catalog gifts from backend /api/gifts/targets or fallback to assets/telegram/gifts/telegram_gifts.json
  Future<List<TelegramGift>> loadCatalog() async {
    if (_cachedCatalog.isNotEmpty) return _cachedCatalog;

    // 1. Try live backend upgrade targets
    try {
      final targets = await GatewayApiService().getUpgradeTargets();
      if (targets.isNotEmpty) {
        final parsed = <TelegramGift>[];
        for (final item in targets) {
          if (item is Map<String, dynamic>) {
            parsed.add(
              TelegramGift(
                giftId: item['id']?.toString() ?? 'target',
                name: item['name']?.toString() ?? 'Gift',
                priceStars: (item['starsValue'] as num?)?.toInt() ?? 0,
                                isUpgradeable: true,
              ),
            );
          }
        }
        if (parsed.isNotEmpty) {
          _cachedCatalog = parsed;
          return _cachedCatalog;
        }
      }
    } catch (_) {}

    // 2. Fallback to asset file
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
      _cachedCatalog = _fallbackGifts;
    }

    if (_cachedCatalog.isEmpty) {
      _cachedCatalog = _fallbackGifts;
    }

    return _cachedCatalog;
  }

  /// Live user inventory loaded from backend /api/wallet/inventory and WalletRepository
  Future<UpgradeUserInventory> loadUserInventory() async {
    final wallet = WalletRepository();
    final invRepo = InventoryRepository();
    await invRepo.fetchInventory();

    final gifts = invRepo.userItems.value.map((item) {
      return TelegramGift(
        giftId: item.giftId,
        instanceId: item.instanceId,
        name: item.name,
        priceStars: item.priceStars,
                isUpgradeable: true,
        isPlaceholder: false,
      );
    }).toList();

    return UpgradeUserInventory(
      tonBalance: wallet.tonBalance.value,
      starsBalance: wallet.starsBalance.value,
      gifts: gifts,
      isPlaceholder: false,
    );
  }

  /// Backward-compatible alias
  Future<UpgradeUserInventory> loadInitialPlaceholderInventory() => loadUserInventory();

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
