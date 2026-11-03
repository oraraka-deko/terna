library;

import 'package:flutter/foundation.dart';
import '../../models/inventory/inventory_models.dart';
import '../api/gateway_api_service.dart';
import '../wallet/wallet_repository.dart';

/// Central inventory repository for both Telegram Gifts and Digital Software Subscriptions.
/// Fully connected to Express backend (/api/wallet/inventory and /api/shop/geministore/sell-back).
class InventoryRepository {
  static final InventoryRepository _instance = InventoryRepository._internal();
  factory InventoryRepository() => _instance;
  InventoryRepository._internal() {
    fetchInventory();
  }

  final ValueNotifier<List<InventoryItem>> userItems = ValueNotifier<List<InventoryItem>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// Fetch user inventory from live backend
  Future<void> fetchInventory() async {
    try {
      isLoading.value = true;
      final api = GatewayApiService();
      final rawList = await api.getUserInventory();

      final items = <InventoryItem>[];
      for (final raw in rawList) {
        if (raw is Map<String, dynamic>) {
          DateTime acquired = DateTime.now();
          if (raw['createdAt'] != null) {
            if (raw['createdAt'] is int) {
              acquired = DateTime.fromMillisecondsSinceEpoch(raw['createdAt'] as int);
            } else {
              acquired = DateTime.tryParse(raw['createdAt'].toString()) ?? DateTime.now();
            }
          }

          items.add(
            InventoryItem(
              instanceId: raw['instanceId']?.toString() ?? raw['id']?.toString() ?? 'inv_${raw['giftId']}',
              giftId: raw['giftId']?.toString() ?? raw['productId']?.toString() ?? 'gift',
              name: raw['name']?.toString() ?? 'Inventory Item',
              priceStars: (raw['priceStars'] as num?)?.toInt() ?? (raw['starsValue'] as num?)?.toInt() ?? 0,
              floorTon: (raw['floorTon'] as num?)?.toDouble() ?? (raw['tonValue'] as num?)?.toDouble() ?? 0.0,
              isDigital: raw['isDigital'] == true,
              isCollectible: raw['isCollectible'] == true,
              editionNumber: raw['editionNumber']?.toString(),
              modelName: raw['modelName']?.toString(),
              backdropColor: raw['backdropColor']?.toString(),
              edgeColor: raw['edgeColor']?.toString(),
              symbolName: raw['symbolName']?.toString(),
              rarity: (raw['rarity'] as num?)?.toInt() ?? 1,
              acquiredAt: acquired,
              status: raw['status']?.toString() ?? 'ACTIVE',
              posterAsset: raw['posterAsset']?.toString() ?? raw['posterUrl']?.toString(),
              licenseKey: raw['licenseKey']?.toString() ?? raw['code']?.toString(),
              accountLogin: raw['accountLogin']?.toString(),
              accountPassword: raw['accountPassword']?.toString(),
              instructions: raw['instructions']?.toString(),
            ),
          );
        }
      }
      userItems.value = items;
    } catch (e) {
      debugPrint('[InventoryRepository] fetchInventory offline fallback: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void addItem(InventoryItem item) {
    userItems.value = [item, ...userItems.value];
  }

  /// Sell a Telegram gift for either TON or Stars
  Future<bool> sellGift({
    required String instanceId,
    required String currency, // 'TON' or 'STARS'
  }) async {
    final index = userItems.value.indexWhere((i) => i.instanceId == instanceId);
    if (index == -1) return false;

    final item = userItems.value[index];
    final wallet = WalletRepository();

    try {
      final api = GatewayApiService();
      await api.sellBackGift(
        giftInstanceId: instanceId,
        payoutCurrency: currency.toLowerCase(),
      );
    } catch (_) {
      // Local optimistic credit if offline
      if (currency.toUpperCase() == 'TON') {
        wallet.creditTon(item.floorTon, 'Sold Gift: ${item.name}');
      } else {
        wallet.creditStars(item.priceStars, 'Sold Gift: ${item.name}');
      }
    }

    final updated = List<InventoryItem>.from(userItems.value);
    updated.removeAt(index);
    userItems.value = updated;
    await wallet.refreshBalances();
    return true;
  }

  /// Sell back a digital software subscription (at 60% value as in area_game)
  Future<bool> sellDigital(String instanceId) async {
    final index = userItems.value.indexWhere((i) => i.instanceId == instanceId);
    if (index == -1) return false;

    final item = userItems.value[index];
    final wallet = WalletRepository();

    try {
      final api = GatewayApiService();
      await api.sellBackGift(
        giftInstanceId: instanceId,
        payoutCurrency: 'ton',
      );
    } catch (_) {
      wallet.creditTon(item.digitalSellBackTon, 'Liquidated Digital Subscription: ${item.name} (60%)');
    }

    final updated = List<InventoryItem>.from(userItems.value);
    updated.removeAt(index);
    userItems.value = updated;
    await wallet.refreshBalances();
    return true;
  }

  /// Total Stars valuation
  int get totalStarsValue {
    return userItems.value.fold<int>(0, (sum, i) => sum + i.priceStars);
  }

  /// Total TON floor valuation
  double get totalTonValue {
    return userItems.value.fold<double>(0.0, (sum, i) => sum + i.floorTon);
  }

  /// Total item count
  int get totalCount => userItems.value.length;
}
