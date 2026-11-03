import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

class HapticFeedbackService {
  static final _haptics = WebApp().hapticFeedback;

  // Single interactions
  static void tap() => _haptics.selectionChanged();
  static void selection() => _haptics.selectionChanged();
  static void lightImpact() => _haptics.impactOccurred(style:HapticFeedbackImpactStyle.light);
  static void mediumImpact() => _haptics.impactOccurred(style:HapticFeedbackImpactStyle.medium);
  static void heavyImpact() => _haptics.impactOccurred(style:HapticFeedbackImpactStyle.heavy);

  // Status notifications
  static void success() => _haptics.notificationOccurred(type:HapticFeedbackNotificationType.success);
  static void error() => _haptics.notificationOccurred(type:HapticFeedbackNotificationType.error);
  static void warning() => _haptics.notificationOccurred(type:HapticFeedbackNotificationType.warning);

  /// Kinetic charging pattern (e.g. holding a button or mining action)
  static Future<void> kineticRampUp({int steps = 4, Duration stepDelay = const Duration(milliseconds: 90)}) async {
    const sequence = [
      HapticFeedbackImpactStyle.soft,
      HapticFeedbackImpactStyle.light,
      HapticFeedbackImpactStyle.medium,
      HapticFeedbackImpactStyle.rigid,
      HapticFeedbackImpactStyle.heavy,
    ];
    for (var i = 0; i < steps && i < sequence.length; i++) {
      _haptics.impactOccurred(style: sequence[i]);
      await Future.delayed(stepDelay);
    }
  }

  /// Transaction settlement pulse
  static Future<void> settlementPulse() async {
    _haptics.impactOccurred(style: HapticFeedbackImpactStyle.rigid);
    await Future.delayed(const Duration(milliseconds: 120));
    _haptics.notificationOccurred(type:HapticFeedbackNotificationType.success);
  }
}