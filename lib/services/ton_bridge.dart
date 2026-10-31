import 'dart:convert';
import 'dart:js_interop';

@JS('initTonConnect')
external void _initTonConnect(JSString manifestUrl);

@JS('connectTonWallet')
external JSPromise<JSAny?> _connectTonWallet();

@JS('getTonWalletAddress')
external JSString? _getTonWalletAddress();

@JS('sendTonTx')
external JSPromise<JSString> _sendTonTx(JSString txJson);

class TonConnectBridge {
  static void init(String manifestUrl) {
    _initTonConnect(manifestUrl.toJS);
  }

  static Future<void> connect() async {
    await _connectTonWallet().toDart;
  }

  static String? getConnectedAddress() {
    final addr = _getTonWalletAddress();
    return addr?.toDart;
  }

  static Future<String> sendPayment({
    required String recipientAddress,
    required BigInt nanoTons,
    required String orderIdMemo,
  }) async {
    final validUntil = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 300; // 5 min
    
    // Construct comment payload (0x00000000 prefix + utf8 bytes)
    final commentBytes = utf8.encode(orderIdMemo);
    final payloadBytes = [0, 0, 0, 0, ...commentBytes];
    final base64Payload = base64Encode(payloadBytes);

    final tx = {
      'validUntil': validUntil,
      'messages': [
        {
          'address': recipientAddress,
          'amount': nanoTons.toString(),
          'payload': base64Payload,
        }
      ]
    };

    final jsResult = await _sendTonTx(jsonEncode(tx).toJS).toDart;
    return jsResult.toDart;
  }
}