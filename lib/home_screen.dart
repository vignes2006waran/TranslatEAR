import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  bool isTranslating = false;
  String detectedLanguage = 'Waiting...';
  String originalText = '';
  String translatedText = '';
  bool isListening = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final String backendUrl = 'http://192.168.1.12:8000';
  final String nativeLanguage = 'tam_Taml';

  // Volume button channel
  static const _volumeChannel = EventChannel('volume_button_events');
  StreamSubscription? _volumeSubscription;

  // Shake detection
  StreamSubscription? _shakeSubscription;
  final double _shakeThreshold = 25.0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _listenVolumeButton();
    _listenShake();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _playBeep(bool isStarting) async {
    if (isStarting) {
      // Double beep = starting
      await _audioPlayer.play(AssetSource('sounds/beep_start.mp3'));
    } else {
      // Single low beep = stopping
      await _audioPlayer.play(AssetSource('sounds/beep_stop.mp3'));
    }
  }
  Future<void> _initSpeech() async {
    await Permission.microphone.request();
    _speechAvailable = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  // Listen for volume button hold (3 seconds)
  void _listenVolumeButton() {
    try {
      _volumeSubscription = _volumeChannel
          .receiveBroadcastStream()
          .listen((event) {
        if (event == 'volume_double_press') {
          _toggleTranslation();
        }
      });
    } catch (e) {
      print('Volume button error: $e');
    }
  }

  // Listen for shake
  void _listenShake() {
    try {
      _shakeSubscription = accelerometerEventStream().listen((event) {
        double acceleration =
            event.x.abs() + event.y.abs() + event.z.abs();
        if (acceleration > _shakeThreshold) {
          final now = DateTime.now();
          if (_lastShakeTime == null ||
              now.difference(_lastShakeTime!).inSeconds > 2) {
            _lastShakeTime = now;
            _toggleTranslation();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isTranslating
                        ? '🎙️ Translation Started!'
                        : '⏹️ Translation Stopped!',
                  ),
                  backgroundColor: const Color(0xFF10A37F),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
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
    _speech.stop();
    _volumeSubscription?.cancel();
    _shakeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _toggleTranslation() {
    setState(() {
      isTranslating = !isTranslating;
      if (isTranslating) {
        _pulseController.repeat(reverse: true);
        detectedLanguage = 'Listening...';
        originalText = '';
        translatedText = '';
        _playBeep(true);   // Play start beep
        _startListening();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        detectedLanguage = 'Waiting...';
        _playBeep(false);  // Play stop beep
        _stopListening();
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;

    await _speech.listen(
      onResult: (result) async {
        setState(() {
          originalText = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          await _translateText(result.recognizedWords);
          if (isTranslating) {
            _startListening();
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      listenOptions: SpeechListenOptions(partialResults: true),
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
  }

  Future<void> _translateText(String text) async {
    setState(() {
      detectedLanguage = 'Translating...';
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'source_lang': 'eng_Latn',
          'target_lang': nativeLanguage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translation = data['translation'];

        setState(() {
          translatedText = translation;
          detectedLanguage = 'English → Tamil';
        });

        await _tts.speak(translation);
      }
    } catch (e) {
      setState(() {
        detectedLanguage = 'Error connecting to server';
        translatedText = 'Make sure Python backend is running!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'TranslateAR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTranslating
                      ? const Color(0xFF10A37F)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.headphones,
                    color: isTranslating
                        ? const Color(0xFF10A37F)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTranslating ? 'Translating...' : 'Inactive',
                        style: TextStyle(
                          color: isTranslating
                              ? const Color(0xFF10A37F)
                              : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        detectedLanguage,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTranslating
                          ? const Color(0xFF10A37F)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),


            // Big Activate Button
            ScaleTransition(
              scale: isTranslating
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTap: _toggleTranslation,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTranslating
                        ? const Color(0xFF10A37F)
                        : const Color(0xFF2A2A2A),
                    border: Border.all(
                      color: const Color(0xFF10A37F),
                      width: 3,
                    ),
                    boxShadow: isTranslating
                        ? [
                      BoxShadow(
                        color: const Color(0xFF10A37F).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTranslating ? Icons.mic : Icons.mic_none,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTranslating ? 'TAP TO STOP' : 'TAP TO START',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Translation Display
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Original',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      originalText.isEmpty
                          ? isTranslating
                          ? 'Listening to speech...'
                          : 'Tap the button to start'
                          : originalText,
                      style: TextStyle(
                        color: originalText.isEmpty
                            ? Colors.grey
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 30),
                    const Text(
                      'Translation',
                      style: TextStyle(
                        color: Color(0xFF10A37F),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translatedText.isEmpty
                          ? isTranslating
                          ? 'Translation will appear here...'
                          : ''
                          : translatedText,
                      style: TextStyle(
                        color: translatedText.isEmpty
                            ? Colors.grey
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: const Color(0xFF10A37F),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Translate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }


}
