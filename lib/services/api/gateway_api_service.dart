library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:http/http.dart' as http;

import '../../env.dart';
import '../../models/api/api_models.dart';
import '../../models/wallet/wallet_models.dart';

/// Central API Client communicating with Express backend (and Cloudflare bindings).
class GatewayApiService {
  static final GatewayApiService _instance = GatewayApiService._internal();
  static String get defaultBaseUrl => Env.backendUrl;
  factory GatewayApiService() => _instance;
  GatewayApiService._internal();

  String _customBaseUrl = '';
  void setBaseUrl(String url) => _customBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');

  /// Base API URL (defaults to Env.apiBaseUrl, e.g. http://localhost:8080/api)
  String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    return Env.apiBaseUrl;
  }

  /// Current user ID for demo / non-Telegram fallback
  String currentUserId = Env.defaultUserId;
  String currentUsername = Env.defaultUsername;

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-User-Id': currentUserId,
      'X-Username': currentUsername,
    };

    try {
      final initData = WebApp().initData;
      if (initData.isNotEmpty) {
        headers['X-Telegram-Init-Data'] = initData;
      }
    } catch (_) {}

    return headers;
  }

  // --- Network Safe Helpers ---

  Future<dynamic> _get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .get(uri, headers: _buildHeaders())
        .timeout(Env.requestTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'GET $endpoint failed: ${response.body}',
    );
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .post(uri, headers: _buildHeaders(), body: jsonEncode(body))
        .timeout(Env.requestTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'POST $endpoint failed: ${response.body}',
    );
  }

  // --------------------------------------------------------------------------
  // 1. HEALTH & WALLET STATE
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getHealth() async {
    try {
      final data = await _get('/health');
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      debugPrint('[GatewayApiService] Health check error: $e');
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWalletInfo() async {
    final data = await _get('/wallet/info?userId=${Uri.encodeComponent(currentUserId)}');
    return data is Map<String, dynamic> ? data : {};
  }

  Future<UserStateResponse> getUserState() async {
    try {
      final info = await getWalletInfo();
      return UserStateResponse(
        tonBalance: (info['tonBalance'] as num?)?.toDouble() ?? 0.0,
        starsBalance: (info['starsBalance'] as num?)?.toInt() ?? 0,
        serverSeedHash: info['serverSeedHash']?.toString() ?? '',
        clientSeed: info['clientSeed']?.toString() ?? 'client_seed',
        nonce: (info['nonce'] as num?)?.toInt() ?? 1,
        gifts: (info['inventory'] as List<dynamic>?)
                ?.map((item) => UserGiftItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            const [],
      );
    } catch (e) {
      debugPrint('[GatewayApiService] getUserState fallback: $e');
      return const UserStateResponse(
        tonBalance: 0.0,
        starsBalance: 0,
        serverSeedHash: '',
        clientSeed: 'offline_client',
        nonce: 1,
        gifts: [],
      );
    }
  }

  Future<List<dynamic>> getUserTransactions({int limit = 30}) async {
    try {
      final data = await _get('/wallet/transactions?limit=$limit&userId=${Uri.encodeComponent(currentUserId)}');
      if (data is Map<String, dynamic> && data['transactions'] is List) {
        return data['transactions'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[GatewayApiService] getUserTransactions error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getUserInventory() async {
    try {
      final data = await _get('/wallet/inventory?userId=${Uri.encodeComponent(currentUserId)}');
      if (data is Map<String, dynamic> && data['inventory'] is List) {
        return data['inventory'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[GatewayApiService] getUserInventory error: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // 2. TON & STARS DEPOSITS & WITHDRAWALS
  // --------------------------------------------------------------------------
  Future<TonDepositSession> createTonDepositRequest(double amountTon) async {
    final data = await _post('/wallet/deposit/ton', {
      'amountTon': amountTon,
    });
    final nano = (amountTon * 1e9).round().toString();
    return TonDepositSession(
      depositId: data['depositId']?.toString() ?? 'dep_${DateTime.now().millisecondsSinceEpoch}',
      depositAddress: data['destinationAddress']?.toString() ?? '',
      comment: data['comment']?.toString() ?? 'Terna Deposit',
      amountTon: amountTon,
      nanoAmount: data['nanoAmount']?.toString() ?? nano,
    );
  }

  Future<TonVerifyResult> verifyTonDeposit({
    required String depositId,
    String? boc,
    String? userWalletAddress,
    required double amountTon,
  }) async {
    final data = await _post('/wallet/deposit/ton', {
      'userId': currentUserId,
      'depositId': depositId,
      'boc': boc,
      'userWalletAddress': userWalletAddress,
      'amountTon': amountTon,
    });
    return TonVerifyResult(
      verified: data['verified'] == true,
      txHash: data['txHash']?.toString(),
      tonBalance: (data['tonBalance'] as num?)?.toDouble() ?? 0.0,
      message: data['message']?.toString() ?? (data['verified'] == true ? 'Deposit confirmed' : 'Pending verification'),
    );
  }

  Future<StarsInvoiceSession> createStarsInvoice(int starsAmount) async {
    final data = await _post('/wallet/stars-invoice', {
      'starsAmount': starsAmount,
    });
    final invoiceId = data['invoiceId']?.toString() ?? '';
    final invoiceLink = data['invoiceLink']?.toString() ?? '';
    if (data['ok'] != true || invoiceId.isEmpty || invoiceLink.isEmpty) {
      throw StateError(data['error']?.toString() ?? 'The backend did not create a Stars invoice.');
    }
    return StarsInvoiceSession(
      invoiceId: invoiceId,
      invoiceLink: invoiceLink,
      starsAmount: starsAmount,
    );
  }

  Future<StarsPaidResult> checkStarsInvoiceStatus(String invoiceId) async {
    final data = await _get('/wallet/stars-invoice/${Uri.encodeComponent(invoiceId)}');
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid Stars invoice status response.');
    }
    return StarsPaidResult.fromJson(data);
  }

  Future<Map<String, dynamic>> adjustUserBalance({
    required String userId,
    required double tonDelta,
    required int starsDelta,
    required String reason,
  }) async {
    final data = await _post('/admin/adjust-balance', {
      'userId': userId,
      'tonDelta': tonDelta,
      'starsDelta': starsDelta,
      'reason': reason,
    });
    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw const FormatException('The admin balance adjustment was not accepted.');
    }
    return data;
  }

  Future<Map<String, dynamic>> withdrawTon(String destinationAddress, double amount) async {
    final data = await _post('/wallet/withdraw/ton', {
      'userId': currentUserId,
      'destinationAddress': destinationAddress,
      'amount': amount,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> requestStarsWithdrawal(int starsAmount, {String? destinationAddress}) async {
    final data = await _post('/wallet/withdraw/stars', {
      'userId': currentUserId,
      'starsAmount': starsAmount,
      'destinationAddress': destinationAddress ?? 'Telegram_Wallet',
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 3. SHOP & GEMINI STORE
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getShopPrices() async {
    try {
      final data = await _get('/shop/prices');
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      return {'tonPriceUsd': 1.5, 'starsPriceUsd': 0.013, 'updatedAt': DateTime.now().millisecondsSinceEpoch};
    }
  }

  Future<List<dynamic>> getGeminiStoreProducts() async {
    try {
      final data = await _get('/shop/geministore/products');
      if (data is Map<String, dynamic> && data['products'] is List) {
        return data['products'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[GatewayApiService] getGeminiStoreProducts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> purchaseGeminiStoreProduct({
    required String productId,
    required String currency,
  }) async {
    final data = await _post('/shop/geministore/purchase', {
      'userId': currentUserId,
      'productId': productId,
      'currency': currency,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> sellBackGift({
    required String giftInstanceId,
    required String payoutCurrency,
  }) async {
    final data = await _post('/shop/geministore/sell-back', {
      'userId': currentUserId,
      'giftInstanceId': giftInstanceId,
      'payoutCurrency': payoutCurrency,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 4. UPGRADE GIFTS GAME
  // --------------------------------------------------------------------------
  Future<List<dynamic>> getUpgradeTargets() async {
    try {
      final data = await _get('/gifts/targets');
      if (data is Map<String, dynamic> && data['targets'] is List) {
        return data['targets'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[GatewayApiService] getUpgradeTargets error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> executeUpgrade({
    required String targetGiftId,
    List<String> selectedInventoryGifts = const [],
    double additionalTon = 0,
    int additionalStars = 0,
    String clientSeed = 'upgrade_client',
    int nonce = 1,
  }) async {
    final data = await _post('/gifts/upgrade', {
      'userId': currentUserId,
      'targetGiftId': targetGiftId,
      'selectedInventoryGifts': selectedInventoryGifts,
      'additionalTon': additionalTon,
      'additionalStars': additionalStars,
      'clientSeed': clientSeed,
      'nonce': nonce,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 5. MINES ARENA GAME
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getActiveMines() async {
    try {
      final data = await _get('/games/mines/active?userId=${Uri.encodeComponent(currentUserId)}');
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      return {'activeRound': null};
    }
  }

  Future<Map<String, dynamic>> startMines({
    required double amount,
    required String currency,
    required int gridSize,
    required int mineCount,
    String clientSeed = 'mines_client',
    int nonce = 1,
  }) async {
    final data = await _post('/games/mines/start', {
      'userId': currentUserId,
      'amount': amount,
      'currency': currency,
      'gridSize': gridSize,
      'mineCount': mineCount,
      'clientSeed': clientSeed,
      'nonce': nonce,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> revealMinesTile({
    required String roundId,
    required int tileIndex,
  }) async {
    final data = await _post('/games/mines/reveal', {
      'userId': currentUserId,
      'roundId': roundId,
      'tileIndex': tileIndex,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> cashoutMines({
    required String roundId,
  }) async {
    final data = await _post('/games/mines/cashout', {
      'userId': currentUserId,
      'roundId': roundId,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 6. TOWER CLIMB GAME
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getActiveTower() async {
    try {
      final data = await _get('/games/tower/active?userId=${Uri.encodeComponent(currentUserId)}');
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      return {'activeRound': null};
    }
  }

  Future<Map<String, dynamic>> startTower({
    required double betAmount,
    required String currency,
    required String difficulty,
    String clientSeed = 'tower_client',
    int nonce = 1,
  }) async {
    final data = await _post('/games/tower/start', {
      'userId': currentUserId,
      'betAmount': betAmount,
      'currency': currency,
      'difficulty': difficulty,
      'clientSeed': clientSeed,
      'nonce': nonce,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> stepTower({
    required String roundId,
    required int rowIndex,
    required int tileIndex,
  }) async {
    final data = await _post('/games/tower/step', {
      'userId': currentUserId,
      'roundId': roundId,
      'rowIndex': rowIndex,
      'tileIndex': tileIndex,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> cashoutTower({
    required String roundId,
  }) async {
    final data = await _post('/games/tower/cashout', {
      'userId': currentUserId,
      'roundId': roundId,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 7. PLINKO GAME
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> dropPlinko({
    required double betAmount,
    required String currency,
    required String risk,
    int rows = 12,
    String clientSeed = 'plinko_client',
    int nonce = 1,
  }) async {
    final data = await _post('/games/plinko/drop', {
      'betAmount': betAmount,
      'currency': currency,
      'risk': risk,
      'rows': rows,
      'clientSeed': clientSeed,
      'nonce': nonce,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> spinRoulette({
    required String roundId,
    required List<Map<String, dynamic>> bets,
    required String clientSeed,
    required int nonce,
  }) async {
    final data = await _post('/games/roulette/spin', {
      'roundId': roundId,
      'bets': bets,
      'clientSeed': clientSeed,
      'nonce': nonce,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> flipSunOrMoon({
    required String roundId,
    required int betAmount,
    required String selectedSide,
    required String clientSeed,
    required int nonce,
  }) async {
    final data = await _post('/games/sun-or-moon/flip', {
      'roundId': roundId,
      'betAmount': betAmount,
      'selectedSide': selectedSide,
      'clientSeed': clientSeed,
      'nonce': nonce,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 8. AREA PVP GAME
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getAreaState() async {
    try {
      final data = await _get('/games/area/state');
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> placeAreaBet({
    required double amount,
    required String currency,
    String? clientSeed,
    String? color,
  }) async {
    final data = await _post('/games/area/bet', {
      'userId': currentUserId,
      'username': currentUsername,
      'amount': amount,
      'currency': currency,
      'clientSeed': clientSeed,
      'color': color,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> settleAreaRound({
    required String winnerId,
  }) async {
    final data = await _post('/games/area/settle', {
      'userId': currentUserId,
      'winnerId': winnerId,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  // --------------------------------------------------------------------------
  // 9. CHAT, SOCIAL & FRIENDS
  // --------------------------------------------------------------------------
  Future<List<dynamic>> getChatMessages({
    String scope = 'global',
    String? targetId,
    int limit = 50,
  }) async {
    try {
      var query = '/chat/messages?scope=$scope&limit=$limit';
      if (targetId != null) query += '&targetId=${Uri.encodeComponent(targetId)}';
      final data = await _get(query);
      if (data is Map<String, dynamic> && data['messages'] is List) {
        return data['messages'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[GatewayApiService] getChatMessages error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> postChatMessage({
    required String text,
    String scope = 'global',
    String? groupId,
    String? recipientId,
    String? recipientName,
    String? replyToId,
    String? replyPreview,
  }) async {
    final data = await _post('/chat/messages', {
      'senderId': currentUserId,
      'sender': currentUsername,
      'text': text,
      'scope': scope,
      'groupId': groupId,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'replyToId': replyToId,
      'replyPreview': replyPreview,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> toggleChatReaction({
    required String messageId,
    required String emoji,
  }) async {
    final data = await _post('/chat/reaction', {
      'userId': currentUserId,
      'messageId': messageId,
      'emoji': emoji,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> markChatSeen(List<String> messageIds) async {
    try {
      await _post('/chat/seen', {
        'userId': currentUserId,
        'messageIds': messageIds,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> executeChatTransfer({
    required String recipientId,
    required String recipientName,
    required String type, // 'ton' | 'stars' | 'gift'
    double amount = 0,
    String? giftId,
    String? giftName,
  }) async {
    final data = await _post('/chat/transfer', {
      'senderId': currentUserId,
      'senderName': currentUsername,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'type': type,
      'amount': amount,
      'giftId': giftId,
      'giftName': giftName,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  Future<List<dynamic>> getFriends() async {
    try {
      final data = await _get('/chat/friends?userId=${Uri.encodeComponent(currentUserId)}');
      if (data is Map<String, dynamic> && data['friends'] is List) {
        return data['friends'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      debugPrint('[GatewayApiService] getFriends error: $e');
      return [];
    }
  }

  Future<bool> sendFriendRequest(String friendId) async {
    try {
      final data = await _post('/chat/friends/request', {
        'userId': currentUserId,
        'friendId': friendId,
      });
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respondFriendRequest(String friendId, bool accept) async {
    try {
      final data = await _post('/chat/friends/respond', {
        'userId': currentUserId,
        'friendId': friendId,
        'accept': accept,
      });
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getGamerBio(String userId) async {
    try {
      final data = await _get('/chat/bio/${Uri.encodeComponent(userId)}');
      if (data is Map<String, dynamic> && data['bio'] != null) {
        return data['bio'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> updateGamerBio(Map<String, dynamic> bio) async {
    final data = await _post('/chat/bio', {
      'userId': currentUserId,
      ...bio,
    });
    return data is Map<String, dynamic> ? data : {};
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException ($statusCode): $message';
}
