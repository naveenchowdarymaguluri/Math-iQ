import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

enum SoundType { correct, wrong, levelUp, tick, gameOver, button }

/// Generates and plays short WAV sound effects entirely in Dart — no audio
/// asset files required.
class SoundService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final SoundService instance = SoundService._();
  SoundService._();

  bool _sfxOn = true;
  bool get sfxOn => _sfxOn;
  void setSfx(bool v) => _sfxOn = v;

  // Pre-computed WAV bytes
  late final Uint8List _correct;
  late final Uint8List _wrong;
  late final Uint8List _levelUp;
  late final Uint8List _tick;
  late final Uint8List _gameOver;
  late final Uint8List _button;

  bool _initialized = false;

  // ─── Init ──────────────────────────────────────────────────────────────────
  void init() {
    if (_initialized) return;
    try {
      // Ascending ding-ding: E5 → A5
      _correct = _makeWav([
        (freq: 659, ms: 80, amp: 0.65),
        (freq: 880, ms: 110, amp: 0.75),
      ]);
      // Descending buzz: A4 → E4
      _wrong = _makeWav([
        (freq: 440, ms: 90, amp: 0.55),
        (freq: 330, ms: 110, amp: 0.45),
      ]);
      // C4 → E4 → G4 → C5 arpeggio
      _levelUp = _makeWav([
        (freq: 262, ms: 100, amp: 0.55),
        (freq: 330, ms: 100, amp: 0.60),
        (freq: 392, ms: 100, amp: 0.65),
        (freq: 523, ms: 200, amp: 0.75),
      ]);
      // Quiet high tick
      _tick = _makeWav([
        (freq: 1047, ms: 35, amp: 0.35),
      ]);
      // Descending sad: G4 → E4 → C4
      _gameOver = _makeWav([
        (freq: 392, ms: 160, amp: 0.55),
        (freq: 330, ms: 160, amp: 0.50),
        (freq: 262, ms: 210, amp: 0.45),
      ]);
      // Soft tap: C5
      _button = _makeWav([
        (freq: 523, ms: 45, amp: 0.45),
      ]);
      _initialized = true;
    } catch (_) {
      // Silently ignore — sounds are non-critical
    }
  }

  final AudioPlayer _player = AudioPlayer();

  // ─── Playback ──────────────────────────────────────────────────────────────
  Future<void> play(SoundType type) async {
    if (!_sfxOn) return;
    if (!_initialized) init();
    if (!_initialized) return;
    try {
      final bytes = switch (type) {
        SoundType.correct => _correct,
        SoundType.wrong => _wrong,
        SoundType.levelUp => _levelUp,
        SoundType.tick => _tick,
        SoundType.gameOver => _gameOver,
        SoundType.button => _button,
      };
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }

  // ─── WAV generation ────────────────────────────────────────────────────────
  static Uint8List _makeWav(
      List<({int freq, int ms, double amp})> notes) {
    const sampleRate = 22050;
    const bitsPerSample = 16;
    const channels = 1;

    // Count total PCM samples
    int totalSamples = 0;
    for (final n in notes) {
      totalSamples += (sampleRate * n.ms / 1000).round();
    }

    // Generate samples with fade-out envelope per note
    final pcm = ByteData(totalSamples * 2);
    int offset = 0;
    for (final note in notes) {
      final noteSamples = (sampleRate * note.ms / 1000).round();
      for (int i = 0; i < noteSamples; i++) {
        final pos = i / noteSamples;
        // Linear fade-out over last 25 %
        final envelope = pos < 0.75 ? 1.0 : (1.0 - pos) / 0.25;
        final angle = 2.0 * math.pi * note.freq * i / sampleRate;
        final raw = (math.sin(angle) * note.amp * 32767 * envelope).round();
        pcm.setInt16(offset, raw.clamp(-32768, 32767), Endian.little);
        offset += 2;
      }
    }

    // Build WAV header (44 bytes)
    final dataLen = pcm.lengthInBytes;
    final header = ByteData(44);
    int hp = 0;
    // RIFF
    for (final b in [0x52, 0x49, 0x46, 0x46]) { // "RIFF"
      header.setUint8(hp++, b);
    }
    header.setUint32(hp, 36 + dataLen, Endian.little); hp += 4;
    for (final b in [0x57, 0x41, 0x56, 0x45]) { // "WAVE"
      header.setUint8(hp++, b);
    }
    // fmt chunk
    for (final b in [0x66, 0x6D, 0x74, 0x20]) { // "fmt "
      header.setUint8(hp++, b);
    }
    header.setUint32(hp, 16, Endian.little); hp += 4;       // chunk size
    header.setUint16(hp, 1, Endian.little); hp += 2;        // PCM
    header.setUint16(hp, channels, Endian.little); hp += 2;
    header.setUint32(hp, sampleRate, Endian.little); hp += 4;
    header.setUint32(
        hp, sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    hp += 4;
    header.setUint16(
        hp, channels * bitsPerSample ~/ 8, Endian.little);
    hp += 2;
    header.setUint16(hp, bitsPerSample, Endian.little); hp += 2;
    // data chunk
    for (final b in [0x64, 0x61, 0x74, 0x61]) { // "data"
      header.setUint8(hp++, b);
    }
    header.setUint32(hp, dataLen, Endian.little);

    // Combine
    final result = Uint8List(44 + dataLen);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, result.length, pcm.buffer.asUint8List());
    return result;
  }
}
