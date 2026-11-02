import 'package:flutter/foundation.dart';
import 'higher_lower_audio_stub.dart'
    if (dart.library.js_interop) 'higher_lower_audio_web.dart' as audio_impl;

/// Audio synthesizer service for Higher or Lower.
class HigherLowerAudioService {
  static void playFlip() {
    if (kIsWeb) {
      audio_impl.playCardFlipWeb();
    }
  }

  static void playWin() {
    if (kIsWeb) {
      audio_impl.playCardWinWeb();
    }
  }

  static void playWrong() {
    if (kIsWeb) {
      audio_impl.playCardWrongWeb();
    }
  }

  static void playCollect() {
    if (kIsWeb) {
      audio_impl.playCardCollectWeb();
    }
  }

  static void playTap() {
    if (kIsWeb) {
      audio_impl.playCardTapWeb();
    }
  }
}

