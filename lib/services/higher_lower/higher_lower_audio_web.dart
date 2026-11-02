import 'dart:js_interop';

@JS('eval')
external JSAny? _jsEval(String code);

/// Card flip / swish sound
void playCardFlipWeb() {
  try {
    const jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const bufferSize = ctx.sampleRate * 0.08;
          const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
          const data = buffer.getChannelData(0);
          for (let i = 0; i < bufferSize; i++) {
            data[i] = Math.random() * 2 - 1;
          }
          const noise = ctx.createBufferSource();
          noise.buffer = buffer;
          const filter = ctx.createBiquadFilter();
          filter.type = 'bandpass';
          filter.frequency.setValueAtTime(800, ctx.currentTime);
          filter.frequency.exponentialRampToValueAtTime(300, ctx.currentTime + 0.08);
          const gain = ctx.createGain();
          gain.gain.setValueAtTime(0.18, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08);
          noise.connect(filter);
          filter.connect(gain);
          gain.connect(ctx.destination);
          noise.start();
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

/// Correct prediction pleasant ascending chime
void playCardWinWeb() {
  try {
    const jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const notes = [587.33, 880.0]; // D5 -> A5
          notes.forEach((freq, i) => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            const start = ctx.currentTime + (i * 0.08);
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, start);
            gain.gain.setValueAtTime(0.2, start);
            gain.gain.exponentialRampToValueAtTime(0.001, start + 0.18);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(start);
            osc.stop(start + 0.18);
          });
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

/// Wrong prediction low buzzer
void playCardWrongWeb() {
  try {
    const jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sawtooth';
          osc.frequency.setValueAtTime(160, ctx.currentTime);
          osc.frequency.linearRampToValueAtTime(110, ctx.currentTime + 0.25);
          gain.gain.setValueAtTime(0.18, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.25);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 0.25);
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

/// Cash out / collect coins triumph fanfare
void playCardCollectWeb() {
  try {
    const jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
          notes.forEach((freq, idx) => {
            const osc = ctx.createOscillator();
            const gain = ctx.createGain();
            const start = ctx.currentTime + (idx * 0.06);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(freq, start);
            gain.gain.setValueAtTime(0.22, start);
            gain.gain.exponentialRampToValueAtTime(0.001, start + 0.2);
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.start(start);
            osc.stop(start + 0.2);
          });
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

/// UI Tap sound
void playCardTapWeb() {
  try {
    const jsCode = '''
      (function() {
        try {
          const AudioContextClass = window.AudioContext || window.webkitAudioContext;
          if (!AudioContextClass) return;
          const ctx = new AudioContextClass();
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(650, ctx.currentTime);
          gain.gain.setValueAtTime(0.08, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.04);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 0.04);
        } catch(e) {}
      })();
    ''';
    _jsEval(jsCode);
  } catch (_) {}
}

