library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:ton_connect_ui/ton_connect_ui.dart';

import '../../models/wallet/wallet_models.dart';
import '../../env.dart';
import '../api/gateway_api_service.dart';

/// Service managing TON Connect wallet lifecycle, TON blockchain deposits,
/// and native Telegram Stars deposit invoicing.
class TonWalletService extends ChangeNotifier {
  static final TonWalletService _instance = TonWalletService._internal();
  factory TonWalletService() => _instance;
  TonWalletService._internal();

  late final TonConnect _tonConnect;
  bool _isInitialized = false;

  WalletConnection? _connection;
  WalletConnection? get connection => _connection;

  bool get isConnected => tonConnect.isConnected && _connection != null;
  String? get connectedAddress => _connection?.account.address;

  /// Publicly reachable manifest URL
  static String resolveManifestUrl() {
    return Env.tonConnectManifestUrl;
  }

  void init() {
    if (_isInitialized) return;
    _tonConnect = TonConnect(manifestUrl: resolveManifestUrl());
    _isInitialized = true;
  }

  TonConnect get tonConnect {
    if (!_isInitialized) init();
    return _tonConnect;
  }

  /// Open TON Connect UI modal picker (Tonkeeper, Telegram Wallet, MyTonWallet, etc.)
  Future<WalletConnection?> connectWallet(BuildContext context) async {
    final conn = await showWalletPicker(
      context: context,
      ton: tonConnect,
    );

    if (conn != null) {
      _connection = conn;
      notifyListeners();
    }
    return conn;
  }

  /// Disconnect current wallet
  Future<void> disconnectWallet() async {
    if (!_isInitialized) return;
    try {
      await _tonConnect.disconnect();
    } catch (_) {}
    _connection = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // TON DEPOSIT FLOW (TonConnect -> BOC -> TonCenter On-Chain Verification)
  // --------------------------------------------------------------------------
  Future<TonVerifyResult> depositTon({
    required BuildContext context,
    required double amountTon,
    void Function(String stepMessage)? onStepUpdate,
  }) async {
    // 1. Ensure Wallet is connected
    if (!isConnected) {
      onStepUpdate?.call('Please connect your TON wallet first...');
      final conn = await connectWallet(context);
      if (conn == null) {
        throw Exception('Wallet connection was cancelled');
      }
    }

    final userWallet = connectedAddress;
    if (userWallet == null) throw Exception('No connected wallet address');

    // 2. Request unique deposit session from Gateway
    onStepUpdate?.call('Creating deposit session on edge server...');
    final api = GatewayApiService();
    final session = await api.createTonDepositRequest(amountTon);
    if (session.depositAddress.isEmpty || session.depositId.isEmpty) {
      throw StateError('The backend did not provide a valid TON deposit session.');
    }

    // 3. Prompt user confirmation in connected TON wallet
    onStepUpdate?.call('Please confirm the payment request in your wallet...');
    final nanoCoins = BigInt.from((amountTon * 1e9).round());

    final txPayload = TransactionPayload.messages(
      [
        TransactionMessage(
          address: session.depositAddress,
          amount: nanoCoins,
          payload: session.payload,
        ),
      ],
      validUntil: DateTime.now().add(const Duration(minutes: 5)),
      from: userWallet,
    );

    String boc;
    try {
      boc = await tonConnect.sendTransaction(txPayload);
    } catch (e) {
      throw Exception('Payment was rejected or cancelled in your wallet: $e');
    }

    // 4. Verify transaction with TonCenter on edge
    onStepUpdate?.call('Transaction broadcasted! Verifying on-chain via TonCenter API...');
    var verifyResult = await api.verifyTonDeposit(
      depositId: session.depositId,
      boc: boc,
      userWalletAddress: userWallet,
      amountTon: amountTon,
    );

    if (!verifyResult.verified) {
      onStepUpdate?.call('Waiting for next block finalization (~3s)...');
      await Future<void>.delayed(const Duration(seconds: 3));
      verifyResult = await api.verifyTonDeposit(
        depositId: session.depositId,
        boc: boc,
        userWalletAddress: userWallet,
        amountTon: amountTon,
      );
    }

    if (verifyResult.verified) onStepUpdate?.call('✓ Deposit confirmed!');
    return verifyResult;
  }

  // --------------------------------------------------------------------------
  // TELEGRAM STARS DEPOSIT FLOW (Invoice Link -> Native MiniApp openInvoice)
  // --------------------------------------------------------------------------
  Future<StarsPaidResult> depositStars({
    required int starsAmount,
    void Function(String stepMessage)? onStepUpdate,
  }) async {
    onStepUpdate?.call('Generating Stars invoice...');
    final api = GatewayApiService();
    final invoice = await api.createStarsInvoice(starsAmount);

    onStepUpdate?.call('Opening native Telegram payment sheet...');

    bool paidSuccess;
    try {
      final webApp = WebApp();
      final res = await webApp.openInvoice(url: invoice.invoiceLink);
      paidSuccess = (res == InvoiceResult.paid);
    } catch (err) {
      debugPrint('[TonWalletService] Native openInvoice error: $err');
      throw StateError('Telegram Stars payments are available only inside the Telegram app: $err');
    }

    if (!paidSuccess) {
      throw StateError('Payment was cancelled or failed in Telegram.');
    }

    onStepUpdate?.call('Waiting for Telegram payment confirmation...');
    for (var attempt = 0; attempt < 30; attempt++) {
      final result = await api.checkStarsInvoiceStatus(invoice.invoiceId);
      if (result.success) return result;
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    throw TimeoutException(
      'Telegram reported payment, but the verified Stars payment has not reached the wallet yet. Check your balance again shortly.',
    );
  }
}
