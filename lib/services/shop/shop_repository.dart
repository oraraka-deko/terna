library;

import 'dart:math';
import '../../models/shop/shop_models.dart';
import '../../models/upgrade_game/telegram_gift_model.dart';

class ShopRepository {
  static final ShopRepository _instance = ShopRepository._internal();
  factory ShopRepository() => _instance;
  ShopRepository._internal();

  /// 20 curated digital subscriptions from GeminiStore
  List<DigitalProductItem> getDigitalProducts() {
    return const [
      DigitalProductItem(
        serviceId: 'gemini_pro',
        name: 'Google Gemini Pro',
        category: 'AI Tools',
        description: 'Gemini 1.5 Pro with 2M token context window, multimodal vision, and ultra-fast inference.',
        posterAsset: 'assets/shop/geministore_reseller/01_Google_Gemini_Pro.jpg',
        releaseTag: 'TOP AI',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Access', months: 1, priceTon: 1.25, priceStars: 145, isDefault: true),
          DigitalProductPlan(planId: '3m', name: '3 Months License', months: 3, priceTon: 3.20, priceStars: 370),
          DigitalProductPlan(planId: '12m', name: '1 Year License', months: 12, priceTon: 11.50, priceStars: 1320),
        ],
      ),
      DigitalProductItem(
        serviceId: 'chatgpt_plus',
        name: 'ChatGPT Plus (GPT-4o)',
        category: 'AI Tools',
        description: 'OpenAI GPT-4o with voice mode, DALL-E 3 image generation, and code interpreter.',
        posterAsset: 'assets/shop/geministore_reseller/02_ChatGPT_OpenAI.jpg',
        releaseTag: 'BESTSELLER',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Access', months: 1, priceTon: 1.85, priceStars: 215, isDefault: true),
          DigitalProductPlan(planId: '3m', name: '3 Months License', months: 3, priceTon: 4.90, priceStars: 570),
          DigitalProductPlan(planId: '12m', name: '1 Year License', months: 12, priceTon: 17.80, priceStars: 2050),
        ],
      ),
      DigitalProductItem(
        serviceId: 'claude_anthropic',
        name: 'Claude 3.5 Sonnet',
        category: 'AI Tools',
        description: 'Industry-leading coding intelligence, Artifacts interactive UI sandbox, and high reasoning.',
        posterAsset: 'assets/shop/geministore_reseller/03_Claude_Anthropic.jpg',
        releaseTag: 'DEVELOPER CHOICE',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Access', months: 1, priceTon: 1.80, priceStars: 210, isDefault: true),
          DigitalProductPlan(planId: '3m', name: '3 Months License', months: 3, priceTon: 4.80, priceStars: 560),
        ],
      ),
      DigitalProductItem(
        serviceId: 'lovable_ai',
        name: 'Lovable FullStack AI',
        category: 'Dev & Cloud',
        description: 'Autonomous full-stack web and mobile application generation from text prompts and Figma.',
        posterAsset: 'assets/shop/geministore_reseller/04_Lovable_FullStack_AI.jpg',
        releaseTag: 'NEW',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Builder', months: 1, priceTon: 2.20, priceStars: 255, isDefault: true),
          DigitalProductPlan(planId: '3m', name: '3 Months Pro', months: 3, priceTon: 5.80, priceStars: 670),
        ],
      ),
      DigitalProductItem(
        serviceId: 'grok_xai',
        name: 'Grok 2 (xAI)',
        category: 'AI Tools',
        description: 'Unfiltered real-time knowledge search connected directly to the X network with Flux generation.',
        posterAsset: 'assets/shop/geministore_reseller/05_Grok_xAI.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month SuperGrok', months: 1, priceTon: 1.40, priceStars: 160, isDefault: true),
          DigitalProductPlan(planId: '12m', name: '1 Year Access', months: 12, priceTon: 12.00, priceStars: 1390),
        ],
      ),
      DigitalProductItem(
        serviceId: 'kling_ai',
        name: 'Kling AI Video Pro',
        category: 'Media & Entertainment',
        description: 'Cinematic 1080p AI video generation with realistic physics, camera motion, and character consistency.',
        posterAsset: 'assets/shop/geministore_reseller/06_Kling_AI.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Standard', months: 1, priceTon: 1.90, priceStars: 220, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'elevenlabs',
        name: 'ElevenLabs Prime Voice',
        category: 'AI Tools',
        description: 'Hyper-realistic AI voice cloning, multilingual speech synthesis, and studio sound effects.',
        posterAsset: 'assets/shop/geministore_reseller/07_ElevenLabs.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Creator', months: 1, priceTon: 1.60, priceStars: 185, isDefault: true),
          DigitalProductPlan(planId: '3m', name: '3 Months Creator', months: 3, priceTon: 4.20, priceStars: 485),
        ],
      ),
      DigitalProductItem(
        serviceId: 'wispr_flow',
        name: 'Wispr Flow AI',
        category: 'Utilities',
        description: 'Instant speech-to-text dictation across every desktop application with auto-formatting.',
        posterAsset: 'assets/shop/geministore_reseller/08_Wispr_Flow.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Unlimited', months: 1, priceTon: 0.95, priceStars: 110, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'muse_ai',
        name: 'Muse AI Studio',
        category: 'Media & Entertainment',
        description: 'Next-gen video hosting with automatic transcript search and smart player analytics.',
        posterAsset: 'assets/shop/geministore_reseller/09_Muse_AI.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Pro', months: 1, priceTon: 1.10, priceStars: 125, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'canva_pro',
        name: 'Canva Pro Designer',
        category: 'Utilities',
        description: '100M+ premium stock assets, background remover, brand kits, and Magic Studio AI tools.',
        posterAsset: 'assets/shop/geministore_reseller/10_Canva_Pro.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Private', months: 1, priceTon: 0.85, priceStars: 99, isDefault: true),
          DigitalProductPlan(planId: '12m', name: '1 Year Private', months: 12, priceTon: 6.90, priceStars: 790),
        ],
      ),
      DigitalProductItem(
        serviceId: 'capcut_pro',
        name: 'CapCut Pro Editor',
        category: 'Media & Entertainment',
        description: 'Cloud video editing, auto-captions, 4K 60FPS export, and viral trending templates.',
        posterAsset: 'assets/shop/geministore_reseller/11_CapCut_Pro.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Pro', months: 1, priceTon: 0.90, priceStars: 105, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'microsoft_office',
        name: 'Microsoft 365 ProPlus',
        category: 'Utilities',
        description: 'Word, Excel, PowerPoint, Outlook + 1TB OneDrive cloud storage across 5 devices.',
        posterAsset: 'assets/shop/geministore_reseller/12_Microsoft_Office_Windows.jpg',
        plans: [
          DigitalProductPlan(planId: '12m', name: '1 Year License', months: 12, priceTon: 5.50, priceStars: 640, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'notion_plus',
        name: 'Notion Plus + AI',
        category: 'Dev & Cloud',
        description: 'Unlimited team blocks, page history, custom domains, and integrated Notion AI writer.',
        posterAsset: 'assets/shop/geministore_reseller/13_Notion_Plus.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Plus', months: 1, priceTon: 1.15, priceStars: 135, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'ilovepdf_premium',
        name: 'iLovePDF Premium',
        category: 'Utilities',
        description: 'Unlimited PDF conversion, OCR text recognition, electronic signatures, and batch compression.',
        posterAsset: 'assets/shop/geministore_reseller/14_iLovePdf_Premium.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Premium', months: 1, priceTon: 0.65, priceStars: 75, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'youtube_premium',
        name: 'YouTube Premium & Music',
        category: 'Media & Entertainment',
        description: 'Ad-free videos, background play, offline downloads, and high-bitrate YouTube Music.',
        posterAsset: 'assets/shop/geministore_reseller/15_YouTube_Premium.jpg',
        plans: [
          DigitalProductPlan(planId: '3m', name: '3 Months Access', months: 3, priceTon: 2.10, priceStars: 245, isDefault: true),
          DigitalProductPlan(planId: '12m', name: '1 Year Access', months: 12, priceTon: 6.50, priceStars: 750),
        ],
      ),
      DigitalProductItem(
        serviceId: 'amazon_prime',
        name: 'Amazon Prime Video',
        category: 'Media & Entertainment',
        description: '4K HDR movies, exclusive Amazon Originals series, and multi-device streaming.',
        posterAsset: 'assets/shop/geministore_reseller/16_Amazon_Prime_Video.jpg',
        plans: [
          DigitalProductPlan(planId: '1m', name: '1 Month Private', months: 1, priceTon: 0.80, priceStars: 95, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'apple_music',
        name: 'Apple Music Individual',
        category: 'Media & Entertainment',
        description: 'Lossless audio streaming, Spatial Audio with Dolby Atmos, and 100M+ songs.',
        posterAsset: 'assets/shop/geministore_reseller/17_Apple_Music.jpg',
        plans: [
          DigitalProductPlan(planId: '3m', name: '3 Months Pass', months: 3, priceTon: 1.95, priceStars: 225, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'nord_vpn',
        name: 'NordVPN Ultra Security',
        category: 'Utilities',
        description: 'Threat Protection Pro, double encryption, 60+ countries, and ultra-high speeds.',
        posterAsset: 'assets/shop/geministore_reseller/18_Nord_VPN.jpg',
        plans: [
          DigitalProductPlan(planId: '12m', name: '1 Year Secure Pass', months: 12, priceTon: 4.80, priceStars: 550, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'surfshark_vpn',
        name: 'Surfshark VPN Unlimited',
        category: 'Utilities',
        description: 'Unlimited simultaneous devices, CleanWeb ad-blocker, and strict no-logs policy.',
        posterAsset: 'assets/shop/geministore_reseller/19_Surfshark_VPN.jpg',
        plans: [
          DigitalProductPlan(planId: '12m', name: '1 Year Pass', months: 12, priceTon: 4.20, priceStars: 480, isDefault: true),
        ],
      ),
      DigitalProductItem(
        serviceId: 'super_duolingo',
        name: 'Super Duolingo Plus',
        category: 'Utilities',
        description: 'Unlimited hearts, no ads, mistake review practice, and progress quiz tracking.',
        posterAsset: 'assets/shop/geministore_reseller/20_Super_Duolingo.jpg',
        plans: [
          DigitalProductPlan(planId: '12m', name: '1 Year Family/Super', months: 12, priceTon: 3.90, priceStars: 450, isDefault: true),
        ],
      ),
    ];
  }

  /// Telegram Gifts Catalog
  List<TelegramGift> getTelegramGifts() {
    return const [
      TelegramGift(
        giftId: '5170145012310081615',
        name: 'Heart Box',
        priceStars: 15,
        totalStock: 907734,
        isUpgradeable: true,
      ),
      TelegramGift(
        giftId: '5170233102089322756',
        name: 'Teddy Bear',
        priceStars: 15,
        totalStock: 566630,
        isUpgradeable: true,
      ),
      TelegramGift(
        giftId: '5170250947678437525',
        name: 'Gift Box',
        priceStars: 25,
        totalStock: 779417,
        isUpgradeable: true,
      ),
      TelegramGift(
        giftId: '5168103777563050263',
        name: 'Red Rose',
        priceStars: 25,
        totalStock: 791458,
        isUpgradeable: true,
      ),
      TelegramGift(
        giftId: '5170314437495619623',
        name: 'Star Trophy',
        priceStars: 50,
        totalStock: 120500,
        isUpgradeable: true,
      ),
      TelegramGift(
        giftId: '5170314437495619624',
        name: 'Blue Velvet Rose',
        priceStars: 75,
        totalStock: 45200,
        isUpgradeable: true,
      ),
    ];
  }

  ShopPrices getPrices() => ShopPrices.standard();

  /// Lucky Roulette reel strip & outcome generator
  LuckyRouletteOutcome generateLuckyRouletteOutcome({
    required String giftId,
    required String giftName,
    required int priceStars,
    required double floorTon,
    required double winChance, // 1 to 95
    bool isDemo = false,
  }) {
    final rand = Random();
    final roll = (rand.nextDouble() * 100);
    final won = roll <= winChance;

    // Generate reel strip of 80 tiles
    const totalTiles = 80;
    const winTargetIndex = 65; // Suspense finish near end

    final targetTile = LuckyRouletteTile(
      giftId: giftId,
      name: giftName,
      priceStars: priceStars,
      floorTon: floorTon,
      isFailure: false,
    );

    final failureTile = const LuckyRouletteTile(
      giftId: 'empty',
      name: 'EMPTY',
      priceStars: 0,
      floorTon: 0,
      isFailure: true,
    );

    final strip = <LuckyRouletteTile>[];
    for (int i = 0; i < totalTiles; i++) {
      if (i == winTargetIndex) {
        strip.add(won ? targetTile : failureTile);
      } else {
        // Distribute matching winChance ratio
        final tileRand = rand.nextDouble() * 100;
        strip.add(tileRand <= winChance ? targetTile : failureTile);
      }
    }

    return LuckyRouletteOutcome(
      won: won,
      rollPercentile: double.parse(roll.toStringAsFixed(2)),
      winIndex: winTargetIndex,
      reelStrip: strip,
      message: won ? 'Congratulations! You won $giftName!' : 'Better luck next spin!',
    );
  }
}
