library;

enum InventoryFilter {
  all,
  digital,
  gifts,
  nft,
}

/// Universal inventory item representing both Telegram Gifts / Collectibles
/// and Digital Software subscriptions / licenses
class InventoryItem {
  final String instanceId;
  final String giftId;
  final String name;
  final int priceStars;
  final double floorTon;
  final bool isDigital;
  final bool isCollectible;
  final String? editionNumber;
  final String? modelName;
  final String? backdropColor;
  final String? edgeColor;
  final String? symbolName;
  final int rarity;
  final DateTime acquiredAt;
  final String status; // 'ACTIVE', 'WITHDRAWN', 'SOLD'

  // Digital product specifics
  final String? licenseKey;
  final String? accountLogin;
  final String? accountPassword;
  final String? instructions;
  final String? posterAsset;

  const InventoryItem({
    required this.instanceId,
    required this.giftId,
    required this.name,
    required this.priceStars,
    required this.floorTon,
    this.isDigital = false,
    this.isCollectible = false,
    this.editionNumber,
    this.modelName,
    this.backdropColor,
    this.edgeColor,
    this.symbolName,
    this.rarity = 1,
    required this.acquiredAt,
    this.status = 'ACTIVE',
    this.licenseKey,
    this.accountLogin,
    this.accountPassword,
    this.instructions,
    this.posterAsset,
  });

  String get tgsPath => 'assets/telegram/gifts/tgs/gift_$giftId.tgs';
  String get webpPath => isDigital
      ? (posterAsset ?? 'assets/shop/geministore_reseller/01_Google_Gemini_Pro.jpg')
      : 'assets/telegram/gifts/webp/gift_$giftId.webp';
  String get pngPath => isDigital
      ? (posterAsset ?? 'assets/shop/geministore_reseller/01_Google_Gemini_Pro.jpg')
      : 'assets/telegram/gifts/png/gift_$giftId.png';

  /// 60% sell-back value for digital products
  double get digitalSellBackTon => double.parse((floorTon * 0.60).toStringAsFixed(3));
  int get digitalSellBackStars => (priceStars * 0.60).round();

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final stars = (json['price_stars'] as num?)?.toInt() ?? (json['priceStars'] as num?)?.toInt() ?? 25;
    final tonVal = (json['valuation'] as num?)?.toDouble() ??
        (json['floor_ton'] as num?)?.toDouble() ??
        double.parse((stars * 0.0086).toStringAsFixed(3));

    return InventoryItem(
      instanceId: json['instance_id']?.toString() ?? json['instanceId']?.toString() ?? '',
      giftId: json['gift_id']?.toString() ?? json['giftId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gift',
      priceStars: stars,
      floorTon: tonVal,
      isDigital: json['is_digital'] == true || json['isDigital'] == true,
      isCollectible: json['is_collectible'] == true || json['isCollectible'] == true || json['model_name'] != null,
      editionNumber: json['edition_number']?.toString(),
      modelName: json['model_name']?.toString(),
      backdropColor: json['backdrop_color']?.toString(),
      edgeColor: json['edge_color']?.toString(),
      symbolName: json['symbol_name']?.toString(),
      rarity: (json['rarity'] as num?)?.toInt() ?? 1,
      acquiredAt: json['acquired_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['acquired_at'] as num).toInt() > 1000000000000
                  ? (json['acquired_at'] as num).toInt()
                  : (json['acquired_at'] as num).toInt() * 1000)
          : DateTime.now(),
      status: json['status']?.toString() ?? 'ACTIVE',
      licenseKey: json['license_key']?.toString(),
      accountLogin: json['account_login']?.toString(),
      accountPassword: json['account_password']?.toString(),
      instructions: json['instructions']?.toString(),
      posterAsset: json['poster_asset']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'instance_id': instanceId,
        'gift_id': giftId,
        'name': name,
        'price_stars': priceStars,
        'floor_ton': floorTon,
        'is_digital': isDigital,
        'is_collectible': isCollectible,
        'edition_number': editionNumber,
        'model_name': modelName,
        'backdrop_color': backdropColor,
        'edge_color': edgeColor,
        'symbol_name': symbolName,
        'rarity': rarity,
        'acquired_at': acquiredAt.millisecondsSinceEpoch,
        'status': status,
        'license_key': licenseKey,
        'account_login': accountLogin,
        'account_password': accountPassword,
        'instructions': instructions,
        'poster_asset': posterAsset,
      };
}

extension StringToDouble on String {
  double toDouble() => double.tryParse(this) ?? 0.0;
}
