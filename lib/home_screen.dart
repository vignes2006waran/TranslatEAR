import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vosk_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'sound_manager.dart';
import 'earbud_screen.dart';
import 'translation_service.dart';
import 'languages_screen.dart';
import 'app_theme.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

const _audioChannel = MethodChannel('audio_config');

class ConnectedEarbud {
  static String? name;
  static String? address;
}

class SelectedMic {
  static String type = 'phone';
  static String label = 'Phone Microphone';
  static String? bluetoothAddress;
}

class SelectedSpeaker {
  static String type = 'phone';
  static String label = 'Phone Speaker';
}

class TranslationHistory {
  static final List<Map<String, dynamic>> sessions = [];
  static void addSession(Map<String, dynamic> session) {
    sessions.insert(0, session);
  }
}

const _accent = Color(0xFF10A37F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isTranslating = false;
  String statusText = 'Ready to translate';
  String _detectedLangName = 'Auto';
  String _selectedSourceLang = 'English';
  int _currentNavIndex = 0;

  // ── Accumulated paragraph text ────────────────────────────────────────────
  String _originalParagraph = '';
  String _translatedParagraph = '';
  String _currentPartialOriginal = '';
  String _currentPartialTranslated = '';

  String get originalText => _currentPartialOriginal.isEmpty
      ? _originalParagraph
      : (_originalParagraph.isEmpty
      ? _currentPartialOriginal
      : '$_originalParagraph\n$_currentPartialOriginal');

  String get translatedText => _currentPartialTranslated.isEmpty
      ? _translatedParagraph
      : (_translatedParagraph.isEmpty
      ? _currentPartialTranslated
      : '$_translatedParagraph\n$_currentPartialTranslated');

  // ── Theme ─────────────────────────────────────────────────────────────────
  late AppTheme _t;
  bool get _isDark => _t.isDark;

  Color get bg      => _t.bg;
  Color get card    => _t.card;
  Color get bar     => _t.bar;
  Color get bdr     => _t.bdr;
  Color get bdr2    => _t.bdr2;
  Color get bdr3    => _t.bdr3;
  Color get txPri   => _t.txPri;
  Color get txMut   => _t.txMut;
  Color get txDead  => _t.txDead;
  Color get txDd2   => _t.txDd2;
  Color get navDead => _t.txNav;

  // ── Speech / TTS ──────────────────────────────────────────────────────────
  final VoskService _vosk = VoskService.instance;
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;

  String _lastSubmitted = '';
  String _lastTranslatedText = '';
  int _lastWordCount = 0;
  Timer? _wordDebounce;
  Timer? _silenceTimer;

  String get _currentLocaleId => 'en-IN';
  void _advanceLocale() {}
  void _lockLocale(String _) {}
  void _resetLocaleRotation() {}

  final ScrollController _origScrollController = ScrollController();
  final ScrollController _transScrollController = ScrollController();

  final List<Map<String, String>> _sessionConversations = [];
  DateTime? _sessionStart;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _textFadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;

  final List<double> _waveHeights = List.filled(36, 0.0);
  final Random _random = Random();

  String get nativeLangName =>
      TranslationService.instance.currentTargetLangName;

  @override
  void initState() {
    super.initState();
    _t = const AppTheme(true);
    _initAnimations();
    _initSpeech();
    _loadAndApplyNativeLanguage();
    _loadTheme();

    // ── TTS completion listener — resume mic after TTS finishes ──────────────
    _tts.setCompletionHandler(() {
      _vosk.setTtsSpeaking(false);
    });
    _tts.setErrorHandler((msg) {
      _vosk.setTtsSpeaking(false);
    });
  }

  static const Map<String, String> _speechLocaleMap = {
    'Tamil':      'ta-IN',
    'Hindi':      'hi-IN',
    'Telugu':     'te-IN',
    'Kannada':    'kn-IN',
    'Bengali':    'bn-IN',
    'Gujarati':   'gu-IN',
    'Marathi':    'mr-IN',
    'Urdu':       'ur-PK',
    'Arabic':     'ar-SA',
    'French':     'fr-FR',
    'German':     'de-DE',
    'Spanish':    'es-ES',
    'Italian':    'it-IT',
    'Portuguese': 'pt-BR',
    'Russian':    'ru-RU',
    'Japanese':   'ja-JP',
    'Korean':     'ko-KR',
    'Chinese':    'zh-CN',
    'Thai':       'th-TH',
    'Vietnamese': 'vi-VN',
    'Indonesian': 'id-ID',
    'Turkish':    'tr-TR',
    'Dutch':      'nl-NL',
    'Polish':     'pl-PL',
    'Swedish':    'sv-SE',
    'English':    'en-IN',
  };

  String get _nativeSpeechLocale =>
      _speechLocaleMap[nativeLangName] ?? 'en-IN';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode') ?? 'dark';
    final isDark = _resolvedIsDark(savedMode);
    if (mounted) setState(() => _t = AppTheme(isDark));
  }

  bool _resolvedIsDark(String mode) {
    if (mode == 'light') return false;
    if (mode == 'dark') return true;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  Future<void> _toggleTheme() async {
    final newDark = !_isDark;
    setState(() => _t = AppTheme(newDark));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newDark ? 'dark' : 'light');
    await prefs.setBool('is_dark_mode', newDark);
  }

  // ── Language / TTS ────────────────────────────────────────────────────────

  Future<void> _loadAndApplyNativeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('native_language') ?? 'Tamil';
    final langMap = {
      'Tamil': TranslateLanguage.tamil,
      'Hindi': TranslateLanguage.hindi,
      'Telugu': TranslateLanguage.telugu,
      'Kannada': TranslateLanguage.kannada,
      'Bengali': TranslateLanguage.bengali,
      'Gujarati': TranslateLanguage.gujarati,
      'Marathi': TranslateLanguage.marathi,
      'Urdu': TranslateLanguage.urdu,
      'Arabic': TranslateLanguage.arabic,
      'French': TranslateLanguage.french,
      'German': TranslateLanguage.german,
      'Spanish': TranslateLanguage.spanish,
      'Italian': TranslateLanguage.italian,
      'Portuguese': TranslateLanguage.portuguese,
      'Russian': TranslateLanguage.russian,
      'Japanese': TranslateLanguage.japanese,
      'Korean': TranslateLanguage.korean,
      'Chinese': TranslateLanguage.chinese,
      'Thai': TranslateLanguage.thai,
      'Vietnamese': TranslateLanguage.vietnamese,
      'Indonesian': TranslateLanguage.indonesian,
      'Turkish': TranslateLanguage.turkish,
      'Dutch': TranslateLanguage.dutch,
      'Polish': TranslateLanguage.polish,
      'Swedish': TranslateLanguage.swedish,
    };
    final lang = langMap[saved] ?? TranslateLanguage.tamil;
    TranslationService.instance.setTargetLanguage(lang, saved);
    await TranslationService.instance.loadModels();
    await _initTts();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _glowController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    _textFadeController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.07).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textFadeController, curve: Curves.easeIn));
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _speechAvailable = await _vosk.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    final ttsLangMap = {
      'Tamil': 'ta-IN',     'Hindi': 'hi-IN',   'Telugu': 'te-IN',
      'Kannada': 'kn-IN',   'Bengali': 'bn-IN',  'Gujarati': 'gu-IN',
      'Marathi': 'mr-IN',   'Urdu': 'ur-PK',     'Arabic': 'ar-SA',
      'French': 'fr-FR',    'German': 'de-DE',   'Spanish': 'es-ES',
      'Italian': 'it-IT',   'Portuguese': 'pt-BR','Russian': 'ru-RU',
      'Japanese': 'ja-JP',  'Korean': 'ko-KR',   'Chinese': 'zh-CN',
      'Thai': 'th-TH',      'Vietnamese': 'vi-VN','Indonesian': 'id-ID',
      'Turkish': 'tr-TR',   'Dutch': 'nl-NL',    'Polish': 'pl-PL',
      'Swedish': 'sv-SE',
    };
    final ttsLang = ttsLangMap[nativeLangName] ?? 'ta-IN';
    await _tts.setLanguage(ttsLang);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _textFadeController.dispose();
    _silenceTimer?.cancel();
    _vosk.stopListening();
    _tts.stop();
    SoundManager.dispose();
    super.dispose();
  }

  // ── Audio routing ─────────────────────────────────────────────────────────

  Future<void> _applyMicSelection() async {
    try {
      await _audioChannel.invokeMethod('setMic', {'type': SelectedMic.type});
      await _audioChannel.invokeMethod(
          'setSpeaker', {'type': SelectedSpeaker.type});
    } catch (e) {}
  }

  Future<void> _applySpeakerSelection() async {
    try {
      await _audioChannel.invokeMethod(
          'setSpeaker', {'type': SelectedSpeaker.type});
    } catch (e) {}
  }

  // ── Selector sheets ───────────────────────────────────────────────────────

  void _showMicSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSelectorSheet(
        ctx: ctx,
        title: 'Select Microphone',
        subtitle: 'Choose which microphone listens to your voice',
        icon: Icons.mic_rounded,
        selectedType: SelectedMic.type,
        phoneLabel: 'Phone Microphone',
        phoneSubtitle: 'Built-in device microphone',
        phoneIcon: Icons.smartphone_rounded,
        btIcon: Icons.headphones_rounded,
        onSelectPhone: () async {
          setState(() {
            SelectedMic.type = 'phone';
            SelectedMic.label = 'Phone Microphone';
            SelectedMic.bluetoothAddress = null;
          });
          await _applyMicSelection();
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onSelectBt: () async {
          setState(() {
            SelectedMic.type = 'bluetooth';
            SelectedMic.label = ConnectedEarbud.name!;
            SelectedMic.bluetoothAddress = ConnectedEarbud.address;
          });
          await _applyMicSelection();
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showSpeakerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSelectorSheet(
        ctx: ctx,
        title: 'Select Speaker',
        subtitle: 'Choose where the translation audio plays',
        icon: Icons.volume_up_rounded,
        selectedType: SelectedSpeaker.type,
        phoneLabel: 'Phone Speaker',
        phoneSubtitle: 'Built-in device speaker',
        phoneIcon: Icons.phone_android_rounded,
        btIcon: Icons.headphones_rounded,
        onSelectPhone: () async {
          setState(() {
            SelectedSpeaker.type = 'phone';
            SelectedSpeaker.label = 'Phone Speaker';
          });
          await _applySpeakerSelection();
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onSelectBt: () async {
          setState(() {
            SelectedSpeaker.type = 'bluetooth';
            SelectedSpeaker.label = ConnectedEarbud.name!;
          });
          await _applySpeakerSelection();
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildSelectorSheet({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required String selectedType,
    required String phoneLabel,
    required String phoneSubtitle,
    required IconData phoneIcon,
    required IconData btIcon,
    required VoidCallback onSelectPhone,
    required VoidCallback onSelectBt,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top:   BorderSide(color: bdr),
          left:  BorderSide(color: bdr),
          right: BorderSide(color: bdr),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: bdr3, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Icon(icon, color: _accent, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: txPri,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: txMut, fontSize: 12)),
            const SizedBox(height: 20),
            _selectorOption(
                icon: phoneIcon,
                title: phoneLabel,
                subtitle: phoneSubtitle,
                isSelected: selectedType == 'phone',
                onTap: onSelectPhone),
            const SizedBox(height: 10),
            if (ConnectedEarbud.name != null)
              _selectorOption(
                  icon: btIcon,
                  title: ConnectedEarbud.name!,
                  subtitle: ConnectedEarbud.address ?? 'Bluetooth device',
                  isSelected: selectedType == 'bluetooth',
                  onTap: onSelectBt,
                  isBluetooth: true)
            else
              _noBluetoothTile(ctx),
          ]),
    );
  }

  Widget _selectorOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isBluetooth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withOpacity(0.08) : card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? _accent.withOpacity(0.4) : bdr3,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: isSelected ? _accent.withOpacity(0.15) : _t.iconBg,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon,
                  color: isSelected ? _accent : txMut, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: isSelected ? txPri : txMut,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: txMut, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ])),
          const SizedBox(width: 8),
          AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _accent : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? _accent : bdr3, width: 1.5)),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 12)
                  : null),
        ]),
      ),
    );
  }

  Widget _noBluetoothTile(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bdr3)),
      child: Row(children: [
        Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: _t.iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.headphones_rounded, color: txDead, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('No Bluetooth Device',
                  style: TextStyle(
                      color: txDead, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Connect earbuds to see them here',
                  style: TextStyle(color: txDead, fontSize: 11)),
            ])),
        GestureDetector(
          onTap: () {
            Navigator.pop(ctx);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EarbudScreen()));
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withOpacity(0.2))),
              child: const Text('Connect',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600))),
        ),
      ]),
    );
  }

  // ── Translation logic ─────────────────────────────────────────────────────

  void _toggleTranslation() {
    if (!mounted) return;
    if (!isTranslating) {
      setState(() {
        isTranslating = true;
        statusText = 'Listening...';
        _detectedLangName = 'Auto';
        _originalParagraph = '';
        _resetLocaleRotation();
        _translatedParagraph = '';
        _currentPartialOriginal = '';
        _currentPartialTranslated = '';
        _sessionConversations.clear();
        _sessionStart = DateTime.now();
        _textFadeController.reset();
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
      });
      _startWave();
      SoundManager.playStartTune().then((_) {
        if (mounted && isTranslating) _startListening();
      });
    } else {
      setState(() {
        isTranslating = false;
        statusText = 'Ready to translate';
        _pulseController.stop();
        _pulseController.reset();
        _glowController.stop();
        _glowController.reset();
        for (int i = 0; i < _waveHeights.length; i++) _waveHeights[i] = 0.0;
      });
      _stopAll().then((_) => SoundManager.playStopTune());
      _saveSession();
    }
  }

  void _startWave() {
    if (!isTranslating || !mounted) return;
    setState(() {
      for (int i = 0; i < _waveHeights.length; i++) {
        _waveHeights[i] = _random.nextDouble() * 36 + 4;
      }
    });
    Future.delayed(const Duration(milliseconds: 110), _startWave);
  }

  Future<void> _startListening() async {
    if (!isTranslating || !mounted) return;

    if (!_speechAvailable) {
      _speechAvailable = await _vosk.initialize();
    }
    if (!_speechAvailable || !isTranslating || !mounted) return;

    _lastSubmitted = '';
    _lastTranslatedText = '';
    _lastWordCount = 0;
    TranslationService.instance.clearDetectionBuffer();

    await _vosk.startListening(
      bcpCode: 'en',
      onResult: (words, isFinal) {
        if (!mounted || !isTranslating) return;
        final text = words.trim();
        if (text.isEmpty) return;

        setState(() => _currentPartialOriginal = text);

        if (isFinal) {
          _wordDebounce?.cancel();
          if (text != _lastSubmitted && text.length > 1) {
            _lastSubmitted = text;
            _originalParagraph = _originalParagraph.isEmpty
                ? text
                : '$_originalParagraph\n$text';
            setState(() => _currentPartialOriginal = '');
            _translateFinalAndAppend(text);
            _sessionConversations.add({'original': text, 'translated': ''});
          } else {
            setState(() => _currentPartialOriginal = '');
          }
          _lastTranslatedText = '';
          _lastWordCount = 0;
        }
      },
    );
  }

  Future<void> _translatePartialLive(String text) async {
    if (!mounted || !isTranslating) return;
    try {
      final translation =
      await TranslationService.instance.translateOnMainThread(text);
      if (!mounted || !isTranslating) return;
      if (translation.isEmpty) return;
      final detected = TranslationService.instance.lastDetectedLangName;
      setState(() {
        _currentPartialTranslated = translation;
        _detectedLangName = detected;
        statusText = '$detected → $nativeLangName';
      });
      _textFadeController.reset();
      _textFadeController.forward();
    } catch (e) {}
  }

  // ── KEY METHOD: Translate final sentence + speak with TTS pause ───────────
  Future<void> _translateFinalAndAppend(String text) async {
    if (!mounted || !isTranslating) return;
    try {
      final translation =
      await TranslationService.instance.translateOnMainThread(text);
      if (!mounted || !isTranslating) return;

      if (translation.isEmpty) return;

      final detected = TranslationService.instance.lastDetectedLangName;

      _translatedParagraph = _translatedParagraph.isEmpty
          ? translation
          : '$_translatedParagraph\n$translation';

      setState(() {
        _currentPartialTranslated = '';
        _detectedLangName = detected;
        statusText = '$detected → $nativeLangName';
      });
      _textFadeController.reset();
      _textFadeController.forward();

      // Auto-scroll both boxes to bottom
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_origScrollController.hasClients) {
          _origScrollController.animateTo(
            _origScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        if (_transScrollController.hasClients) {
          _transScrollController.animateTo(
            _transScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // ── SPEAK: pause mic BEFORE TTS, resume AFTER via completion handler ──
      final ttsLangMap = {
        'Tamil': 'ta-IN',     'Hindi': 'hi-IN',   'Telugu': 'te-IN',
        'Kannada': 'kn-IN',   'Bengali': 'bn-IN',  'Gujarati': 'gu-IN',
        'Marathi': 'mr-IN',   'Urdu': 'ur-PK',     'Arabic': 'ar-SA',
        'French': 'fr-FR',    'German': 'de-DE',   'Spanish': 'es-ES',
        'Italian': 'it-IT',   'Portuguese': 'pt-BR','Russian': 'ru-RU',
        'Japanese': 'ja-JP',  'Korean': 'ko-KR',   'Chinese': 'zh-CN',
        'Thai': 'th-TH',      'Vietnamese': 'vi-VN','Indonesian': 'id-ID',
        'Turkish': 'tr-TR',   'Dutch': 'nl-NL',    'Polish': 'pl-PL',
        'Swedish': 'sv-SE',
      };
      await _tts.setLanguage(ttsLangMap[nativeLangName] ?? 'ta-IN');

      // Pause mic restarts during TTS playback to prevent error_busy spam
      _vosk.setTtsSpeaking(true);
      try {
        await _audioChannel.invokeMethod('resetAudioForTTS');
      } catch (e) {}
      await _tts.speak(translation);
      // Note: _vosk.setTtsSpeaking(false) is called via _tts.setCompletionHandler
      // set in initState — so mic resumes automatically when TTS finishes

    } catch (e) {
      // Make sure mic is never left paused on error
      _vosk.setTtsSpeaking(false);
    }
  }

  void _showSourceLanguagePicker() {
    final locales = TranslationService.instance.downloadedSpeechLocales;
    final downloaded = _speechLocaleMap.entries
        .where((e) => locales.contains(e.value))
        .map((e) => e.key)
        .where((name) => name != nativeLangName)
        .toList()
      ..sort();

    if (downloaded.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No languages downloaded. Go to Languages to download.'),
        backgroundColor: _accent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: bdr2, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Opposite person speaks',
                style: TextStyle(
                    color: txPri,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...downloaded.map((lang) => ListTile(
              leading: Icon(Icons.language_rounded,
                  color: lang == _selectedSourceLang ? _accent : txMut,
                  size: 20),
              title: Text(lang,
                  style: TextStyle(
                      color: lang == _selectedSourceLang ? _accent : txPri,
                      fontWeight: lang == _selectedSourceLang
                          ? FontWeight.w700
                          : FontWeight.normal)),
              trailing: lang == _selectedSourceLang
                  ? Icon(Icons.check_circle_rounded,
                  color: _accent, size: 20)
                  : null,
              onTap: () {
                setState(() => _selectedSourceLang = lang);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _stopAll() async {
    _silenceTimer?.cancel();
    _wordDebounce?.cancel();
    _vosk.setTtsSpeaking(false); // ensure mic flag is cleared on stop
    await _vosk.stopListening();
    try {
      await _tts.stop();
    } catch (e) {}
  }

  void _saveSession() {
    if (_sessionConversations.isEmpty) return;
    final now = _sessionStart ?? DateTime.now();
    final h = now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final dateStr = (now.day == today.day && now.month == today.month)
        ? 'Today'
        : (now.day == yesterday.day && now.month == yesterday.month)
        ? 'Yesterday'
        : '${now.day}/${now.month}/${now.year}';
    final allText =
    _sessionConversations.map((c) => c['original'] ?? '').join('. ');
    final summary =
    allText.length > 80 ? '${allText.substring(0, 80)}...' : allText;
    TranslationHistory.addSession({
      'date': dateStr,
      'time': '$h12:$m $period',
      'from': 'Auto',
      'to': nativeLangName,
      'summary': summary.isEmpty ? 'Translation session' : summary,
      'conversations': List<Map<String, String>>.from(_sessionConversations),
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (isTranslating)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (_, __) => Positioned(
                  top: -80,
                  left: MediaQuery.of(context).size.width / 2 - 130,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: _accent.withOpacity(
                                (_isDark ? 0.12 : 0.07) *
                                    _glowAnimation.value),
                            blurRadius: 120,
                            spreadRadius: 60),
                      ],
                    ),
                  ),
                ),
              ),

            SafeArea(
              child: Column(
                children: [
                  // ── TOP BAR ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(children: [
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _accent.withOpacity(0.25))),
                          child: const Icon(Icons.translate,
                              color: _accent, size: 18)),
                      const SizedBox(width: 10),
                      Text('TranslateAR',
                          style: TextStyle(
                              color: txPri,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleTheme,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: bar,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: bdr)),
                          child: Icon(
                              _isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: _isDark
                                  ? const Color(0xFFFFC107)
                                  : txMut,
                              size: 17),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _topBtn(
                          Icons.history_rounded,
                              () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryScreen()))),
                      const SizedBox(width: 8),
                      _topBtn(
                          Icons.settings_rounded,
                              () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()))),
                    ]),
                  ),
                  const SizedBox(height: 10),

                  // ── LANGUAGE BAR ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: bdr2)),
                      child: Row(
                        children: [
                          Icon(Icons.language_rounded,
                              color: _accent, size: 15),
                          const SizedBox(width: 8),
                          Text(_detectedLangName,
                              style: TextStyle(
                                  color: _detectedLangName == 'Auto'
                                      ? txMut
                                      : txPri,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded,
                              color: txMut, size: 14),
                          const SizedBox(width: 10),
                          Text(nativeLangName,
                              style: const TextStyle(
                                  color: _accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const LanguagesScreen()));
                              await TranslationService.instance.loadModels();
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _accent.withOpacity(0.25))),
                              child: Text('Manage',
                                  style: TextStyle(
                                      color: _accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── ORB + WAVE ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(
                                18,
                                    (i) => Flexible(
                                  child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 110),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      width: 2.5,
                                      height: isTranslating
                                          ? _waveHeights[i].clamp(4.0, 28.0)
                                          : 4.0,
                                      decoration: BoxDecoration(
                                          color: isTranslating
                                              ? _accent.withOpacity(
                                              0.3 + (i % 4) * 0.15)
                                              : bdr,
                                          borderRadius:
                                          BorderRadius.circular(2))),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (_, __) => Transform.scale(
                            scale:
                            isTranslating ? _pulseAnimation.value : 1.0,
                            child: GestureDetector(
                              onTap: _toggleTranslation,
                              child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isTranslating)
                                      AnimatedBuilder(
                                        animation: _glowAnimation,
                                        builder: (_, __) => Container(
                                          width: 110,
                                          height: 110,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: _accent.withOpacity(
                                                      (_isDark ? 0.25 : 0.15) *
                                                          _glowAnimation
                                                              .value),
                                                  width: 1)),
                                        ),
                                      ),
                                    Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: isTranslating
                                                    ? _accent.withOpacity(0.4)
                                                    : bdr,
                                                width: 1.5))),
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                            colors: isTranslating
                                                ? [
                                              const Color(0xFF12B589),
                                              const Color(0xFF0E9A72),
                                              const Color(0xFF0B7D5C),
                                            ]
                                                : _isDark
                                                ? [
                                              const Color(
                                                  0xFF1A1A2A),
                                              const Color(
                                                  0xFF111120),
                                              const Color(
                                                  0xFF0A0A15),
                                            ]
                                                : [
                                              const Color(
                                                  0xFFF2F2F2),
                                              const Color(
                                                  0xFFE8E8E8),
                                              const Color(
                                                  0xFFDDDDDD),
                                            ]),
                                        boxShadow: isTranslating
                                            ? [
                                          BoxShadow(
                                              color: _accent
                                                  .withOpacity(0.5),
                                              blurRadius: 24,
                                              spreadRadius: 2)
                                        ]
                                            : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(_isDark
                                                  ? 0.5
                                                  : 0.1),
                                              blurRadius: 12)
                                        ],
                                      ),
                                      child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                isTranslating
                                                    ? Icons.mic_rounded
                                                    : Icons.mic_none_rounded,
                                                size: 28,
                                                color: isTranslating
                                                    ? Colors.white
                                                    : txMut),
                                            const SizedBox(height: 3),
                                            Text(
                                                isTranslating
                                                    ? 'STOP'
                                                    : 'START',
                                                style: TextStyle(
                                                    color: isTranslating
                                                        ? Colors.white
                                                        .withOpacity(0.9)
                                                        : txMut,
                                                    fontSize: 9,
                                                    fontWeight:
                                                    FontWeight.w700,
                                                    letterSpacing: 1.2)),
                                          ]),
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(
                                18,
                                    (i) => Flexible(
                                  child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 110),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      width: 2.5,
                                      height: isTranslating
                                          ? _waveHeights[18 + i]
                                          .clamp(4.0, 28.0)
                                          : 4.0,
                                      decoration: BoxDecoration(
                                          color: isTranslating
                                              ? _accent.withOpacity(
                                              0.3 + (i % 4) * 0.15)
                                              : bdr,
                                          borderRadius:
                                          BorderRadius.circular(2))),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── STATUS ────────────────────────────────────────────────
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(statusText,
                        key: ValueKey(statusText),
                        style: TextStyle(
                            color: isTranslating ? _accent : txMut,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),

                  // ── TEXT CARD ─────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isTranslating
                                    ? _accent.withOpacity(0.2)
                                    : bdr2),
                            boxShadow: _t.cardShadow),
                        child: Column(children: [
                          // ORIGINAL
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: originalText.isNotEmpty
                                                  ? txPri
                                                  : bdr)),
                                      const SizedBox(width: 8),
                                      Text('ORIGINAL',
                                          style: TextStyle(
                                              color: txMut,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.5)),
                                    ]),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: _origScrollController,
                                        child: Text(
                                            originalText.isEmpty
                                                ? (isTranslating
                                                ? 'Listening...'
                                                : 'Tap the orb to begin')
                                                : originalText,
                                            style: TextStyle(
                                                color: originalText.isEmpty
                                                    ? txDead
                                                    : txPri.withOpacity(0.85),
                                                fontSize: 17,
                                                height: 1.7)),
                                      ),
                                    ),
                                  ]),
                            ),
                          ),

                          Container(
                              height: 1,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    _accent.withOpacity(0.35),
                                    Colors.transparent,
                                  ]))),

                          // TRANSLATION
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: translatedText.isNotEmpty
                                                  ? _accent
                                                  : bdr)),
                                      const SizedBox(width: 8),
                                      const Text('TRANSLATION',
                                          style: TextStyle(
                                              color: _accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.5)),
                                      const Spacer(),
                                      if (translatedText.isNotEmpty)
                                        GestureDetector(
                                          onTap: () async {
                                            await _tts.speak(translatedText);
                                          },
                                          child: Container(
                                              padding:
                                              const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                  color: _accent
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      8)),
                                              child: const Icon(
                                                  Icons.volume_up_rounded,
                                                  color: _accent,
                                                  size: 14)),
                                        ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        controller: _transScrollController,
                                        child: FadeTransition(
                                          opacity: translatedText.isNotEmpty
                                              ? _textFadeAnimation
                                              : const AlwaysStoppedAnimation(
                                              1),
                                          child: Text(
                                              translatedText.isEmpty
                                                  ? (isTranslating
                                                  ? 'Translation will appear here...'
                                                  : '')
                                                  : translatedText,
                                              style: TextStyle(
                                                  color:
                                                  translatedText.isEmpty
                                                      ? txDead
                                                      : txPri,
                                                  fontSize: 19,
                                                  height: 1.7,
                                                  fontWeight:
                                                  FontWeight.w500)),
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── BOTTOM NAV ────────────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: bdr2),
                        boxShadow: _t.cardShadow),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(Icons.translate_rounded, 'Translate', 0),
                          _navItem(Icons.history_rounded, 'History', 1),
                          _navItem(Icons.language_rounded, 'Languages', 2),
                          _navItem(Icons.person_rounded, 'Profile', 3),
                        ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _deviceSelectorBar({
    required IconData icon,
    required String topLabel,
    required String valueLabel,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: bar,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isActive ? _accent.withOpacity(0.35) : bdr),
            boxShadow: _t.barShadow),
        child: Row(children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: _accent, size: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topLabel,
                        style: TextStyle(
                            color: txMut,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4)),
                    const SizedBox(height: 2),
                    Text(valueLabel,
                        style: TextStyle(
                            color: txPri,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ])),
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTranslating ? _accent : txDead)),
          const SizedBox(width: 8),
          Text('Change', style: TextStyle(color: txMut, fontSize: 11)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, color: txMut, size: 16),
        ]),
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: bar,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bdr)),
          child: Icon(icon, color: navDead, size: 17)));

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()));
        } else if (index == 2) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LanguagesScreen()));
        } else if (index == 3) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
            color:
            isActive ? _accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(13)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isActive ? _accent : txDd2, size: 21),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: isActive ? _accent : txDd2,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}