import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'plinko_audio_stub.dart'
    if (dart.library.js_interop) 'plinko_audio_web.dart' as platform_audio;

/// Unified audio service for Plinko Game.
class PlinkoAudioService {
  static void playPegClick([double freq = 680.0]) {
    if (kIsWeb) {
      platform_audio.PlinkoAudioPlatform.playPegClick(freq);
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playDrop() {
    if (kIsWeb) {
      platform_audio.PlinkoAudioPlatform.playDrop();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void playVictory() {
    if (kIsWeb) {
      platform_audio.PlinkoAudioPlatform.playVictory();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void playTick() {
    if (kIsWeb) {
      platform_audio.PlinkoAudioPlatform.playTick();
    } else {
      HapticFeedback.selectionClick();
    }
  }
}

