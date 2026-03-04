import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();

  // Voice
  double voiceSpeed = 0.5;
  double voiceVolume = 1.0;
  double voicePitch = 1.0;

  // Translation
  bool autoDetect = true;

  // ANC
  bool ancEnabled = false;

  // Activation
  bool inAppButton = true;
  bool shakeToActivate = false;
  bool voiceCommand = false;
  bool doubleTapEarbud = false;
  bool wearDetection = false;
  bool autoActivate = false;
  bool scheduleActivate = false;
  bool volumeDoubleClick = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ta-IN');
    await _tts.setSpeechRate(voiceSpeed);
    await _tts.setVolume(voiceVolume);
    await _tts.setPitch(voicePitch);
  }

  Future<void> _previewVoice() async {
    await _tts.setSpeechRate(voiceSpeed);
    await _tts.setVolume(voiceVolume);
    await _tts.setPitch(voicePitch);
    await _tts.speak('வணக்கம், இது ஒரு சோதனை குரல்');
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    // Apply TTS settings
    await _tts.setSpeechRate(voiceSpeed);
    await _tts.setVolume(voiceVolume);
    await _tts.setPitch(voicePitch);

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Settings saved!'),
            ],
          ),
          backgroundColor: const Color(0xFF10A37F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E1E2E)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF8888A8), size: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Settings',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Voice Settings ──
                    _sectionTitle('Voice Output'),
                    const SizedBox(height: 10),
                    _card(Column(
                      children: [
                        // Speed
                        _sliderTile(
                          icon: Icons.speed_rounded,
                          title: 'Speech Speed',
                          tag: voiceSpeed <= 0.3
                              ? 'Slow'
                              : voiceSpeed <= 0.6
                              ? 'Normal'
                              : 'Fast',
                          value: voiceSpeed,
                          min: 0.1,
                          max: 1.0,
                          onChanged: (v) => setState(() => voiceSpeed = v),
                        ),
                        _cardLine(),
                        // Volume
                        _sliderTile(
                          icon: Icons.volume_up_rounded,
                          title: 'Voice Volume',
                          tag: '${(voiceVolume * 100).toInt()}%',
                          value: voiceVolume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (v) => setState(() => voiceVolume = v),
                        ),
                        _cardLine(),
                        // Pitch
                        _sliderTile(
                          icon: Icons.music_note_rounded,
                          title: 'Voice Pitch',
                          tag: voicePitch < 0.8
                              ? 'Low'
                              : voicePitch > 1.2
                              ? 'High'
                              : 'Normal',
                          value: voicePitch,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (v) => setState(() => voicePitch = v),
                        ),
                        _cardLine(),
                        // Preview button
                        GestureDetector(
                          onTap: _previewVoice,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10A37F)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: Color(0xFF10A37F), size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Text('Preview Voice',
                                    style: TextStyle(
                                        color: Color(0xFF10A37F),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                                const Spacer(),
                                const Text('Tap to test',
                                    style: TextStyle(
                                        color: Color(0xFF444460),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 22),

                    // ── Translation ──
                    _sectionTitle('Translation'),
                    const SizedBox(height: 10),
                    _card(_toggleTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Auto Detect Language',
                      subtitle: 'Automatically detect spoken language',
                      value: autoDetect,
                      onChanged: (v) => setState(() => autoDetect = v),
                    )),

                    const SizedBox(height: 22),

                    // ── ANC ──
                    _sectionTitle('Noise Cancellation'),
                    const SizedBox(height: 10),
                    _card(_toggleTile(
                      icon: Icons.noise_control_off_rounded,
                      title: 'Enable ANC',
                      subtitle: 'Reduce background noise during translation',
                      value: ancEnabled,
                      onChanged: (v) => setState(() => ancEnabled = v),
                    )),

                    const SizedBox(height: 22),

                    // ── Activation Methods ──
                    _sectionTitle('Activation Methods'),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose how to start/stop translation',
                      style:
                      TextStyle(color: Color(0xFF444460), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    _card(Column(
                      children: [
                        _toggleTile(
                          icon: Icons.touch_app_rounded,
                          title: 'In-App Orb Button',
                          subtitle: 'Tap the big orb on home screen',
                          value: inAppButton,
                          onChanged: (v) =>
                              setState(() => inAppButton = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.volume_down_rounded,
                          title: 'Double Press Volume ↓',
                          subtitle: 'Works even with screen off',
                          value: volumeDoubleClick,
                          onChanged: (v) =>
                              setState(() => volumeDoubleClick = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.phone_android_rounded,
                          title: 'Shake Phone',
                          subtitle: 'Shake device twice to activate',
                          value: shakeToActivate,
                          onChanged: (v) =>
                              setState(() => shakeToActivate = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.mic_rounded,
                          title: 'Voice Command',
                          subtitle: 'Say "Hey Translate" to activate',
                          value: voiceCommand,
                          onChanged: (v) =>
                              setState(() => voiceCommand = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.headphones_rounded,
                          title: 'Double Tap Earbud',
                          subtitle: 'Double tap your earbud',
                          value: doubleTapEarbud,
                          onChanged: (v) =>
                              setState(() => doubleTapEarbud = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.hearing_rounded,
                          title: 'Wear Detection',
                          subtitle: 'Auto-activate when earbuds are worn',
                          value: wearDetection,
                          onChanged: (v) =>
                              setState(() => wearDetection = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.auto_mode_rounded,
                          title: 'Auto Activate',
                          subtitle: 'Activates when foreign language detected',
                          value: autoActivate,
                          onChanged: (v) =>
                              setState(() => autoActivate = v),
                        ),
                        _cardLine(),
                        _toggleTile(
                          icon: Icons.schedule_rounded,
                          title: 'Schedule Activation',
                          subtitle: 'Set a time to auto-activate',
                          value: scheduleActivate,
                          onChanged: (v) =>
                              setState(() => scheduleActivate = v),
                        ),
                      ],
                    )),

                    const SizedBox(height: 24),

                    // Save button
                    GestureDetector(
                      onTap: _isSaving ? null : _saveSettings,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _isSaving
                              ? const Color(0xFF10A37F).withOpacity(0.4)
                              : const Color(0xFF10A37F),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: _isSaving
                              ? []
                              : [
                            BoxShadow(
                              color: const Color(0xFF10A37F)
                                  .withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                              : const Text(
                            'Save Settings',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3),
  );

  Widget _card(Widget child) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0F0F1A),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF141425)),
    ),
    child: child,
  );

  Widget _cardLine() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: const Color(0xFF141425),
  );

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required String tag,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: const Color(0xFF10A37F), size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Color(0xFF8888A8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        color: Color(0xFF10A37F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF10A37F),
              inactiveTrackColor:
              const Color(0xFF10A37F).withOpacity(0.12),
              thumbColor: const Color(0xFF10A37F),
              overlayColor:
              const Color(0xFF10A37F).withOpacity(0.1),
              trackHeight: 3,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
                value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF10A37F).withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF10A37F), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Color(0xFF8888A8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF2A2A3A), fontSize: 11)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: value,
              activeColor: const Color(0xFF10A37F),
              activeTrackColor:
              const Color(0xFF10A37F).withOpacity(0.3),
              inactiveThumbColor: const Color(0xFF333350),
              inactiveTrackColor: const Color(0xFF1E1E2E),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}