library;

/// Data transfer models for communication with Cloudflare Edge Gateway API.

/// User state returned by GET /api/v1/user/state
class UserStateResponse {
  final double tonBalance;
  final int starsBalance;
  final String serverSeedHash;
  final String clientSeed;
  final int nonce;
  final List<UserGiftItem> gifts;

  const UserStateResponse({
    required this.tonBalance,
    required this.starsBalance,
    required this.serverSeedHash,
    required this.clientSeed,
    required this.nonce,
    this.gifts = const [],
  });

  factory UserStateResponse.fromJson(Map<String, dynamic> json) {
    return UserStateResponse(
      tonBalance: (json['tonBalance'] as num?)?.toDouble() ?? 0.0,
      starsBalance: (json['starsBalance'] as num?)?.toInt() ?? 0,
      serverSeedHash: json['serverSeedHash']?.toString() ?? '',
      clientSeed: json['clientSeed']?.toString() ?? '',
      nonce: (json['nonce'] as num?)?.toInt() ?? 0,
      gifts: (json['gifts'] as List<dynamic>?)
              ?.map((item) => UserGiftItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'tonBalance': tonBalance,
        'starsBalance': starsBalance,
        'serverSeedHash': serverSeedHash,
        'clientSeed': clientSeed,
        'nonce': nonce,
        'gifts': gifts.map((g) => g.toJson()).toList(),
      };
}

/// An owned gift in the player's edge SQLite vault
class UserGiftItem {
  final String instanceId;
  final String giftId;
  final String name;
  final int priceStars;

  const UserGiftItem({
    required this.instanceId,
    required this.giftId,
    required this.name,
    required this.priceStars,
  });

  factory UserGiftItem.fromJson(Map<String, dynamic> json) {
    return UserGiftItem(
      instanceId: json['instance_id']?.toString() ?? json['instanceId']?.toString() ?? '',
      giftId: json['gift_id']?.toString() ?? json['giftId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Gift',
      priceStars: (json['price_stars'] as num?)?.toInt() ??
          (json['priceStars'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'instance_id': instanceId,
        'gift_id': giftId,
        'name': name,
        'price_stars': priceStars,
      };
}

/// Deterministic Provably Fair Plinko roll response from POST /api/v1/play/plinko
class PlinkoRollResult {
  final int bucketIndex;
  final List<int> directions;
  final double multiplier;
  final double payout;
  final String revealedServerSeed;
  final String nextServerSeedHash;
  final double tonBalance;
  final int starsBalance;

  const PlinkoRollResult({
    required this.bucketIndex,
    required this.directions,
    required this.multiplier,
    required this.payout,
    required this.revealedServerSeed,
    required this.nextServerSeedHash,
    required this.tonBalance,
    required this.starsBalance,
  });

  factory PlinkoRollResult.fromJson(Map<String, dynamic> json) {
    return PlinkoRollResult(
      bucketIndex: (json['bucketIndex'] as num?)?.toInt() ?? 0,
      directions: (json['directions'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 0.0,
      payout: (json['payout'] as num?)?.toDouble() ?? 0.0,
      revealedServerSeed: json['revealedServerSeed']?.toString() ?? '',
      nextServerSeedHash: json['nextServerSeedHash']?.toString() ?? '',
      tonBalance: (json['tonBalance'] as num?)?.toDouble() ?? 0.0,
      starsBalance: (json['starsBalance'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Result of provably fair Upgrade wheel roll from POST /api/v1/play/upgrade
class UpgradeWheelResult {
  final bool won;
  final double rollPercentile;
  final double winChancePercent;
  final double targetAngleDeg;
  final UserGiftItem? grantedGift;
  final String revealedServerSeed;
  final String nextServerSeedHash;
  final double tonBalance;
  final int starsBalance;

  const UpgradeWheelResult({
    required this.won,
    required this.rollPercentile,
    required this.winChancePercent,
    required this.targetAngleDeg,
    this.grantedGift,
    required this.revealedServerSeed,
    required this.nextServerSeedHash,
    required this.tonBalance,
    required this.starsBalance,
  });

  factory UpgradeWheelResult.fromJson(Map<String, dynamic> json) {
    return UpgradeWheelResult(
      won: json['won'] == true,
      rollPercentile: (json['rollPercentile'] as num?)?.toDouble() ?? 0.0,
      winChancePercent: (json['winChancePercent'] as num?)?.toDouble() ?? 0.0,
      targetAngleDeg: (json['targetAngleDeg'] as num?)?.toDouble() ?? 0.0,
      grantedGift: json['grantedGift'] != null
          ? UserGiftItem.fromJson(json['grantedGift'] as Map<String, dynamic>)
          : null,
      revealedServerSeed: json['revealedServerSeed']?.toString() ?? '',
      nextServerSeedHash: json['nextServerSeedHash']?.toString() ?? '',
      tonBalance: (json['tonBalance'] as num?)?.toDouble() ?? 0.0,
      starsBalance: (json['starsBalance'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Response from starting a Tower game session POST /api/v1/tower/start
class TowerSessionStartResult {
  final String serverSeedHash;
  final int currentRow;

  const TowerSessionStartResult({
    required this.serverSeedHash,
    required this.currentRow,
  });

  factory TowerSessionStartResult.fromJson(Map<String, dynamic> json) {
    return TowerSessionStartResult(
      serverSeedHash: json['serverSeedHash']?.toString() ?? '',
      currentRow: (json['currentRow'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Response from picking a tile in Tower game POST /api/v1/tower/pick
class TowerTilePickResult {
  final String status; // 'safe' | 'busted' | 'cashed_out'
  final bool isSafe;
  final int? clearedRow;
  final int? nextRow;
  final List<int>? rowTiles;
  final List<List<int>>? fullMatrix;
  final double? multiplier;
  final double? payout;
  final String? revealedServerSeed;
  final double? tonBalance;
  final int? starsBalance;

  const TowerTilePickResult({
    required this.status,
    required this.isSafe,
    this.clearedRow,
    this.nextRow,
    this.rowTiles,
    this.fullMatrix,
    this.multiplier,
    this.payout,
    this.revealedServerSeed,
    this.tonBalance,
    this.starsBalance,
  });

  factory TowerTilePickResult.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'safe';
    return TowerTilePickResult(
      status: status,
      isSafe: status == 'safe' || status == 'cashed_out',
      clearedRow: (json['clearedRow'] as num?)?.toInt(),
      nextRow: (json['nextRow'] as num?)?.toInt(),
      rowTiles: (json['rowTiles'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      fullMatrix: (json['fullMatrix'] as List<dynamic>?)
          ?.map((r) => (r as List<dynamic>).map((c) => (c as num).toInt()).toList())
          .toList(),
      multiplier: (json['multiplier'] as num?)?.toDouble(),
      payout: (json['payout'] as num?)?.toDouble(),
      revealedServerSeed: json['revealedServerSeed']?.toString(),
      tonBalance: (json['tonBalance'] as num?)?.toDouble(),
      starsBalance: (json['starsBalance'] as num?)?.toInt(),
    );
  }
}

/// Response from cashing out Tower game POST /api/v1/tower/cashout
class TowerCashoutResult {
  final String status;
  final double multiplier;
  final double payout;
  final List<List<int>>? fullMatrix;
  final String revealedServerSeed;
  final double tonBalance;
  final int starsBalance;

  const TowerCashoutResult({
    required this.status,
    required this.multiplier,
    required this.payout,
    this.fullMatrix,
    required this.revealedServerSeed,
    required this.tonBalance,
    required this.starsBalance,
  });

  factory TowerCashoutResult.fromJson(Map<String, dynamic> json) {
    return TowerCashoutResult(
      status: json['status']?.toString() ?? 'cashed_out',
      multiplier: (json['multiplier'] as num?)?.toDouble() ?? 0.0,
      payout: (json['payout'] as num?)?.toDouble() ?? 0.0,
      fullMatrix: (json['fullMatrix'] as List<dynamic>?)
          ?.map((r) => (r as List<dynamic>).map((c) => (c as num).toInt()).toList())
          .toList(),
      revealedServerSeed: json['revealedServerSeed']?.toString() ?? '',
      tonBalance: (json['tonBalance'] as num?)?.toDouble() ?? 0.0,
      starsBalance: (json['starsBalance'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Generic API response wrapper with error support
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResponse.success(this.data, {this.statusCode = 200})
      : success = true,
        error = null;

  const ApiResponse.failure(this.error, {this.statusCode = 400})
      : success = false,
        data = null;
}

