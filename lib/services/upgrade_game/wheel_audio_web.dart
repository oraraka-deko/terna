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

class WheelAudioPlatform {
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

  /// Wheel ticking beep (D5 pitch up with exponential ramp)
  static void playTick() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      final now = ctx.currentTime;
      osc.frequency.setValueAtTime(587.33, now); // D5
      osc.frequency.exponentialRampToValueAtTime(880.0, now + 0.08); // Pitch up

      gain.gain.setValueAtTime(0.22, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12); // Fade out

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(now + 0.12);
    } catch (_) {}
  }

  /// Upgrade victory sound
  static void playWin() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
      for (var i = 0; i < notes.length; i++) {
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'triangle';
        final t = now + (i * 0.09);
        osc.frequency.setValueAtTime(notes[i], t);
        gain.gain.setValueAtTime(0.25, t);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.28);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(t);
        osc.stop(t + 0.28);
      }
    } catch (_) {}
  }

  /// Upgrade loss / rejected sound
  static void playLoss() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(320.0, now);
      osc.frequency.exponentialRampToValueAtTime(160.0, now + 0.25);
      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.25);
    } catch (_) {}
  }

  /// Bet placed sound
  static void playBet() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(740.0, now);
      osc.frequency.exponentialRampToValueAtTime(987.77, now + 0.09);
      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.1);
    } catch (_) {}
  }
}
