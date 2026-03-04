import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'sound_manager.dart';
import 'earbud_screen.dart';

// ── Global audio channel ──────────────────────────────────────────────────────
const _audioChannel = MethodChannel('audio_config');

// Global earbud state
class ConnectedEarbud {
  static String? name;
  static String? address;
}

// Global selected mic state
class SelectedMic {
  static String type = 'phone'; // 'phone' or 'bluetooth'
  static String label = 'Phone Microphone';
  static String? bluetoothAddress;
}

// Global selected speaker state
class SelectedSpeaker {
  static String type = 'phone'; // 'phone' or 'bluetooth'
  static String label = 'Phone Speaker';
}

// ─── Global history ───────────────────────────────────────────────────────────
class TranslationHistory {
  static final List<Map<String, dynamic>> sessions = [];
  static void addSession(Map<String, dynamic> session) {
    sessions.insert(0, session);
  }
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isTranslating = false;
  String statusText = 'Ready to translate';
  String originalText = '';
  String translatedText = '';
  int _currentNavIndex = 0;

  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;

  final List<String> _queue = [];
  bool _processingQueue = false;
  String _lastSubmitted = '';
  String _currentPartial = '';
  Timer? _silenceTimer;

  final List<Map<String, String>> _sessionConversations = [];
  DateTime? _sessionStart;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _textFadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;

  final List<double> _waveHeights = List.filled(28, 0.0);
  final Random _random = Random();

  static const _volumeChannel = EventChannel('volume_button_events');
  StreamSubscription? _volumeSubscription;
  StreamSubscription? _shakeSubscription;
  DateTime? _lastShake;

