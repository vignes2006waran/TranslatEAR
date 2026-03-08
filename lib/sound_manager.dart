import 'dart:typed_data';
import 'dart:math';
import 'package:just_audio/just_audio.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // Generate musical tune as bytes
  static Uint8List _generateTune(List<double> frequencies, List<int> durations) {
    const sampleRate = 44100;
    final totalSamples = durations.fold(0, (sum, d) => sum + (sampleRate * d ~/ 1000));

    final buffer = ByteData(44 + totalSamples * 2);

    // WAV Header
    final bytes = buffer.buffer.asUint8List();
    final header = 'RIFF'.codeUnits + [0, 0, 0, 0] +
        'WAVE'.codeUnits + 'fmt '.codeUnits +
        [16, 0, 0, 0, 1, 0, 1, 0] +
        _int32Bytes(sampleRate) +
        _int32Bytes(sampleRate * 2) +
        [2, 0, 16, 0] +
        'data'.codeUnits +
        [0, 0, 0, 0];

    for (int i = 0; i < header.length; i++) {
      bytes[i] = header[i];
    }

    // Generate samples for each note
    int sampleIndex = 44;
    for (int noteIndex = 0; noteIndex < frequencies.length; noteIndex++) {
      final freq = frequencies[noteIndex];
      final numSamples = sampleRate * durations[noteIndex] ~/ 1000;
      for (int i = 0; i < numSamples; i++) {
        final t = i / sampleRate;
        final envelope = i < 100 ? i / 100.0 :
        i > numSamples - 100 ? (numSamples - i) / 100.0 : 1.0;
        final sample = (sin(2 * pi * freq * t) * 32767 * envelope * 0.7).toInt();
        buffer.setInt16(sampleIndex, sample, Endian.little);
        sampleIndex += 2;
      }
    }

    // Fix sizes in header
    buffer.setUint32(4, bytes.length - 8, Endian.little);
    buffer.setUint32(40, totalSamples * 2, Endian.little);

    return bytes;
  }

  static List<int> _int32Bytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  // Start tune - rising happy melody (ding ding ding↑)
  static Future<void> playStartTune() async {
    final tune = _generateTune(
      [523.25, 659.25, 783.99, 1046.50], // C5 E5 G5 C6
      [150, 150, 150, 400],
    );
    await _playBytes(tune);
  }

  // Stop tune - falling gentle melody (dong↓ dong↓)
  static Future<void> playStopTune() async {
    final tune = _generateTune(
      [783.99, 659.25, 523.25, 392.00], // G5 E5 C5 G4
      [150, 150, 150, 400],
    );
    await _playBytes(tune);
  }

  static Future<void> _playBytes(Uint8List bytes) async {
    try {
      await _player.stop();
      await _player.setAudioSource(
        _BytesAudioSource(bytes),
      );
      await _player.play();
    } catch (e) {
      print('Sound error: $e');
    }
  }

  static void dispose() {
    _player.dispose();
  }
}

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  _BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }
}