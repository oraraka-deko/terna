import 'package:flutter/material.dart';

/// Currency toggle mode in the Gift Shop banner ("Play With")
enum GiftShopCurrency { stars, ton }

/// Category tabs in the Gift Shop
enum GiftShopCategory { all, collections, stars, craft }

/// Sorting options for gifts
enum GiftShopSortBy { priceAsc, priceDesc, popular, name }

/// View layout mode for the gifts grid
enum GiftShopViewMode { grid2, grid3, list }

/// Domain model representing a Telegram Gift available in the shop.
class GiftShopItem {
  final String giftId;
  final String name;
  final int priceStars;
  final double priceTon;
  final int totalStock;
  final bool isUpgradeable;
  final String editionNumber; // e.g. "#135966"
  final bool hasCloverBadge;
  final bool hasPickaxeBadge;
  final int modelCount;
  final int backdropCount;
  final int symbolCount;
  final List<Color> backgroundGradient;
  final List<String> sampleModelNames;
  final String? releaseTag; // e.g. "NEW", "HOT"

  /// PLACEHOLDER: Indicates this is simulated frontend data
  final bool isPlaceholder;

  const GiftShopItem({
    required this.giftId,
    required this.name,
    required this.priceStars,
    required this.priceTon,
    this.totalStock = 0,
    this.isUpgradeable = false,
    required this.editionNumber,
    this.hasCloverBadge = true,
    this.hasPickaxeBadge = true,
    this.modelCount = 1,
    this.backdropCount = 1,
    this.symbolCount = 1,
    this.backgroundGradient = const [Color(0xFF2E384D), Color(0xFF1E2330)],
    this.sampleModelNames = const [],
    this.releaseTag,
    this.isPlaceholder = false,
  });

  /// Assets paths
  String get tgsPath => 'assets/telegram/gifts/tgs/gift_$giftId.tgs';
  String get webpPath => 'assets/telegram/gifts/webp/gift_$giftId.webp';
  String get pngPath => 'assets/telegram/gifts/png/gift_$giftId.png';

  /// Helper factory to parse from telegram_gifts.json item
  factory GiftShopItem.fromJson(
    Map<String, dynamic> json, {
    int index = 0,
    double starsPriceUsd = 0.013,
    double tonPriceUsd = 1.5,
  }) {
    final giftId = json['gift_id']?.toString() ?? '';
    final name = json['name']?.toString() ?? 'Gift';
    final priceStars = (json['price_stars'] as num?)?.toInt() ?? 25;

    final priceTon = double.parse(
      (priceStars * starsPriceUsd / tonPriceUsd).toStringAsFixed(4),
    );

    // Dynamic edition number like #135966
    final editionSeed = (giftId.hashCode.abs() % 900000) + 100000;
    final editionNumber = '#$editionSeed';

    final isUpgradeable = json['is_upgradeable'] == true || (index % 3 == 0);

    // Extract colors from sample_backdrops if available
    List<Color> gradient = _extractGradient(json, index);

    // Sample models
    List<String> models = [];
    if (json['sample_models'] is List) {
      for (final m in json['sample_models']) {
        if (m is Map && m['name'] != null) {
          models.add(m['name'].toString());
        }
      }
    }

    return GiftShopItem(
      giftId: giftId,
      name: name,
      priceStars: priceStars,
      priceTon: priceTon,
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 10000,
      isUpgradeable: isUpgradeable,
      editionNumber: editionNumber,
      hasCloverBadge: index % 2 == 0,
      hasPickaxeBadge: isUpgradeable,
      modelCount: (json['model_count'] as num?)?.toInt() ?? models.length,
      backdropCount: (json['backdrop_count'] as num?)?.toInt() ?? 3,
      symbolCount: (json['symbol_count'] as num?)?.toInt() ?? 2,
      backgroundGradient: gradient,
      sampleModelNames: models,
      releaseTag: index < 5 ? 'NEW' : null,
      isPlaceholder: true, // PLACEHOLDER: demo shop asset
    );
  }

