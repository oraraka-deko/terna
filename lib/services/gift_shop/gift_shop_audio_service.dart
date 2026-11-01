import 'package:flutter/foundation.dart';
import 'gift_shop_audio_stub.dart'
    if (dart.library.js_interop) 'gift_shop_audio_web.dart' as audio_impl;

/// Audio synthesizer service for Gift Shop UI interactions.
class GiftShopAudioService {
  static void playTap() {
    if (kIsWeb) {
      audio_impl.playShopBeepWeb(frequency: 600, duration: 0.05, gain: 0.08);
    }
  }

  static void playSwitchTab() {
    if (kIsWeb) {
      audio_impl.playShopBeepWeb(frequency: 750, duration: 0.06, gain: 0.1);
    }
  }

  static void playCoin() {
    if (kIsWeb) {
      audio_impl.playShopCoinWeb();
    }
  }

  static void playSuccess() {
    if (kIsWeb) {
      audio_impl.playShopSuccessWeb();
    }
  }
}

