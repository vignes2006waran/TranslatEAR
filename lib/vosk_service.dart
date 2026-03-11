import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:io';

/// VoskService — wraps speech_to_text with onDevice:true
class VoskService {
  VoskService._();
  static final VoskService instance = VoskService._();

  static const Map<String, String> _modelUrls = {
    'en': 'https://alphacephei.com/vosk/models/vosk-model-small-en-in-0.4.zip',
    'hi': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
    'ta': 'https://alphacephei.com/vosk/models/vosk-model-small-ta-0.4.zip',
    'te': 'https://alphacephei.com/vosk/models/vosk-model-small-te-0.42.zip',
    'kn': 'https://alphacephei.com/vosk/models/vosk-model-small-kn-0.9.zip',
    'fr': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'de': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'es': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'ru': 'https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip',
    'ar': 'https://alphacephei.com/vosk/models/vosk-model-ar-mgb2-0.4.zip',
    'ja': 'https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip',
    'ko': 'https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip',
    'zh': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'pt': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
    'tr': 'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip',
    'vi': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.4.zip',
    'it': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
    'nl': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
    'pl': 'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip',
    'uk': 'https://alphacephei.com/vosk/models/vosk-model-small-uk-v3-small.zip',
  };

  static const Map<String, String> _bcpToVosk = {
    'en': 'en', 'hi': 'hi', 'ta': 'ta', 'te': 'te', 'kn': 'kn',
    'fr': 'fr', 'de': 'de', 'es': 'es', 'ru': 'ru', 'ar': 'ar',
    'ja': 'ja', 'ko': 'ko', 'zh': 'zh', 'pt': 'pt', 'tr': 'tr',
    'vi': 'vi', 'it': 'it', 'nl': 'nl', 'pl': 'pl', 'uk': 'uk',
    'bn': 'en', 'gu': 'en', 'mr': 'en', 'ur': 'en',
    'th': 'en', 'id': 'en', 'sv': 'en',
  };

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _isListening = false;
  bool _isTtsSpeaking = false;  // ← NEW: tracks TTS state
  bool get isListening => _isListening;

  void Function(String text, bool isFinal)? _onResultCallback;

  // ── Called by home_screen before/after TTS speaks ─────────────────────────
  void setTtsSpeaking(bool speaking) {
    _isTtsSpeaking = speaking;
    debugPrint('VoskService: TTS speaking = $speaking');
  }

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (e) {
        debugPrint('VoskService speech error: $e');
        if (_isListening && !_isTtsSpeaking && _onResultCallback != null) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (_isListening && !_isTtsSpeaking) _restartListening();
          });
        }
      },
      onStatus: (status) {
        debugPrint('VoskService speech status: $status');
        if ((status == 'done' || status == 'notListening') &&
            _isListening && !_isTtsSpeaking) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_isListening && !_isTtsSpeaking) _restartListening();
          });
        }
      },
    );
    return _initialized;
  }

  void _restartListening() {
    if (!_isListening || _isTtsSpeaking || _onResultCallback == null) return;
    _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        _onResultCallback?.call(words, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: false,
        enableHapticFeedback: false,
        onDevice: true,
      ),
      localeId: 'en_IN',
    );
  }

  Future<bool> isModelDownloaded(String bcpCode) async {
    final code = _bcpToVosk[bcpCode.split('-').first] ?? 'en';
    final path = await _modelPath(code);
    return Directory(path).existsSync();
  }

  Future<void> downloadModel(String bcpCode, {void Function(double)? onProgress}) async {
    final code = _bcpToVosk[bcpCode.split('-').first] ?? 'en';
    final url = _modelUrls[code];
    if (url == null) return;

    final dir = await _modelsDir;
    final zipPath = '${dir.path}/$code.zip';
    final modelPath = '${dir.path}/$code';
    if (Directory(modelPath).existsSync()) return;

    try {
      onProgress?.call(0.05);
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final total = response.contentLength ?? 0;
      int received = 0;
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(0.05 + (received / total) * 0.65);
      }

      onProgress?.call(0.7);
      await File(zipPath).writeAsBytes(bytes);
      onProgress?.call(0.75);
      await _extractZip(zipPath, modelPath);
      onProgress?.call(1.0);

      final zf = File(zipPath);
      if (await zf.exists()) await zf.delete();
    } catch (e) {
      debugPrint('VoskService: Download failed for $code: $e');
      rethrow;
    }
  }

  Future<void> _extractZip(String zipPath, String destPath) async {
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final dest = Directory(destPath);
    if (!dest.existsSync()) dest.createSync(recursive: true);
    for (final file in archive) {
      final parts = file.name.split('/');
      final rel = parts.length > 1 ? parts.sublist(1).join('/') : file.name;
      if (rel.isEmpty) continue;
      final filePath = '$destPath/$rel';
      if (file.isFile) {
        final out = File(filePath);
        await out.create(recursive: true);
        await out.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }
  }

  Future<void> deleteModel(String bcpCode) async {
    final code = _bcpToVosk[bcpCode.split('-').first] ?? 'en';
    final path = await _modelPath(code);
    final dir = Directory(path);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String bcpCode = 'en',
  }) async {
    if (_isListening) await stopListening();
    if (!_initialized) await initialize();
    if (!_initialized) return;

    _isListening = true;
    _onResultCallback = onResult;

    _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        onResult(words, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: false,
        enableHapticFeedback: false,
        onDevice: true,
      ),
      localeId: 'en_IN',
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    _onResultCallback = null;
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('VoskService: Stop error: $e');
    }
  }

  Future<Directory> get _modelsDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/vosk_models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> _modelPath(String langCode) async {
    final dir = await _modelsDir;
    return '${dir.path}/$langCode';
  }

  static String voskCode(String bcpCode) =>
      _bcpToVosk[bcpCode.split('-').first] ?? 'en';

  static bool hasNativeModel(String bcpCode) {
    final code = bcpCode.split('-').first;
    return _modelUrls.containsKey(_bcpToVosk[code] ?? '');
  }
}