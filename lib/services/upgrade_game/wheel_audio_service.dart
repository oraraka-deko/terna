import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'wheel_audio_stub.dart'
    if (dart.library.js_interop) 'wheel_audio_web.dart' as platform_audio;

/// Unified audio service for the Upgrade Wheel.
/// Uses Web Audio API (dart:js_interop) on Web/Wasm and fallback haptics on native platforms.
class WheelAudioService {
  static void playTick() {
    if (kIsWeb) {
      platform_audio.WheelAudioPlatform.playTick();
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playWin() {
    if (kIsWeb) {
      platform_audio.WheelAudioPlatform.playWin();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playLoss() {
    if (kIsWeb) {
      platform_audio.WheelAudioPlatform.playLoss();
    } else {
      HapticFeedback.vibrate();
    }
  }

  static void playBet() {
    if (kIsWeb) {
      platform_audio.WheelAudioPlatform.playBet();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}

