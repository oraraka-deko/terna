library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:http/http.dart' as http;

import '../../models/api/api_models.dart';
import '../../models/wallet/wallet_models.dart';

/// Central API Client communicating with Cloudflare Worker Gateway.
class GatewayApiService {
  static final GatewayApiService _instance = GatewayApiService._internal();
  factory GatewayApiService() => _instance;
  GatewayApiService._internal();

  /// Default production edge gateway URL (routed through terna-frontend service binding)
  static const String defaultBaseUrl = 'https://terna-frontend.worker-inosuke.workers.dev';

  String _customBaseUrl = '';
  void setBaseUrl(String url) => _customBaseUrl = url;

  String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.contains('localhost') && !origin.contains('127.0.0.1')) {
        return origin;
      }
    }
    return defaultBaseUrl;
  }

  /// Current user ID for demo / non-Telegram fallback
  String currentUserId = 'demo_user_1';
  String currentUsername = '@terna_player';

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

  // --------------------------------------------------------------------------
  // 1. HEALTH & WALLET STATE
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> getHealth() async {
    final res = await http.get(Uri.parse('$baseUrl/health'), headers: _buildHeaders());
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<UserStateResponse> getUserState() async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/user/state'), headers: _buildHeaders());
    if (res.statusCode != 200) throw Exception('Failed to load user state: ${res.body}');
    return UserStateResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<WalletConfig> getWalletConfig() async {
    final res = await http.get(Uri.parse('$baseUrl/api/v1/wallet/config'), headers: _buildHeaders());
    if (res.statusCode != 200) throw Exception('Failed to load wallet config: ${res.body}');
    return WalletConfig.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // 2. TON DEPOSIT API METHODS
  // --------------------------------------------------------------------------
  Future<TonDepositSession> createTonDepositRequest(double amountTon) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/deposit-request'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'userId': currentUserId,
        'amountTon': amountTon,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to initiate deposit: ${res.body}');
    return TonDepositSession.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<TonVerifyResult> verifyTonDeposit({
    required String depositId,
    String? boc,
    String? userWalletAddress,
    required double amountTon,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/verify-ton-deposit'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'userId': currentUserId,
        'depositId': depositId,
        'boc': boc,
        'userWalletAddress': userWalletAddress,
        'amountTon': amountTon,
      }),
    );
    if (res.statusCode != 200) throw Exception('Deposit verification failed: ${res.body}');
    return TonVerifyResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // 3. TELEGRAM STARS INVOICE API METHODS
  // --------------------------------------------------------------------------
  Future<StarsInvoiceSession> createStarsInvoice(int starsAmount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/stars-invoice'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'userId': currentUserId,
        'starsAmount': starsAmount,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to create Stars invoice: ${res.body}');
    return StarsInvoiceSession.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<bool> checkStarsInvoiceStatus(String invoiceId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/v1/wallet/stars-invoice-status?invoiceId=${Uri.encodeComponent(invoiceId)}'),
      headers: _buildHeaders(),
    );
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['paid'] == true;
  }

  Future<StarsPaidResult> confirmStarsPayment({
    required int starsAmount,
    required String invoiceId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/stars-paid'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'userId': currentUserId,
        'starsAmount': starsAmount,
        'invoiceId': invoiceId,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to confirm Stars payment: ${res.body}');
    return StarsPaidResult.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // --------------------------------------------------------------------------
  // 4. HIGHER OR LOWER PROVABLY FAIR GAME API
  // --------------------------------------------------------------------------
  Future<Map<String, dynamic>> startHigherLower({
    required String currency,
    required double betAmount,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/higher-lower/start'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'currency': currency,
        'betAmount': betAmount,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to start Higher/Lower: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guessHigherLower(String call) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/higher-lower/guess'),
      headers: _buildHeaders(),
      body: jsonEncode({
        'call': call,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to submit prediction: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cashOutHigherLower() async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/higher-lower/cashout'),
      headers: _buildHeaders(),
      body: jsonEncode({}),
    );
    if (res.statusCode != 200) throw Exception('Failed to cash out Higher/Lower: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

