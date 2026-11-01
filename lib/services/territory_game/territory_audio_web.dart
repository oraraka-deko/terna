import 'dart:js_interop';

@JS('AudioContext')
extension type AudioContext._(JSObject _) implements JSObject {
  external factory AudioContext();
  external double get currentTime;
  external AudioDestinationNode get destination;
  external OscillatorNode createOscillator();
  external GainNode createGain();
  external JSPromise<JSAny?> resume();
  external String get state;
}

@JS('AudioDestinationNode')
extension type AudioDestinationNode._(JSObject _) implements JSObject {}

@JS('AudioParam')
extension type AudioParam._(JSObject _) implements JSObject {
  external void setValueAtTime(double value, double startTime);
  external void exponentialRampToValueAtTime(double value, double endTime);
  external void linearRampToValueAtTime(double value, double endTime);
}

@JS('GainNode')
extension type GainNode._(JSObject _) implements JSObject {
  external AudioParam get gain;
  external void connect(JSObject destination);
}

@JS('OscillatorNode')
extension type OscillatorNode._(JSObject _) implements JSObject {
  external set type(String value);
  external AudioParam get frequency;
  external void connect(JSObject destination);
  external void start([double when]);
  external void stop([double when]);
}

class TerritoryAudioPlatform {
  static AudioContext? _ctx;

  static AudioContext? _getOrInitContext() {
    try {
      _ctx ??= AudioContext();
      if (_ctx!.state == 'suspended') {
        _ctx!.resume();
      }
      return _ctx;
    } catch (_) {
      return null;
    }
  }

  /// Snappy transient strike + deep hollow table resonance thud
  static void playPuckWallHit(double intensity) {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final clamped = intensity.clamp(0.1, 1.0);
      final now = ctx.currentTime;

      // 1. Transient snap
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'triangle';
      final baseFreq = 850.0 + (clamped * 150.0);
      osc.frequency.setValueAtTime(baseFreq, now);
      osc.frequency.exponentialRampToValueAtTime(160.0, now + 0.05);

      gain.gain.setValueAtTime(0.22 * clamped, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.05);

      // 2. Hollow sub thud
      final subOsc = ctx.createOscillator();
      final subGain = ctx.createGain();
      subOsc.type = 'sine';
      subOsc.frequency.setValueAtTime(140.0, now);
      subOsc.frequency.exponentialRampToValueAtTime(50.0, now + 0.08);

      subGain.gain.setValueAtTime(0.28 * clamped, now);
      subGain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

      subOsc.connect(subGain);
      subGain.connect(ctx.destination);
      subOsc.start(now);
      subOsc.stop(now + 0.08);
    } catch (_) {}
  }

  /// Launch slap shot
  static void playSlapShot() {
    playPuckWallHit(1.0);
  }

  /// Tension ramp before shot fires
  static void playTensionRamp() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(220.0, now);
      osc.frequency.exponentialRampToValueAtTime(660.0, now + 1.8);

      gain.gain.setValueAtTime(0.02, now);
      gain.gain.linearRampToValueAtTime(0.12, now + 1.5);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 1.8);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 1.8);
    } catch (_) {}
  }

  /// Aiming arrow lock chirp
  static void playAimLock() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880.0, now);
      osc.frequency.exponentialRampToValueAtTime(1760.0, now + 0.1);

      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.12);
    } catch (_) {}
  }

  /// Buzzer when betting closes
  static void playBettingClosed() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(220.0, now);
      osc.frequency.setValueAtTime(180.0, now + 0.08);

      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.22);
    } catch (_) {}
  }

  /// Dual-tone alert beep for countdown urgency
  static void playAlertTick() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc1 = ctx.createOscillator();
      final osc2 = ctx.createOscillator();
      final gain = ctx.createGain();

      osc1.type = 'sawtooth';
      osc2.type = 'sine';
      osc1.frequency.setValueAtTime(880.0, now);
      osc2.frequency.setValueAtTime(1760.0, now);

      gain.gain.setValueAtTime(0.14, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

      osc1.connect(gain);
      osc2.connect(gain);
      gain.connect(ctx.destination);

      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + 0.08);
      osc2.stop(now + 0.08);
    } catch (_) {}
  }

  /// Subtle timer tick
  static void playTick() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(950.0, now);

      gain.gain.setValueAtTime(0.08, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.03);
    } catch (_) {}
  }

  /// Double harmonic bell clink when betting coins
  static void playCoin() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc1 = ctx.createOscillator();
      final gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(987.77, now);
      osc1.frequency.exponentialRampToValueAtTime(1318.51, now + 0.08);
      gain1.gain.setValueAtTime(0.22, now);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.18);

      final osc2 = ctx.createOscillator();
      final gain2 = ctx.createGain();
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(1567.98, now + 0.05);
      osc2.frequency.exponentialRampToValueAtTime(2093.00, now + 0.14);
      gain2.gain.setValueAtTime(0.001, now);
      gain2.gain.setValueAtTime(0.18, now + 0.05);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.22);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.05);
      osc2.stop(now + 0.22);
    } catch (_) {}
  }

  /// UI Click
  static void playClick() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(600.0, now);
      osc.frequency.exponentialRampToValueAtTime(300.0, now + 0.04);
      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.04);
    } catch (_) {}
  }

  /// Arpeggiated victory fanfare
  static void playVictory() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;
      final notes = [523.25, 659.25, 783.99, 1046.50];

      for (int i = 0; i < notes.length; i++) {
        final startTime = now + (i * 0.1);
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(notes[i], startTime);

        gain.gain.setValueAtTime(0.2, startTime);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.4);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(startTime);
        osc.stop(startTime + 0.4);
      }
    } catch (_) {}
  }
}

