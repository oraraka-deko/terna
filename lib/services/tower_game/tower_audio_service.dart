import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'tower_audio_stub.dart'
    if (dart.library.js_interop) 'tower_audio_web.dart' as platform_audio;

/// Unified audio service for Tower Climb game.
class TowerAudioService {
  static void playClick() {
    if (kIsWeb) {
      platform_audio.TowerAudioPlatform.playClick();
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playStepSafe() {
    if (kIsWeb) {
      platform_audio.TowerAudioPlatform.playStepSafe();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void playBust() {
    if (kIsWeb) {
      platform_audio.TowerAudioPlatform.playBust();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playCashOut() {
    if (kIsWeb) {
      platform_audio.TowerAudioPlatform.playCashOut();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void playGrandWin() {
    if (kIsWeb) {
      platform_audio.TowerAudioPlatform.playGrandWin();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}

