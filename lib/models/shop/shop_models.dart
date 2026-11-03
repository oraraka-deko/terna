library;


/// Plan variant for digital software subscriptions
class DigitalProductPlan {
  final String planId;
  final String name; // e.g. "1 Month Access", "1 Year License"
  final int months;
  final double priceTon;
  final int priceStars;
  final bool isDefault;

  const DigitalProductPlan({
    required this.planId,
    required this.name,
    this.months = 1,
    required this.priceTon,
    required this.priceStars,
    this.isDefault = false,
  });

  factory DigitalProductPlan.fromJson(Map<String, dynamic> json) {
    return DigitalProductPlan(
      planId: json['plan_id']?.toString() ?? json['planId']?.toString() ?? '1m',
      name: json['name']?.toString() ?? json['plan_name']?.toString() ?? '1 Month',
      months: (json['months'] as num?)?.toInt() ?? 1,
      priceTon: (json['price_ton'] as num?)?.toDouble() ?? 1.5,
      priceStars: (json['price_stars'] as num?)?.toInt() ?? 150,
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'name': name,
        'months': months,
        'price_ton': priceTon,
        'price_stars': priceStars,
        'is_default': isDefault,
      };
}

/// Digital product from GeminiStore catalog (AI tools, software, developer keys)
class DigitalProductItem {
  final String serviceId;
  final String name;
  final String category;
  final String description;
  final String posterAsset;
  final String? releaseTag;
  final List<DigitalProductPlan> plans;
  final int stockCount;
  final bool inStock;

  const DigitalProductItem({
    required this.serviceId,
    required this.name,
    required this.category,
    required this.description,
    required this.posterAsset,
    this.releaseTag,
    required this.plans,
    this.stockCount = 99,
    this.inStock = true,
  });

  DigitalProductPlan get defaultPlan =>
      plans.firstWhere((p) => p.isDefault, orElse: () => plans.first);

  factory DigitalProductItem.fromJson(Map<String, dynamic> json) {
    return DigitalProductItem(
      serviceId: json['service_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Digital Subscription',
      category: json['category']?.toString() ?? 'AI Tools',
      description: json['description']?.toString() ?? '',
      posterAsset: json['poster_asset']?.toString() ?? 'assets/shop/geministore_reseller/01_Google_Gemini_Pro.jpg',
      releaseTag: json['release_tag']?.toString(),
      plans: (json['plans'] as List<dynamic>?)
              ?.map((p) => DigitalProductPlan.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      stockCount: (json['stock_count'] as num?)?.toInt() ?? 99,
      inStock: json['in_stock'] != false,
    );
  }
}

/// Order record for delivered software credentials
class DigitalOrderRecord {
  final String orderId;
  final String serviceName;
  final String planName;
  final String credentialsText;
  final String? licenseKey;
  final String? accountLogin;
  final String? accountPassword;
  final String instructions;
  final DateTime purchasedAt;
  final String currency;
  final double amountPaid;
  final String status; // 'DELIVERED', 'WITHDRAWN', 'REFUNDED'

  const DigitalOrderRecord({
    required this.orderId,
    required this.serviceName,
    required this.planName,
    required this.credentialsText,
    this.licenseKey,
    this.accountLogin,
    this.accountPassword,
    required this.instructions,
    required this.purchasedAt,
    required this.currency,
    required this.amountPaid,
    this.status = 'DELIVERED',
  });
}

/// Live prices for Telegram Stars & Telegram Premium conversions
class ShopPrices {
  final double tonPerStar;
  final double starPriceUsd;
  final double gramPriceUsd;
  final int minStarsPurchase;
  final List<PremiumDurationOption> premiumOptions;

  const ShopPrices({
    this.tonPerStar = 0.0086,
    this.starPriceUsd = 0.0175,
    this.gramPriceUsd = 1.42,
    this.minStarsPurchase = 100,
    this.premiumOptions = const [],
  });

  factory ShopPrices.standard() {
    return const ShopPrices(
      tonPerStar: 0.0086,
      starPriceUsd: 0.0175,
      gramPriceUsd: 1.42,
      minStarsPurchase: 100,
      premiumOptions: [
        PremiumDurationOption(months: 3, priceTon: 7.20, originalPriceTon: 8.50, discountPercent: 15),
        PremiumDurationOption(months: 6, priceTon: 13.50, originalPriceTon: 17.00, discountPercent: 20),
        PremiumDurationOption(months: 12, priceTon: 24.80, originalPriceTon: 34.00, discountPercent: 27),
      ],
    );
  }
}

class PremiumDurationOption {
  final int months;
  final double priceTon;
  final double originalPriceTon;
  final int discountPercent;

  const PremiumDurationOption({
    required this.months,
    required this.priceTon,
    required this.originalPriceTon,
    required this.discountPercent,
  });
}

/// Recipient verification data
class RecipientVerification {
  final bool ok;
  final String? name;
  final String? username;
  final String? photoUrl;
  final bool hasActivePremium;
  final String? error;

  const RecipientVerification({
    required this.ok,
    this.name,
    this.username,
    this.photoUrl,
    this.hasActivePremium = false,
    this.error,
  });
}

/// Single tile item for the Lucky Roulette spinning reel
class LuckyRouletteTile {
  final String giftId;
  final String name;
  final int priceStars;
  final double floorTon;
  final bool isFailure;

  const LuckyRouletteTile({
    required this.giftId,
    required this.name,
    required this.priceStars,
    required this.floorTon,
    required this.isFailure,
  });

  String get assetPath => isFailure
      ? ''
      : 'assets/telegram/gifts/webp/gift_$giftId.webp';
}

/// Final outcome of Lucky Roulette spin
class LuckyRouletteOutcome {
  final bool won;
  final double rollPercentile;
  final int winIndex;
  final List<LuckyRouletteTile> reelStrip;
  final String? message;

  const LuckyRouletteOutcome({
    required this.won,
    required this.rollPercentile,
    required this.winIndex,
    required this.reelStrip,
    this.message,
  });
}
