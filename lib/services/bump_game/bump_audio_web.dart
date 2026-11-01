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

class BumpAudioPlatform {
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

  /// Punchy hollow ball-ball bump / womp sound
  static void playBallBump(double intensity) {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final clamped = intensity.clamp(0.1, 1.0);
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'triangle';

      final startFreq = 260.0 + (clamped * 120.0);
      final endFreq = 75.0;
      osc.frequency.setValueAtTime(startFreq, now);
      osc.frequency.exponentialRampToValueAtTime(endFreq, now + 0.07);

      gain.gain.setValueAtTime(0.25 * clamped, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.08);
    } catch (_) {}
  }

  /// Wall cushion impact
  static void playWallBump(double intensity) {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final clamped = intensity.clamp(0.1, 1.0);
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';

      osc.frequency.setValueAtTime(180.0, now);
      osc.frequency.exponentialRampToValueAtTime(45.0, now + 0.06);

      gain.gain.setValueAtTime(0.20 * clamped, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.07);
    } catch (_) {}
  }

  /// Edge warning beep (blinking red edge)
  static void playWarningBeep() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(920.0, now);
      osc.frequency.setValueAtTime(1380.0, now + 0.04);

      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.08);
    } catch (_) {}
  }

  /// Edge gap opens
  static void playEdgeOpen() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(420.0, now);
      osc.frequency.exponentialRampToValueAtTime(210.0, now + 0.15);

      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.16);
    } catch (_) {}
  }

  /// Ball falls out and gets eliminated
  static void playEliminated() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(480.0, now);
      osc.frequency.exponentialRampToValueAtTime(60.0, now + 0.35);

      gain.gain.setValueAtTime(0.22, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.36);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.36);
    } catch (_) {}
  }

  /// Launch push toward center
  static void playLaunchImpulse() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(140.0, now);
      osc.frequency.exponentialRampToValueAtTime(540.0, now + 0.12);

      gain.gain.setValueAtTime(0.3, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.15);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.15);
    } catch (_) {}
  }

  /// Victory fanfare
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

  /// Coin bet placed
  static void playCoin() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(987.77, now);
      osc.frequency.exponentialRampToValueAtTime(1318.51, now + 0.08);

      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.16);
    } catch (_) {}
  }

  /// Buzzer
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
}

