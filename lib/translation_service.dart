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
    debugPrint('ML Kit translator ready! Target: $_targetLangName');
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

  Future<String> translateOnMainThread(String text, {
    String sourceLang = 'eng_Latn',
    String targetLang = 'tam_Taml',
  }) async {
    if (text.trim().isEmpty) return '';
    try {
      // Step 1: Auto-detect language
      final detectedCode = await _languageIdentifier.identifyLanguage(text);
      debugPrint('Detected language: $detectedCode');

      // Step 2: Get source TranslateLanguage
      TranslateLanguage sourceLangEnum = TranslateLanguage.english; // default
      if (detectedCode != 'und' && _bcpToLang.containsKey(detectedCode)) {
        sourceLangEnum = _bcpToLang[detectedCode]!;
      }

      // Step 3: If source == target, skip translation
      if (sourceLangEnum == _targetLang) {
        debugPrint('Source == Target, skipping translation');
        return text;
      }

      // Step 4: Check if source model is downloaded (needed for translation)
      final sourceDownloaded = await _modelManager.isModelDownloaded(sourceLangEnum.bcpCode);
      if (!sourceDownloaded) {
        // Download source model silently
        await _modelManager.downloadModel(sourceLangEnum.bcpCode);
      }

      // Step 5: Translate
      final translator = _getTranslator(sourceLangEnum);
      final result = await translator.translateText(text);
      debugPrint('Translated ($detectedCode → ${_targetLang.bcpCode}): "$text" → "$result"');
      return result;

    } catch (e) {
      debugPrint('Translation error: $e');
      // Fallback: try English → target
      try {
        final fallback = _getTranslator(TranslateLanguage.english);
        return await fallback.translateText(text);
      } catch (e2) {
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