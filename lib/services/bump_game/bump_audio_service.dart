import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'bump_audio_stub.dart'
    if (dart.library.js_interop) 'bump_audio_web.dart' as platform_audio;

/// Unified audio service for Arena Bump
class BumpAudioService {
  static bool soundEnabled = true;

  static void toggleSound() {
    soundEnabled = !soundEnabled;
    if (soundEnabled) {
      playClick();
    }
  }

  static void playBallBump([double intensity = 0.5]) {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playBallBump(intensity);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void playWallBump([double intensity = 0.5]) {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playWallBump(intensity);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  static void playWarningBeep() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playWarningBeep();
    }
  }

  static void playEdgeOpen() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playEdgeOpen();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void playEliminated() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playEliminated();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playLaunchImpulse() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playLaunchImpulse();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playVictory() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playVictory();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playClick() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playClick();
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playCoin() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playCoin();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void playBettingClosed() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.BumpAudioPlatform.playBettingClosed();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}