  final String backendUrl = 'http://192.168.1.12:8000';
  final String nativeLanguage = 'tam_Taml';
  final String nativeLangName = 'Tamil';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSpeech();
    _initTts();
    _listenVolume();
    _listenShake();
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
    _speechAvailable =
    await _speech.initialize(onError: (e) => print('Speech error: $e'));
    setState(() {});
  }

  Future<void> _initTts() async {
    final languages = await _tts.getLanguages;
    bool tamilAvailable = false;
    if (languages != null) {
      for (var lang in languages) {
        if (lang.toString().toLowerCase().contains('ta')) {
          tamilAvailable = true;
          break;
        }
      }
    }
    await _tts.setLanguage(tamilAvailable ? 'ta-IN' : 'en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  void _listenVolume() {
    try {
      _volumeSubscription =
          _volumeChannel.receiveBroadcastStream().listen((event) {
            if (event == 'volume_double_press') _toggleTranslation();
          });
    } catch (e) {
      print('Volume error: $e');
    }
  }

  void _listenShake() {
    try {
      _shakeSubscription = accelerometerEventStream().listen((event) {
        final acc = event.x.abs() + event.y.abs() + event.z.abs();
        if (acc > 25.0) {
          final now = DateTime.now();
          if (_lastShake == null || now.difference(_lastShake!).inSeconds > 2) {
            _lastShake = now;
            _toggleTranslation();
          }
        }
      });
    } catch (e) {
      print('Shake error: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _textFadeController.dispose();
    _silenceTimer?.cancel();
    _queue.clear();
    _speech.stop();
    _tts.stop();
    _volumeSubscription?.cancel();
    _shakeSubscription?.cancel();
    SoundManager.dispose();
    super.dispose();
  }

  // ── Audio routing helpers ─────────────────────────────────────────────────

  /// Call this when mic selection changes
  Future<void> _applyMicSelection() async {
    try {
      await _audioChannel.invokeMethod('setMic', {'type': SelectedMic.type});
      if (isTranslating) await _prepareForListening();
    } catch (e) {
      print('Mic selection error: $e');
    }
  }

  Future<void> _applySpeakerSelection() async {
    try {
      await _audioChannel.invokeMethod('setSpeaker', {'type': SelectedSpeaker.type});
    } catch (e) {
      print('Speaker selection error: $e');
    }
  }

  /// Call just before speech recognition starts — routes mic correctly
  Future<void> _prepareForListening() async {
    try {
      await _audioChannel.invokeMethod('prepareForListening');
    } catch (e) {
      print('prepareForListening error: $e');
    }
  }

  /// Call just before TTS speaks — routes speaker correctly
  Future<void> _prepareForSpeaking() async {
    try {
      await _audioChannel.invokeMethod('prepareForSpeaking');
    } catch (e) {
      print('prepareForSpeaking error: $e');
    }
  }

  // ── Mic selector bottom sheet ─────────────────────────────────────────────
  void _showMicSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _buildSelectorSheet(
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
      ),
    );
  }

  // ── Speaker selector bottom sheet ─────────────────────────────────────────
  void _showSpeakerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => _buildSelectorSheet(
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
      ),
    );
  }

  // ── Reusable bottom sheet ─────────────────────────────────────────────────
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
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E2E)),
          left: BorderSide(color: Color(0xFF1E1E2E)),
          right: BorderSide(color: Color(0xFF1E1E2E)),
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
                  color: const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Icon(icon, color: const Color(0xFF10A37F), size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3)),
          ]),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Color(0xFF444460), fontSize: 12)),
          const SizedBox(height: 20),

          // Phone option
          _selectorOption(
            icon: phoneIcon,
            title: phoneLabel,
            subtitle: phoneSubtitle,
            isSelected: selectedType == 'phone',
            onTap: onSelectPhone,
          ),
          const SizedBox(height: 10),

          // Bluetooth option
          if (ConnectedEarbud.name != null) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
              child: Text('BLUETOOTH DEVICES',
                  style: TextStyle(
                      color: Color(0xFF444460),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ),
            _selectorOption(
              icon: btIcon,
              title: ConnectedEarbud.name!,
              subtitle: ConnectedEarbud.address ?? 'Bluetooth device',
              isSelected: selectedType == 'bluetooth',
              onTap: onSelectBt,
              isBluetooth: true,
            ),
          ] else
            _noBluetoothTile(ctx),
        ],
      ),
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
          color: isSelected
              ? const Color(0xFF10A37F).withOpacity(0.08)
              : const Color(0xFF0C0C18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10A37F).withOpacity(0.4)
                : const Color(0xFF1A1A2A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10A37F).withOpacity(0.15)
                    : const Color(0xFF1A1A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? const Color(0xFF10A37F)
                      : const Color(0xFF444460),
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color:
                          isSelected ? Colors.white : const Color(0xFF888899),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                      const TextStyle(color: Color(0xFF444460), fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF10A37F)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF10A37F)
                      : const Color(0xFF2A2A3A),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _noBluetoothTile(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A1A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A2A),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.headphones_rounded,
                color: Color(0xFF2A2A3A), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Bluetooth Device',
                    style: TextStyle(
                        color: Color(0xFF2A2A3A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Connect earbuds to see them here',
                    style: TextStyle(color: Color(0xFF1E1E2E), fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EarbudScreen()));
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF10A37F).withOpacity(0.2)),
              ),
              child: const Text('Connect',
                  style: TextStyle(
                      color: Color(0xFF10A37F),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle translation ─────────────────────────────────────────────────────
  void _toggleTranslation() {
    if (!mounted) return;
    setState(() {
      isTranslating = !isTranslating;
      if (isTranslating) {
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        statusText = 'Listening...';
        originalText = '';
        translatedText = '';
        _sessionConversations.clear();
        _sessionStart = DateTime.now();
        _textFadeController.reset();
        SoundManager.playStartTune();
        _startWave();
        _startListening();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _glowController.stop();
        _glowController.reset();
        statusText = 'Ready to translate';
        SoundManager.playStopTune();
        _stopAll();
        _saveSession();
        for (int i = 0; i < _waveHeights.length; i++) _waveHeights[i] = 0.0;
      }
    });
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

  // ── Listening ─────────────────────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!isTranslating || !mounted) return;

    // 1. Route audio to correct mic BEFORE initializing speech
    await _prepareForListening();

    try {
      await _speech.cancel();
      await _speech.stop();
    } catch (e) {}

    await Future.delayed(const Duration(milliseconds: 800));
    if (!isTranslating || !mounted) return;

    _speechAvailable = await _speech.initialize(
      onError: (e) {
        print('Speech error: $e');
        if (mounted && isTranslating) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && isTranslating) _startListening();
          });
        }
      },
    );

    if (!_speechAvailable || !isTranslating || !mounted) return;
    _lastSubmitted = '';
    _currentPartial = '';

    await _speech.listen(
      onResult: (result) {
        if (!mounted || !isTranslating) return;
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        setState(() => originalText = words);
        _currentPartial = words;
        _silenceTimer?.cancel();

        if (result.finalResult) {
          _submitForTranslation(words);
        } else if (_isSentenceEnd(words)) {
          _submitForTranslation(words);
        } else {
          _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
            if (!mounted || !isTranslating) return;
            if (_currentPartial.isNotEmpty &&
                _currentPartial != _lastSubmitted) {
              _submitForTranslation(_currentPartial);
            }
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions:
      SpeechListenOptions(partialResults: true, cancelOnError: false),
      localeId: 'en_US',
    );

    _speech.statusListener = (status) {
      if (!mounted || !isTranslating) return;
      if (status == 'done' || status == 'notListening') {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && isTranslating) _startListening();
        });
      }
    };
  }

  bool _isSentenceEnd(String text) {
    final t = text.trimRight();
    return t.endsWith('.') ||
        t.endsWith('!') ||
        t.endsWith('?') ||
        t.endsWith('...') ||
        t.endsWith(',') ||
        t.endsWith(';');
  }

  void _submitForTranslation(String text) {
    if (text.trim().isEmpty || text == _lastSubmitted) return;
    _lastSubmitted = text;
    _currentPartial = '';
    setState(() => originalText = text);
    _queue.add(text);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_processingQueue) return;
    _processingQueue = true;
    while (_queue.isNotEmpty && isTranslating && mounted) {
      final text = _queue.removeAt(0);
      await _translateAndSpeak(text);
      if (_queue.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    _processingQueue = false;
    if (mounted && isTranslating) setState(() => statusText = 'Listening...');
  }

  Future<void> _stopAll() async {
    _silenceTimer?.cancel();
    _queue.clear();
    _processingQueue = false;
    _speech.statusListener = null;
    await _speech.stop();
    await _tts.stop();
  }

  // ── Translate + speak ──────────────────────────────────────────────────────
  Future<void> _translateAndSpeak(String text) async {
    if (!mounted || !isTranslating) return;
    setState(() => statusText = 'Translating...');

    try {
      final response = await http
          .post(
        Uri.parse('$backendUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source_lang': 'eng_Latn',
          'target_lang': nativeLanguage,
        }),
      )
          .timeout(const Duration(seconds: 60));

      if (!mounted || !isTranslating) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translation = data['translation'] as String;

        _sessionConversations
            .add({'original': text, 'translated': translation});
        setState(() {
          translatedText = translation;
          statusText = 'English → $nativeLangName';
          originalText = '';
        });
        _textFadeController.reset();
        _textFadeController.forward();

        // 2. Route audio to correct speaker BEFORE speaking
        await _prepareForSpeaking();
        await _tts.speak(translation);
        // After TTS done, restore mic routing
        await _audioChannel.invokeMethod('restoreAfterSpeaking');

      } else {
        setState(() => statusText = 'Error ${response.statusCode}');
      }
    } on TimeoutException {
      if (mounted) setState(() => statusText = 'Timeout — retrying...');
    } catch (e) {
      if (mounted) {
        setState(() {
          statusText = 'Backend not reachable';
          translatedText = 'Make sure Python server is running';
        });
      }
    }
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
      'from': 'English',
      'to': nativeLangName,
      'summary': summary.isEmpty ? 'Translation session' : summary,
      'conversations': List<Map<String, String>>.from(_sessionConversations),
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          if (isTranslating)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (_, __) => Positioned(
                top: -80,
                left: MediaQuery.of(context).size.width / 2 - 130,
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10A37F)
                            .withOpacity(0.12 * _glowAnimation.value),
                        blurRadius: 120,
                        spreadRadius: 60,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10A37F).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF10A37F).withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.translate,
                            color: Color(0xFF10A37F), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text('TranslateAR',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5)),
                      const Spacer(),
                      _topBtn(Icons.history_rounded, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HistoryScreen()));
                      }),
                      const SizedBox(width: 8),
                      _topBtn(Icons.settings_rounded, () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()));
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Mic + Speaker selectors ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _deviceSelectorBar(
                        icon: SelectedMic.type == 'bluetooth'
                            ? Icons.headphones_rounded
                            : Icons.smartphone_rounded,
                        topLabel: 'MICROPHONE',
                        valueLabel: SelectedMic.label,
                        isActive: SelectedMic.type == 'bluetooth',
                        onTap: _showMicSelector,
                      ),
                      const SizedBox(height: 8),
                      _deviceSelectorBar(
                        icon: SelectedSpeaker.type == 'bluetooth'
                            ? Icons.headphones_rounded
                            : Icons.phone_android_rounded,
                        topLabel: 'SPEAKER',
                        valueLabel: SelectedSpeaker.label,
                        isActive: SelectedSpeaker.type == 'bluetooth',
                        onTap: _showSpeakerSelector,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Orb ──
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Transform.scale(
                    scale: isTranslating ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: _toggleTranslation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isTranslating)
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (_, __) => Container(
                                width: 215, height: 215,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF10A37F).withOpacity(
                                        0.25 * _glowAnimation.value),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            width: 188, height: 188,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isTranslating
                                    ? const Color(0xFF10A37F).withOpacity(0.4)
                                    : const Color(0xFF1E1E2E),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 158, height: 158,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: isTranslating
                                    ? [
                                  const Color(0xFF12B589),
                                  const Color(0xFF0E9A72),
                                  const Color(0xFF0B7D5C),
                                ]
                                    : [
                                  const Color(0xFF1A1A2A),
                                  const Color(0xFF111120),
                                  const Color(0xFF0A0A15),
                                ],
                              ),
                              boxShadow: isTranslating
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFF10A37F)
                                      .withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                )
                              ]
                                  : [
                                BoxShadow(
                                    color:
                                    Colors.black.withOpacity(0.5),
                                    blurRadius: 20)
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isTranslating
                                      ? Icons.mic_rounded
                                      : Icons.mic_none_rounded,
                                  size: 50,
                                  color: isTranslating
                                      ? Colors.white
                                      : const Color(0xFF444460),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isTranslating ? 'LISTENING' : 'TAP TO START',
                                  style: TextStyle(
                                    color: isTranslating
                                        ? Colors.white.withOpacity(0.9)
                                        : const Color(0xFF444460),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Status ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: TextStyle(
                      color: isTranslating
                          ? const Color(0xFF10A37F)
                          : const Color(0xFF444460),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Wave ──
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_waveHeights.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 110),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 3,
                        height: isTranslating
                            ? _waveHeights[i].clamp(4.0, 36.0)
                            : 4.0,
                        decoration: BoxDecoration(
                          color: isTranslating
                              ? const Color(0xFF10A37F)
                              .withOpacity(0.3 + (i % 4) * 0.15)
                              : const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Translation panel ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0C18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isTranslating
                              ? const Color(0xFF10A37F).withOpacity(0.2)
                              : const Color(0xFF141425),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Original
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: originalText.isNotEmpty
                                            ? Colors.white
                                            : const Color(0xFF1E1E2E),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('ORIGINAL',
                                        style: TextStyle(
                                            color: Color(0xFF444460),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5)),
                                  ]),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        originalText.isEmpty
                                            ? (isTranslating
                                            ? 'Listening...'
                                            : 'Tap the orb to begin')
                                            : originalText,
                                        style: TextStyle(
                                          color: originalText.isEmpty
                                              ? const Color(0xFF2A2A3A)
                                              : Colors.white.withOpacity(0.85),
                                          fontSize: 15,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                const Color(0xFF10A37F).withOpacity(0.35),
                                Colors.transparent,
                              ]),
                            ),
                          ),

                          // Translation
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: translatedText.isNotEmpty
                                            ? const Color(0xFF10A37F)
                                            : const Color(0xFF1E1E2E),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('TRANSLATION',
                                        style: TextStyle(
                                            color: Color(0xFF10A37F),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5)),
                                    const Spacer(),
                                    if (translatedText.isNotEmpty)
                                      GestureDetector(
                                        onTap: () async {
                                          // Replay respects speaker selection
                                          await _prepareForSpeaking();
                                          await _tts.speak(translatedText);
                                          await _prepareForListening();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10A37F)
                                                .withOpacity(0.1),
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.volume_up_rounded,
                                              color: Color(0xFF10A37F),
                                              size: 14),
                                        ),
                                      ),
                                  ]),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: FadeTransition(
                                        opacity: translatedText.isNotEmpty
                                            ? _textFadeAnimation
                                            : const AlwaysStoppedAnimation(1),
                                        child: Text(
                                          translatedText.isEmpty
                                              ? (isTranslating
                                              ? 'Translation will appear here...'
                                              : '')
                                              : translatedText,
                                          style: TextStyle(
                                            color: translatedText.isEmpty
                                                ? const Color(0xFF2A2A3A)
                                                : Colors.white,
                                            fontSize: 17,
                                            height: 1.6,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Bottom nav ──
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0C18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF141425)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(Icons.translate_rounded, 'Translate', 0),
                      _navItem(Icons.history_rounded, 'History', 1),
                      _navItem(Icons.person_rounded, 'Profile', 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          color: const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF10A37F).withOpacity(0.35)
                : const Color(0xFF1E1E2E),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: const Color(0xFF10A37F), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topLabel,
                      style: const TextStyle(
                          color: Color(0xFF444460),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 2),
                  Text(valueLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTranslating
                    ? const Color(0xFF10A37F)
                    : const Color(0xFF2A2A3A),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Change',
                style: TextStyle(color: Color(0xFF444460), fontSize: 11)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF444460), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Icon(icon, color: const Color(0xFF555570), size: 17),
    ),
  );

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
              MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF10A37F).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? const Color(0xFF10A37F)
                    : const Color(0xFF2E2E45),
                size: 21),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: isActive
                        ? const Color(0xFF10A37F)
                        : const Color(0xFF2E2E45),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}