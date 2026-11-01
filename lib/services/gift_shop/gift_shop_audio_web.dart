import 'dart:js_interop';

@JS('eval')
external JSAny? _jsEval(String code);

void playShopBeepWeb({
  double frequency = 440,
  double duration = 0.08,
  String type = 'sine',
  double gain = 0.15,
}) {
  try {
    final jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const osc = ctx.createOscillator();
          const gainNode = ctx.createGain();
          osc.type = "$type";
          osc.frequency.setValueAtTime($frequency, ctx.currentTime);
          gainNode.gain.setValueAtTime($gain, ctx.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + $duration);
          osc.connect(gainNode);
          gainNode.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + $duration);
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

void playShopSuccessWeb() {
  try {
    final jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const notes = [523.25, 659.25, 783.99, 1046.50];
          notes.forEach((freq, idx) => {
            const osc = ctx.createOscillator();
            const gainNode = ctx.createGain();
            const start = ctx.currentTime + (idx * 0.08);
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, start);
            gainNode.gain.setValueAtTime(0.2, start);
            gainNode.gain.exponentialRampToValueAtTime(0.001, start + 0.15);
            osc.connect(gainNode);
            gainNode.connect(ctx.destination);
            osc.start(start);
            osc.stop(start + 0.15);
          });
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

void playShopCoinWeb() {
  try {
    final jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = "sine";
          osc.frequency.setValueAtTime(987.77, ctx.currentTime);
          osc.frequency.setValueAtTime(1318.51, ctx.currentTime + 0.07);
          gain.gain.setValueAtTime(0.25, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.22);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 0.22);
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}
