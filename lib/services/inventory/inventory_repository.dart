library;

import 'package:flutter/foundation.dart';
import '../../models/inventory/inventory_models.dart';
import '../wallet/wallet_repository.dart';

/// Central inventory repository for both Telegram Gifts and Digital Software Subscriptions
class InventoryRepository {
  static final InventoryRepository _instance = InventoryRepository._internal();
  factory InventoryRepository() => _instance;
  InventoryRepository._internal() {
    _initDemoInventory();
  }

  final ValueNotifier<List<InventoryItem>> userItems = ValueNotifier<List<InventoryItem>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  void _initDemoInventory() {
    final now = DateTime.now();
    userItems.value = [
      InventoryItem(
        instanceId: 'inv_dig_1',
        giftId: 'gemini_pro',
        name: 'Google Gemini Pro',
        priceStars: 150,
        floorTon: 1.25,
        isDigital: true,
        acquiredAt: now.subtract(const Duration(days: 2)),
        status: 'ACTIVE',
        posterAsset: 'assets/shop/geministore_reseller/01_Google_Gemini_Pro.jpg',
        licenseKey: 'GEMINI-PRO-9842-AX39-KL28',
        accountLogin: 'terna.gemini.pro@gmail.com',
        accountPassword: 'Password!9841',
        instructions: '1. Log in at gemini.google.com with the credentials provided.\n2. Do not change recovery email.\n3. Enjoy Gemini 1.5 Pro with 2M token context!',
      ),
      InventoryItem(
        instanceId: 'inv_dig_2',
        giftId: 'chatgpt_plus',
        name: 'ChatGPT Plus (GPT-4o)',
        priceStars: 220,
        floorTon: 1.85,
        isDigital: true,
        acquiredAt: now.subtract(const Duration(days: 1)),
        status: 'ACTIVE',
        posterAsset: 'assets/shop/geministore_reseller/02_ChatGPT_Plus.jpg',
        licenseKey: 'OPENAI-PLUS-7718-FF92-0192',
        accountLogin: 'terna.chatgpt.plus@gmail.com',
        accountPassword: 'GPT_Secure#2026',
        instructions: '1. Log in at chatgpt.com\n2. Select GPT-4o model from top dropdown\n3. Dedicated private workspace profile.',
      ),
      InventoryItem(
        instanceId: 'inv_gift_1',
        giftId: '5170145012310081615',
        name: 'Heart Box',
        priceStars: 50,
        floorTon: 0.43,
        isCollectible: true,
        editionNumber: '#907734',
        modelName: 'Ruby Heart',
        backdropColor: '#4A0E17',
        edgeColor: '#E11D48',
        symbolName: 'Heart',
        rarity: 2,
        acquiredAt: now.subtract(const Duration(hours: 14)),
        status: 'ACTIVE',
      ),
      InventoryItem(
        instanceId: 'inv_gift_2',
        giftId: '5170233102089322756',
        name: 'Teddy Bear',
        priceStars: 25,
        floorTon: 0.22,
        isCollectible: true,
        editionNumber: '#566630',
        modelName: 'Golden Honey',
        backdropColor: '#2C1810',
        edgeColor: '#F59E0B',
        symbolName: 'Paw',
        rarity: 1,
        acquiredAt: now.subtract(const Duration(hours: 6)),
        status: 'ACTIVE',
      ),
      InventoryItem(
        instanceId: 'inv_gift_3',
        giftId: '5168103777563050263',
        name: 'Red Rose',
        priceStars: 75,
        floorTon: 0.65,
        isCollectible: true,
        editionNumber: '#791458',
        modelName: 'Velvet Petals',
        backdropColor: '#1F0A12',
        edgeColor: '#F43F5E',
        symbolName: 'Rose',
        rarity: 3,
        acquiredAt: now.subtract(const Duration(hours: 1)),
        status: 'ACTIVE',
      ),
    ];
  }

  void addItem(InventoryItem item) {
    userItems.value = [item, ...userItems.value];
  }

  /// Sell a Telegram gift for either TON or Stars
  bool sellGift({
    required String instanceId,
    required String currency, // 'TON' or 'STARS'
  }) {
    final index = userItems.value.indexWhere((i) => i.instanceId == instanceId);
    if (index == -1) return false;

    final item = userItems.value[index];
    final wallet = WalletRepository();

    if (currency.toUpperCase() == 'TON') {
      wallet.creditTon(item.floorTon, 'Sold Gift: ${item.name}');
    } else {
      wallet.creditStars(item.priceStars, 'Sold Gift: ${item.name}');
    }

    final updated = List<InventoryItem>.from(userItems.value);
    updated.removeAt(index);
    userItems.value = updated;
    return true;
  }

  /// Sell back a digital software subscription (at 60% value as in area_game)
  bool sellDigital(String instanceId) {
    final index = userItems.value.indexWhere((i) => i.instanceId == instanceId);
    if (index == -1) return false;

    final item = userItems.value[index];
    final wallet = WalletRepository();

    // Credit 60% TON value
    wallet.creditTon(item.digitalSellBackTon, 'Liquidated Digital Subscription: ${item.name} (60%)');

    final updated = List<InventoryItem>.from(userItems.value);
    updated.removeAt(index);
    userItems.value = updated;
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
