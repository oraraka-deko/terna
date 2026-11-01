import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'territory_audio_stub.dart'
    if (dart.library.js_interop) 'territory_audio_web.dart' as platform_audio;

/// Unified audio service for Territory Jackpot / Area PvP.
class TerritoryAudioService {
  static bool soundEnabled = true;

  static void toggleSound() {
    soundEnabled = !soundEnabled;
    if (soundEnabled) {
      playClick();
    }
  }

  static void playPuckWallHit([double intensity = 0.5]) {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playPuckWallHit(intensity);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void playSlapShot() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playSlapShot();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  static void playTensionRamp() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playTensionRamp();
    }
  }

  static void playAimLock() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playAimLock();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  static void playBettingClosed() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playBettingClosed();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  static void playAlertTick() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playAlertTick();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  static void playTick() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playTick();
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playCoin() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playCoin();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void playClick() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playClick();
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void playVictory() {
    if (!soundEnabled) return;
    if (kIsWeb) {
      platform_audio.TerritoryAudioPlatform.playVictory();
    } else {
      HapticFeedback.heavyImpact();
    }
  }
}

