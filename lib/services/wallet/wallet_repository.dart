library;

import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/wallet/wallet_models.dart';
import '../api/gateway_api_service.dart';
import 'ton_wallet_service.dart';

/// Central state repository for wallet balances, TON Connect transactions,
/// and ledger activity log across all games and shop features.
class WalletRepository {
  static final WalletRepository _instance = WalletRepository._internal();
  factory WalletRepository() => _instance;
  WalletRepository._internal() {
    refreshBalances();
  }

  final ValueNotifier<double> tonBalance = ValueNotifier<double>(0.0);
  final ValueNotifier<int> starsBalance = ValueNotifier<int>(0);
  final ValueNotifier<String> depositWalletAddress = ValueNotifier<String>('');
  final ValueNotifier<String> username = ValueNotifier<String>('@terna_player');
  final ValueNotifier<String> avatar = ValueNotifier<String>('');
  final ValueNotifier<List<WalletTransaction>> transactions = ValueNotifier<List<WalletTransaction>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  /// Sync balances and transactions from backend
  Future<void> refreshBalances() async {
    try {
      isLoading.value = true;
      final api = GatewayApiService();

      // 1. Fetch live wallet info
      final info = await api.getWalletInfo();
      if (info.isNotEmpty) {
        tonBalance.value = (info['tonBalance'] as num?)?.toDouble() ?? 0.0;
        starsBalance.value = (info['starsBalance'] as num?)?.toInt() ?? 0;
        depositWalletAddress.value = info['depositWalletAddress']?.toString() ?? '';
        if (info['username'] != null) username.value = info['username'].toString();
        if (info['avatar'] != null) avatar.value = info['avatar'].toString();
        isOffline.value = false;
      }

      // 2. Fetch live transactions
      final rawTxs = await api.getUserTransactions(limit: 50);
      if (rawTxs.isNotEmpty) {
        final parsed = <WalletTransaction>[];
        for (final item in rawTxs) {
          if (item is Map<String, dynamic>) {
            final ts = item['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch((item['createdAt'] as num).toInt())
                : DateTime.now();
            parsed.add(
              WalletTransaction(
                id: item['id']?.toString() ?? 'tx_${item['createdAt']}',
                type: item['type']?.toString() ?? 'TRANSACTION',
                currency: (item['currency']?.toString() ?? 'TON').toUpperCase(),
                amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
                status: item['status']?.toString() ?? 'COMPLETED',
                timestamp: ts,
                description: item['comment']?.toString() ?? item['description']?.toString() ?? '',
                txHash: item['txHash']?.toString(),
              ),
            );
          }
        }
        transactions.value = parsed;
      }
    } catch (e) {
      // Graceful offline fallback: retain last known in-memory state
      isOffline.value = true;
      debugPrint('[WalletRepository] refreshBalances offline fallback: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void creditTon(double amount, String description, {String? txHash}) {
    tonBalance.value = double.parse((tonBalance.value + amount).toStringAsFixed(4));
    _record(
      type: 'DEPOSIT',
      currency: 'TON',
      amount: amount,
      description: description,
      txHash: txHash,
    );
  }

  bool debitTon(double amount, String description) {
    if (tonBalance.value < amount) return false;
    tonBalance.value = double.parse((tonBalance.value - amount).toStringAsFixed(4));
    _record(
      type: 'PURCHASE',
      currency: 'TON',
      amount: -amount,
      description: description,
    );
    return true;
  }

  void creditStars(int amount, String description) {
    starsBalance.value += amount;
    _record(
      type: 'DEPOSIT',
      currency: 'STARS',
      amount: amount.toDouble(),
      description: description,
    );
  }

  bool debitStars(int amount, String description) {
    if (starsBalance.value < amount) return false;
    starsBalance.value -= amount;
    _record(
      type: 'PURCHASE',
      currency: 'STARS',
      amount: -amount.toDouble(),
      description: description,
    );
    return true;
  }

  void _record({
    required String type,
    required String currency,
    required double amount,
    required String description,
    String? txHash,
  }) {
    final newTx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      type: type,
      currency: currency,
      amount: amount,
      status: 'CONFIRMED',
      timestamp: DateTime.now(),
      description: description,
      txHash: txHash,
    );
    transactions.value = [newTx, ...transactions.value];
  }

  /// Submit TON Deposit
  Future<TonVerifyResult> executeTonDeposit(
    BuildContext context,
    double amountTon, {
    void Function(String)? onStepUpdate,
  }) async {
    final tonService = TonWalletService();
    try {
      final res = await tonService.depositTon(
        context: context,
        amountTon: amountTon,
        onStepUpdate: onStepUpdate,
      );
      if (res.verified) {
        await refreshBalances();
      }
      return res;
    } catch (e) {
      onStepUpdate?.call('TON deposit verification failed.');
      rethrow;
    }
  }

  /// Submit Telegram Stars Invoice
  Future<bool> executeStarsDeposit(
    BuildContext context,
    int starsAmount, {
    void Function(String)? onStepUpdate,
  }) async {
    final tonService = TonWalletService();
    try {
      final res = await tonService.depositStars(
        starsAmount: starsAmount,
        onStepUpdate: onStepUpdate,
      );
      if (res.success) {
        await refreshBalances();
        return true;
      }
      return false;
    } catch (e) {
      onStepUpdate?.call('Telegram Stars payment was not verified.');
      rethrow;
    }
  }

  /// Withdraw TON to specified external address
  Future<bool> withdrawTon(String destinationAddress, double amount) async {
    if (tonBalance.value < amount) return false;
    try {
      final api = GatewayApiService();
      final res = await api.withdrawTon(destinationAddress, amount);
      if (res['success'] == true) {
        tonBalance.value = double.parse((tonBalance.value - amount).toStringAsFixed(4));
        _record(
          type: 'WITHDRAWAL',
          currency: 'TON',
          amount: -amount,
          description: 'Withdrawal to ${destinationAddress.substring(0, min(8, destinationAddress.length))}...',
          txHash: res['txHash']?.toString(),
        );
        await refreshBalances();
        return true;
      }
    } catch (e) {
      debugPrint('[WalletRepository] withdrawTon error: $e');
    }
    return false;
  }

  /// Request Stars withdrawal / voucher
  Future<bool> requestStarsWithdrawal(int amount) async {
    if (starsBalance.value < amount) return false;
    try {
      final api = GatewayApiService();
      final res = await api.requestStarsWithdrawal(amount);
      if (res['success'] == true) {
        starsBalance.value -= amount;
        _record(
          type: 'WITHDRAWAL',
          currency: 'STARS',
          amount: -amount.toDouble(),
          description: 'Telegram Stars Withdrawal Request',
        );
        await refreshBalances();
        return true;
      }
    } catch (e) {
      debugPrint('[WalletRepository] requestStarsWithdrawal error: $e');
    }
    return false;
  }
}
