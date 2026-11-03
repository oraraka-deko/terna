library;

/// Models for TON Connect and Telegram Stars wallet deposit workflows.

class WalletConfig {
  final String depositAddress;
  final double minDepositTon;
  final int minDepositStars;
  final bool isTestnet;
  final String network;

  const WalletConfig({
    required this.depositAddress,
    this.minDepositTon = 0.1,
    this.minDepositStars = 10,
    this.isTestnet = false,
    this.network = 'mainnet',
  });

  factory WalletConfig.fromJson(Map<String, dynamic> json) {
    return WalletConfig(
      depositAddress: json['depositAddress']?.toString() ?? '',
      minDepositTon: (json['minDepositTon'] as num?)?.toDouble() ?? 0.1,
      minDepositStars: (json['minDepositStars'] as num?)?.toInt() ?? 10,
      isTestnet: json['isTestnet'] == true,
      network: json['network']?.toString() ?? 'mainnet',
    );
  }
}

class TonDepositSession {
  final String depositId;
  final String comment;
  final String depositAddress;
  final String? payload;
  final double amountTon;
  final String nanoAmount;

  const TonDepositSession({
    required this.depositId,
    required this.comment,
    required this.depositAddress,
    this.payload,
    required this.amountTon,
    required this.nanoAmount,
  });

  factory TonDepositSession.fromJson(Map<String, dynamic> json) {
    return TonDepositSession(
      depositId: json['depositId']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      depositAddress: json['depositAddress']?.toString() ?? '',
      payload: json['payload']?.toString(),
      amountTon: (json['amountTon'] as num?)?.toDouble() ?? 0.0,
      nanoAmount: json['nanoAmount']?.toString() ?? '0',
    );
  }
}

class TonVerifyResult {
  final bool verified;
  final String? txHash;
  final double? tonBalance;
  final String message;

  const TonVerifyResult({
    required this.verified,
    this.txHash,
    this.tonBalance,
    required this.message,
  });

  factory TonVerifyResult.fromJson(Map<String, dynamic> json) {
    return TonVerifyResult(
      verified: json['verified'] == true,
      txHash: json['txHash']?.toString(),
      tonBalance: (json['tonBalance'] as num?)?.toDouble(),
      message: json['message']?.toString() ?? (json['verified'] == true ? 'Deposit confirmed' : 'Pending verification'),
    );
  }
}

class StarsInvoiceSession {
  final String invoiceId;
  final String invoiceLink;
  final int starsAmount;

  const StarsInvoiceSession({
    required this.invoiceId,
    required this.invoiceLink,
    required this.starsAmount,
  });

  factory StarsInvoiceSession.fromJson(Map<String, dynamic> json) {
    return StarsInvoiceSession(
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceLink: json['invoiceLink']?.toString() ?? '',
      starsAmount: (json['starsAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class StarsPaidResult {
  final bool success;
  final bool alreadyProcessed;
  final int? starsBalance;

  const StarsPaidResult({
    required this.success,
    this.alreadyProcessed = false,
    this.starsBalance,
  });

  factory StarsPaidResult.fromJson(Map<String, dynamic> json) {
    return StarsPaidResult(
      success: json['success'] == true || json['ok'] == true,
      alreadyProcessed: json['alreadyProcessed'] == true,
      starsBalance: (json['starsBalance'] as num?)?.toInt(),
    );
  }
}

/// Ledger transaction model matching area_game
class WalletTransaction {
  final String id;
  final String type; // 'DEPOSIT', 'WITHDRAWAL', 'PURCHASE', 'SELL_BACK', 'GAME_WIN'
  final String currency; // 'TON', 'STARS'
  final double amount;
  final String status; // 'CONFIRMED', 'PENDING', 'FAILED'
  final DateTime timestamp;
  final String description;
  final String? txHash;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.currency,
    required this.amount,
    this.status = 'CONFIRMED',
    required this.timestamp,
    required this.description,
    this.txHash,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DEPOSIT',
      currency: json['currency']?.toString() ?? 'TON',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'CONFIRMED',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timestamp'] as num).toInt() > 1000000000000
                  ? (json['timestamp'] as num).toInt()
                  : (json['timestamp'] as num).toInt() * 1000)
          : DateTime.now(),
      description: json['description']?.toString() ?? '',
      txHash: json['txHash']?.toString() ?? json['tx_hash']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'currency': currency,
        'amount': amount,
        'status': status,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'description': description,
        'txHash': txHash,
      };
}

