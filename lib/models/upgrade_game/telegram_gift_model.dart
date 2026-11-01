/// Domain model representing a Telegram Gift item.
class TelegramGift {
  final String giftId;
  final String name;
  final int priceStars;
  final int totalStock;
  final bool isUpgradeable;

  /// Unique instance id if held in inventory.
  final String instanceId;

  /// Flag indicating this is a placeholder/demo asset for frontend development.
  final bool isPlaceholder;

  const TelegramGift({
    required this.giftId,
    required this.name,
    required this.priceStars,
    this.totalStock = 0,
    this.isUpgradeable = false,
    String? instanceId,
    this.isPlaceholder = false,
  }) : instanceId = instanceId ?? giftId;

  /// Primary animated asset path (.tgs format, decompressed with GZip / Lottie)
  String get tgsPath => 'assets/telegram/gifts/tgs/gift_$giftId.tgs';

  /// High-resolution WebP static render asset path
  String get webpPath => 'assets/telegram/gifts/webp/gift_$giftId.webp';

  /// High-resolution PNG asset path
  String get pngPath => 'assets/telegram/gifts/png/gift_$giftId.png';

  factory TelegramGift.fromJson(Map<String, dynamic> json, {bool isPlaceholder = false}) {
    return TelegramGift(
      giftId: json['gift_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Telegram Gift',
      priceStars: (json['price_stars'] as num?)?.toInt() ?? 25,
      totalStock: (json['total_stock'] as num?)?.toInt() ?? 0,
      isUpgradeable: json['is_upgradeable'] == true,
      instanceId: json['instance_id']?.toString() ?? json['gift_id']?.toString(),
      isPlaceholder: isPlaceholder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gift_id': giftId,
      'name': name,
      'price_stars': priceStars,
      'total_stock': totalStock,
      'is_upgradeable': isUpgradeable,
      'instance_id': instanceId,
      'is_placeholder': isPlaceholder,
    };
  }

  TelegramGift copyWith({
    String? giftId,
    String? name,
    int? priceStars,
    int? totalStock,
    bool? isUpgradeable,
    String? instanceId,
    bool? isPlaceholder,
  }) {
    return TelegramGift(
      giftId: giftId ?? this.giftId,
      name: name ?? this.name,
      priceStars: priceStars ?? this.priceStars,
      totalStock: totalStock ?? this.totalStock,
      isUpgradeable: isUpgradeable ?? this.isUpgradeable,
      instanceId: instanceId ?? this.instanceId,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }
}