  static List<Color> _extractGradient(Map<String, dynamic> json, int index) {
    if (json['sample_backdrops'] is List &&
        (json['sample_backdrops'] as List).isNotEmpty) {
      final first = (json['sample_backdrops'] as List).first;
      if (first is Map) {
        final centerHex = first['center_color']?.toString() ?? '';
        final edgeHex = first['edge_color']?.toString() ?? '';
        if (centerHex.isNotEmpty && edgeHex.isNotEmpty) {
          try {
            final c1 = _parseColor(centerHex);
            final c2 = _parseColor(edgeHex);
            return [c1.withValues(alpha: 0.85), c2.withValues(alpha: 0.95)];
          } catch (_) {}
        }
      }
    }

    // Default colorful palettes matching the screenshot (mint, burgundy, brown, lilac, cyan, amber)
    const palettes = [
      [Color(0xFF388E67), Color(0xFF1E4D37)], // Easter Egg emerald mint
      [Color(0xFF5B2245), Color(0xFF2C1021)], // Input Key magenta/burgundy
      [Color(0xFF8B3A2B), Color(0xFF481C14)], // Vice cream warm amber/rust
      [Color(0xFF5A4494), Color(0xFF281E48)], // Liberty lilac/violet
      [Color(0xFF946A28), Color(0xFF4A3412)], // Golden cone warm ochre
      [Color(0xFF286594), Color(0xFF12344D)], // Ocean blue
      [Color(0xFF2E7D32), Color(0xFF1B5E20)], // Forest green
      [Color(0xFF6A1B9A), Color(0xFF4A148C)], // Deep purple
    ];
    return palettes[index % palettes.length];
  }

  static Color _parseColor(String hex) {
    String clean = hex.replaceAll('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  }
}

/// Collection metadata for the Collection filter bottom sheet (Image 2)
class GiftCollection {
  final String id;
  final String name;
  final String iconGiftId;
  final String supplyFormatted; // e.g. "242.5K 🎁"
  final double floorPriceTon; // e.g. 10.9
  final String volume24h; // e.g. "182.7K"
  final bool isNew;
  final bool isPlaceholder;

  const GiftCollection({
    required this.id,
    required this.name,
    required this.iconGiftId,
    required this.supplyFormatted,
    required this.floorPriceTon,
    required this.volume24h,
    this.isNew = false,
    this.isPlaceholder = true, // PLACEHOLDER
  });
}

/// User's inventory state for the gift shop & "My gifts" tab
class GiftShopUserInventory {
  final int starsBalance;
  final double tonBalance;
  final List<GiftShopItem> ownedGifts;
  final bool isPlaceholder;

  const GiftShopUserInventory({
    this.starsBalance = 0,
    this.tonBalance = 0.0,
    this.ownedGifts = const [],
    this.isPlaceholder = false,
  });

  GiftShopUserInventory copyWith({
    int? starsBalance,
    double? tonBalance,
    List<GiftShopItem>? ownedGifts,
    bool? isPlaceholder,
  }) {
    return GiftShopUserInventory(
      starsBalance: starsBalance ?? this.starsBalance,
      tonBalance: tonBalance ?? this.tonBalance,
      ownedGifts: ownedGifts ?? this.ownedGifts,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }
}

/// Current active filters applied to the catalog
class GiftShopFilterState {
  final GiftShopCategory category;
  final GiftShopCurrency currency;
  final String searchQuery;
  final String? selectedCollectionId;
  final GiftShopSortBy sortBy;
  final GiftShopViewMode viewMode;

  const GiftShopFilterState({
    this.category = GiftShopCategory.all,
    this.currency = GiftShopCurrency.stars,
    this.searchQuery = '',
    this.selectedCollectionId,
    this.sortBy = GiftShopSortBy.popular,
    this.viewMode = GiftShopViewMode.grid2,
  });

  GiftShopFilterState copyWith({
    GiftShopCategory? category,
    GiftShopCurrency? currency,
    String? searchQuery,
    String? selectedCollectionId,
    bool clearCollection = false,
    GiftShopSortBy? sortBy,
    GiftShopViewMode? viewMode,
  }) {
    return GiftShopFilterState(
      category: category ?? this.category,
      currency: currency ?? this.currency,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCollectionId: clearCollection
          ? null
          : (selectedCollectionId ?? this.selectedCollectionId),
      sortBy: sortBy ?? this.sortBy,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}
