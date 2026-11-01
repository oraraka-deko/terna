import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/gift_shop/gift_shop_models.dart';

/// Repository handling Gift Shop catalog data, collections, and demo user inventory.
class GiftShopRepository {
  List<GiftShopItem> _cachedCatalog = [];

  /// Loads full catalog of gifts from assets/telegram/gifts/telegram_gifts.json
  Future<List<GiftShopItem>> loadCatalog() async {
    if (_cachedCatalog.isNotEmpty) return _cachedCatalog;

    try {
      final jsonStr = await rootBundle.loadString('assets/telegram/gifts/telegram_gifts.json');
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        int index = 0;
        _cachedCatalog = decoded
            .map((item) {
              final g = GiftShopItem.fromJson(item as Map<String, dynamic>, index: index);
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
        floorPriceGram: 10.9,
        volume24h: '182.7K',
        isNew: true,
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'resistance_dog',
        name: 'Resistance Dog',
        iconGiftId: '5168043875654172773',
        supplyFormatted: '15.8K 🎁',
        floorPriceGram: 424.0,
        volume24h: '168.1K',
        isNew: true,
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'heroic_helmet',
        name: 'Heroic Helmet',
        iconGiftId: '5170250947678437525',
        supplyFormatted: '8K 🎁',
        floorPriceGram: 181.9,
        volume24h: '5.2K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'swiss_watch',
        name: 'Swiss Watch',
        iconGiftId: '5170521118301225164',
        supplyFormatted: '50K 🎁',
        floorPriceGram: 59.9,
        volume24h: '4.5K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'lucky_locket',
        name: 'Lucky Locket',
        iconGiftId: '5170233102089322756',
        supplyFormatted: '66K 🎁',
        floorPriceGram: 16.1,
        volume24h: '7.4K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'rare_bird',
        name: 'Rare Bird',
        iconGiftId: '5170690322832818290',
        supplyFormatted: '15K 🎁',
        floorPriceGram: 29.7,
        volume24h: '1.9K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'sakura_flower',
        name: 'Sakura Flower',
        iconGiftId: '5170564780938756245',
        supplyFormatted: '100K 🎁',
        floorPriceGram: 11.5,
        volume24h: '1.9K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'jingle_bells',
        name: 'Jingle Bells',
        iconGiftId: '5830323722413671504',
        supplyFormatted: '200K 🎁',
        floorPriceGram: 10.8,
        volume24h: '1.1K',
        isPlaceholder: true, // PLACEHOLDER
      ),
      GiftCollection(
        id: 'desk_calendar',
        name: 'Desk Calendar',
        iconGiftId: '5884080014126745057',
        supplyFormatted: '500K 🎁',
        floorPriceGram: 6.2,
        volume24h: '1.4K',
        isPlaceholder: true, // PLACEHOLDER
      ),
    ];
  }

  /// Initial placeholder inventory for frontend development as requested:
  /// - Includes list of all gifts
  /// - 100 stars
  /// - 10 TON / 10 GRAM
  /// - All clearly flagged as placeholders
  Future<GiftShopUserInventory> loadInitialPlaceholderInventory() async {
    final catalog = await loadCatalog();

    // Map gifts into user inventory marked as placeholder
    final placeholderOwned = catalog.take(25).toList();

    return GiftShopUserInventory(
      starsBalance: 100, // PLACEHOLDER: 100 Stars demo
      tonBalance: 10.0, // PLACEHOLDER: 10 TON demo
      gramBalance: 10.0, // PLACEHOLDER: 10 GRAM demo
      ownedGifts: placeholderOwned, // PLACEHOLDER: demo owned gifts
      isPlaceholder: true, // FLAG PLACEHOLDER
    );
  }

  static final List<GiftShopItem> _fallbackItems = [
    const GiftShopItem(
      giftId: '5170145012310081615',
      name: 'Easter Egg',
      priceStars: 25,
      priceGram: 6.78,
      editionNumber: '#135966',
      isPlaceholder: true,
    ),
    const GiftShopItem(
      giftId: '5170250947678437525',
      name: 'Input Key',
      priceStars: 50,
      priceGram: 9.98,
      editionNumber: '#130740',
      isPlaceholder: true,
    ),
    const GiftShopItem(
      giftId: '5170521118301225164',
      name: 'Vice Cream',
      priceStars: 75,
      priceGram: 9.49,
      editionNumber: '#46444',
      isPlaceholder: true,
    ),
    const GiftShopItem(
      giftId: '5168043875654172773',
      name: 'Liberty Statue',
      priceStars: 100,
      priceGram: 9.99,
      editionNumber: '#46001',
      isPlaceholder: true,
    ),
  ];
}

