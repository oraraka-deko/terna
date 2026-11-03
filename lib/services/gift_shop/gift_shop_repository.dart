import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/gift_shop/gift_shop_models.dart';

/// Repository handling Gift Shop catalog data, collections, and demo user inventory.
class GiftShopRepository {
  List<GiftShopItem> _cachedCatalog = [];

  /// Loads full catalog of gifts from assets/telegram/gifts/telegram_gifts.json
  Future<List<GiftShopItem>> loadCatalog({
    double starsPriceUsd = 0.013,
    double tonPriceUsd = 1.5,
  }) async {
    if (_cachedCatalog.isNotEmpty) return _cachedCatalog;

    try {
      final jsonStr = await rootBundle.loadString(
        'assets/telegram/gifts/telegram_gifts.json',
      );
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        int index = 0;
        _cachedCatalog = decoded
            .map((item) {
              final g = GiftShopItem.fromJson(
                item as Map<String, dynamic>,
                index: index,
                starsPriceUsd: starsPriceUsd,
                tonPriceUsd: tonPriceUsd,
              );
              index++;
              return g;
            })
            .where((g) => g.giftId.isNotEmpty)
            .toList();
      }
    } catch (_) {
      _cachedCatalog = _fallbackItems;
    }

    if (_cachedCatalog.isEmpty) {
      _cachedCatalog = _fallbackItems;
    }

    return _cachedCatalog;
  }

  /// Collections matching the Screenshot modal (Image 2)
  List<GiftCollection> getCollections() {
    return const [
      GiftCollection(
        id: 'myth_mask',
        name: 'Myth Mask',
        iconGiftId: '5170145012310081615',
        supplyFormatted: '242.5K 🎁',
        floorPriceTon: 10.9,
        volume24h: '182.7K',
        isNew: true,
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'resistance_dog',
        name: 'Resistance Dog',
        iconGiftId: '5168043875654172773',
        supplyFormatted: '15.8K 🎁',
        floorPriceTon: 424.0,
        volume24h: '168.1K',
        isNew: true,
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'heroic_helmet',
        name: 'Heroic Helmet',
        iconGiftId: '5170250947678437525',
        supplyFormatted: '8K 🎁',
        floorPriceTon: 181.9,
        volume24h: '5.2K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'swiss_watch',
        name: 'Swiss Watch',
        iconGiftId: '5170521118301225164',
        supplyFormatted: '50K 🎁',
        floorPriceTon: 59.9,
        volume24h: '4.5K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'lucky_locket',
        name: 'Lucky Locket',
        iconGiftId: '5170233102089322756',
        supplyFormatted: '66K 🎁',
        floorPriceTon: 16.1,
        volume24h: '7.4K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'rare_bird',
        name: 'Rare Bird',
        iconGiftId: '5170690322832818290',
        supplyFormatted: '15K 🎁',
        floorPriceTon: 29.7,
        volume24h: '1.9K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'sakura_flower',
        name: 'Sakura Flower',
        iconGiftId: '5170564780938756245',
        supplyFormatted: '100K 🎁',
        floorPriceTon: 11.5,
        volume24h: '1.9K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'jingle_bells',
        name: 'Jingle Bells',
        iconGiftId: '5830323722413671504',
        supplyFormatted: '200K 🎁',
        floorPriceTon: 10.8,
        volume24h: '1.1K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'desk_calendar',
        name: 'Desk Calendar',
        iconGiftId: '5884080014126745057',
        supplyFormatted: '500K 🎁',
        floorPriceTon: 6.2,
        volume24h: '1.4K',
        isPlaceholder: true, // PLACEHOLDER
      ),
    ];
  }

  /// Empty local inventory until the backend returns the user's wallet and gifts.
  Future<GiftShopUserInventory> loadInitialPlaceholderInventory() async {
    return GiftShopUserInventory(
      starsBalance: 0,
      tonBalance: 0,
      ownedGifts: const [],
      isPlaceholder: false,
    );
  }

  static final List<GiftShopItem> _fallbackItems = [
    const GiftShopItem(
      giftId: '5170145012310081615',
      name: 'Heart Box',
      priceStars: 15,
      priceTon: 0.13,
      editionNumber: '#135966',
      isPlaceholder: true,
    ),
    const GiftShopItem(
      giftId: '5170250947678437525',
      name: 'Gift Box',
      priceStars: 25,
      priceTon: 0.22,
      editionNumber: '#130740',
      isPlaceholder: true,
    ),
    const GiftShopItem(
      giftId: '5170521118301225164',
      name: 'Blue Diamond',
      priceStars: 100,
      priceTon: 0.87,
      editionNumber: '#46444',
      isPlaceholder: true,
    ),
    const GiftShopItem(
      giftId: '5168043875654172773',
      name: 'Golden Trophy',
      priceStars: 100,
      priceTon: 0.87,
      editionNumber: '#46001',
      isPlaceholder: true,
    ),
  ];
}
