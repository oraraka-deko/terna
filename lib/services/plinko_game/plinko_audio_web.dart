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

class PlinkoAudioPlatform {
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

  /// Synthesized peg bounce sound matching PlinkoGame.tsx
  static void playPegClick([double freq = 680.0]) {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now);
      osc.frequency.exponentialRampToValueAtTime(freq * 0.45, now + 0.035);

      gain.gain.setValueAtTime(0.08, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.035);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.035);
    } catch (_) {}
  }

  /// Ball dropped / chute release
  static void playDrop() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(440.0, now);
      osc.frequency.exponentialRampToValueAtTime(880.0, now + 0.08);

      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.09);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.09);
    } catch (_) {}
  }

  /// Landing payout victory sound
  static void playVictory() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final notes = [587.33, 739.99, 880.0, 1174.66]; // D5, F#5, A5, D6
      for (var i = 0; i < notes.length; i++) {
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'triangle';
        final t = now + (i * 0.07);
        osc.frequency.setValueAtTime(notes[i], t);
        gain.gain.setValueAtTime(0.2, t);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.22);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(t);
        osc.stop(t + 0.22);
      }
    } catch (_) {}
  }

  /// Landing low multiplier tick
  static void playTick() {
    try {
      final ctx = _getOrInitContext();
      if (ctx == null) return;

      final now = ctx.currentTime;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(350.0, now);
      osc.frequency.exponentialRampToValueAtTime(200.0, now + 0.06);

      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + 0.06);
    } catch (_) {}
  }
}

