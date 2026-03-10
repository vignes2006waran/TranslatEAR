import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance => _instance ??= TranslationService._();
  TranslationService._();

  final _modelManager = OnDeviceTranslatorModelManager();
  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.4);

  // Cache of translators for each source language
  final Map<String, OnDeviceTranslator> _translators = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  TranslateLanguage _targetLang = TranslateLanguage.tamil;
  String _targetLangName = 'Tamil';
  TranslateLanguage get currentTargetLang => _targetLang;
  String get currentTargetLangName => _targetLangName;

  // BCP code to TranslateLanguage map for auto-detection
  static const Map<String, TranslateLanguage> _bcpToLang = {
    'af': TranslateLanguage.afrikaans,
    'sq': TranslateLanguage.albanian,
    'ar': TranslateLanguage.arabic,
    'be': TranslateLanguage.belarusian,
    'bn': TranslateLanguage.bengali,
    'bg': TranslateLanguage.bulgarian,
    'ca': TranslateLanguage.catalan,
    'zh': TranslateLanguage.chinese,
    'hr': TranslateLanguage.croatian,
    'cs': TranslateLanguage.czech,
    'da': TranslateLanguage.danish,
    'nl': TranslateLanguage.dutch,
    'en': TranslateLanguage.english,
    'eo': TranslateLanguage.esperanto,
    'et': TranslateLanguage.estonian,
    'fi': TranslateLanguage.finnish,
    'fr': TranslateLanguage.french,
    'gl': TranslateLanguage.galician,
    'ka': TranslateLanguage.georgian,
    'de': TranslateLanguage.german,
    'el': TranslateLanguage.greek,
    'gu': TranslateLanguage.gujarati,
    'he': TranslateLanguage.hebrew,
    'hi': TranslateLanguage.hindi,
    'hu': TranslateLanguage.hungarian,
    'is': TranslateLanguage.icelandic,
    'id': TranslateLanguage.indonesian,
    'ga': TranslateLanguage.irish,
    'it': TranslateLanguage.italian,
    'ja': TranslateLanguage.japanese,
    'kn': TranslateLanguage.kannada,
    'ko': TranslateLanguage.korean,
    'lv': TranslateLanguage.latvian,
    'lt': TranslateLanguage.lithuanian,
    'mk': TranslateLanguage.macedonian,
    'ms': TranslateLanguage.malay,
    'mt': TranslateLanguage.maltese,
    'mr': TranslateLanguage.marathi,
    'no': TranslateLanguage.norwegian,
    'fa': TranslateLanguage.persian,
    'pl': TranslateLanguage.polish,
    'pt': TranslateLanguage.portuguese,
    'ro': TranslateLanguage.romanian,
    'ru': TranslateLanguage.russian,
    'sk': TranslateLanguage.slovak,
    'sl': TranslateLanguage.slovenian,
    'es': TranslateLanguage.spanish,
    'sw': TranslateLanguage.swahili,
    'sv': TranslateLanguage.swedish,
    'tl': TranslateLanguage.tagalog,
    'ta': TranslateLanguage.tamil,
    'te': TranslateLanguage.telugu,
    'th': TranslateLanguage.thai,
    'tr': TranslateLanguage.turkish,
    'uk': TranslateLanguage.ukrainian,
    'ur': TranslateLanguage.urdu,
    'vi': TranslateLanguage.vietnamese,
    'cy': TranslateLanguage.welsh,
  };

  Future<bool> areModelsDownloaded() async {
    try {
      return await _modelManager.isModelDownloaded(_targetLang.bcpCode);
    } catch (e) {
      return false;
    }
  }

  Future<void> downloadModels({Function(double)? onProgress}) async {
    try {
      onProgress?.call(0.1);
      await _modelManager.downloadModel(_targetLang.bcpCode);
      onProgress?.call(1.0);
    } catch (e) {
      debugPrint('Model download error: $e');
      rethrow;
    }
  }

  Future<void> loadModels() async {
    _isLoaded = true;
    await _refreshDownloadedLocales();
    debugPrint('ML Kit translator ready! Target: $_targetLangName');
  }

  // Speech locale IDs for all downloaded language models
  List<String> _downloadedSpeechLocales = ['en-IN'];
  List<String> get downloadedSpeechLocales => _downloadedSpeechLocales;

  // Map from TranslateLanguage bcpCode to speech recognition locale
  static const Map<String, String> _bcpToSpeechLocale = {
    'af': 'af-ZA', 'sq': 'sq-AL', 'ar': 'ar-SA', 'bn': 'bn-IN',
    'bg': 'bg-BG', 'ca': 'ca-ES', 'zh': 'zh-CN', 'hr': 'hr-HR',
    'cs': 'cs-CZ', 'da': 'da-DK', 'nl': 'nl-NL', 'en': 'en-IN',
    'et': 'et-EE', 'fi': 'fi-FI', 'fr': 'fr-FR', 'de': 'de-DE',
    'el': 'el-GR', 'gu': 'gu-IN', 'he': 'iw-IL', 'hi': 'hi-IN',
    'hu': 'hu-HU', 'id': 'id-ID', 'it': 'it-IT', 'ja': 'ja-JP',
    'kn': 'kn-IN', 'ko': 'ko-KR', 'lv': 'lv-LV', 'lt': 'lt-LT',
    'ms': 'ms-MY', 'mr': 'mr-IN', 'no': 'nb-NO', 'fa': 'fa-IR',
    'pl': 'pl-PL', 'pt': 'pt-BR', 'ro': 'ro-RO', 'ru': 'ru-RU',
    'sk': 'sk-SK', 'sl': 'sl-SI', 'es': 'es-ES', 'sw': 'sw-KE',
    'sv': 'sv-SE', 'tl': 'fil-PH','ta': 'ta-IN', 'te': 'te-IN',
    'th': 'th-TH', 'tr': 'tr-TR', 'uk': 'uk-UA', 'ur': 'ur-PK',
    'vi': 'vi-VN', 'cy': 'cy-GB',
  };

  Future<void> _refreshDownloadedLocales() async {
    final locales = <String>[];
    for (final entry in _bcpToSpeechLocale.entries) {
      try {
        final downloaded = await _modelManager.isModelDownloaded(entry.key);
        if (downloaded) locales.add(entry.value);
      } catch (_) {}
    }
    // Always include English as fallback
    if (!locales.contains('en-IN')) locales.add('en-IN');
    _downloadedSpeechLocales = locales;
    debugPrint('Downloaded speech locales: $locales');
  }

  void setTargetLanguage(TranslateLanguage lang, String name) {
    if (_targetLang == lang) return;
    _targetLang = lang;
    _targetLangName = name;
    // Clear cached translators for new target
    for (final t in _translators.values) t.close();
    _translators.clear();
  }

  void reloadIfNeeded(TranslateLanguage lang) {
    if (_targetLang == lang) {
      for (final t in _translators.values) t.close();
      _translators.clear();
    }
  }

  // Get or create translator for a specific source language
  OnDeviceTranslator _getTranslator(TranslateLanguage sourceLang) {
    final key = sourceLang.bcpCode;
    if (!_translators.containsKey(key)) {
      _translators[key] = OnDeviceTranslator(
        sourceLanguage: sourceLang,
        targetLanguage: _targetLang,
      );
    }
    return _translators[key]!;
  }

  // BCP code → display name for UI
  static const Map<String, String> _bcpToName = {
    'en': 'English', 'ta': 'Tamil',   'hi': 'Hindi',    'te': 'Telugu',
    'kn': 'Kannada', 'ml': 'Malayalam','mr': 'Marathi',  'bn': 'Bengali',
    'gu': 'Gujarati','ur': 'Urdu',     'fr': 'French',   'de': 'German',
    'es': 'Spanish', 'it': 'Italian',  'pt': 'Portuguese','ru': 'Russian',
    'zh': 'Chinese', 'ja': 'Japanese', 'ko': 'Korean',   'ar': 'Arabic',
    'tr': 'Turkish', 'vi': 'Vietnamese','th': 'Thai',    'id': 'Indonesian',
    'ms': 'Malay',   'nl': 'Dutch',    'pl': 'Polish',   'sv': 'Swedish',
    'pa': 'Punjabi', 'si': 'Sinhala',  'ne': 'Nepali',   'sw': 'Swahili',
  };

  String _lastDetectedLangName = 'Auto';
  String get lastDetectedLangName => _lastDetectedLangName;

  // Rolling buffer — accumulates across sentences for better detection
  String _rollingBuffer = '';
  int _sentenceCount = 0;

  void clearDetectionBuffer() {
    // Only clear after enough sentences — keeps context for detection
    _sentenceCount++;
    if (_sentenceCount >= 3) {
      _rollingBuffer = '';
      _sentenceCount = 0;
    }
  }

  Future<String> translateOnMainThread(String text, {
    String sourceLang = 'eng_Latn',
    String targetLang = 'tam_Taml',
  }) async {
    if (text.trim().isEmpty) return '';
    try {
      // Build rolling buffer — more text = better detection accuracy
      _rollingBuffer = (_rollingBuffer + ' ' + text).trim();
      // Keep last 200 chars max for detection
      if (_rollingBuffer.length > 200) {
        _rollingBuffer = _rollingBuffer.substring(_rollingBuffer.length - 200);
      }

      // Run detection on rolling buffer for higher accuracy
      final candidates = await _languageIdentifier
          .identifyPossibleLanguages(_rollingBuffer);

      String detectedCode = 'en';
      double bestConf = 0.0;

      for (final c in candidates) {
        final base = c.languageTag.split('-').first;
        if (c.confidence > bestConf &&
            (_bcpToLang.containsKey(base) || _bcpToLang.containsKey(c.languageTag))) {
          bestConf = c.confidence;
          detectedCode = base;
        }
      }

      debugPrint('Lang detect: $detectedCode conf=${bestConf.toStringAsFixed(2)} buffer="$_rollingBuffer"');

      // Update display name
      _lastDetectedLangName = _bcpToName[detectedCode] ?? detectedCode.toUpperCase();

      // Get source language enum
      final sourceLangEnum = _bcpToLang[detectedCode] ?? TranslateLanguage.english;

      // Skip if source == native (person is speaking their own language)
      if (sourceLangEnum == _targetLang) {
        debugPrint('Source == Target, skipping');
        return '';
      }

      // Ensure model downloaded
      final downloaded = await _modelManager.isModelDownloaded(sourceLangEnum.bcpCode);
      if (!downloaded) {
        await _modelManager.downloadModel(sourceLangEnum.bcpCode);
      }

      final translator = _getTranslator(sourceLangEnum);
      final result = await translator.translateText(text);
      debugPrint('Translated: "$text" → "$result"');
      return result;

    } catch (e) {
      debugPrint('Translation error: $e');
      try {
        return await _getTranslator(TranslateLanguage.english).translateText(text);
      } catch (_) {
        return text;
      }
    }
  }

  void dispose() {
    for (final t in _translators.values) t.close();
    _translators.clear();
    _languageIdentifier.close();
    _isLoaded = false;
  }
}