library;

import '../../models/plinko_game/plinko_models.dart';
import '../api/gateway_api_service.dart';
import '../wallet/wallet_repository.dart';

class PlinkoGameRepository {
  double get tonBalance => WalletRepository().tonBalance.value;
  int get starsBalance => WalletRepository().starsBalance.value;

  static const int rows = 12; // 12 tiers = 13 landing buckets
  static const int bucketCount = 13;

  /// Request provably fair ball drop from backend
  Future<Map<String, dynamic>> requestDropFromBackend({
    required double betAmount,
    required PlinkoCurrency currency,
    required PlinkoRisk risk,
  }) async {
    final result = await GatewayApiService().dropPlinko(
      betAmount: betAmount,
      currency: currency.name.toLowerCase(),
      risk: risk.name.toLowerCase(),
      rows: rows,
    );
    if (result['success'] != true) {
      throw StateError(
        result['error']?.toString() ?? 'The backend rejected the Plinko drop.',
      );
    }
    await WalletRepository().refreshBalances();
    return result;
  }
}
