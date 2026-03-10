import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';
import 'app_theme.dart';

// Theme mode is stored in SharedPreferences under key 'theme_mode'
// Values: 'light' | 'dark' | 'system'

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();

  // ── Theme ──────────────────────────────────────────────────────────────────
  String _themeMode = 'dark';
  late AppTheme _t;

  // ── Voice ──────────────────────────────────────────────────────────────────
  double voiceSpeed = 0.5;
  double voiceVolume = 1.0;
  double voicePitch = 1.0;

  // ── Feature toggles ────────────────────────────────────────────────────────
  bool autoDetect = true;
  bool ancEnabled = false;
  bool inAppButton = true;
  bool shakeToActivate = false;
  bool voiceCommand = false;
  bool doubleTapEarbud = false;
  bool wearDetection = false;
  bool autoActivate = false;
  bool scheduleActivate = false;
  bool volumeDoubleClick = true;
  bool _isSaving = false;

  // ── Language list ──────────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> _languages = [
    {'name': 'Tamil',      'lang': TranslateLanguage.tamil,      'tts': 'ta-IN'},
    {'name': 'Hindi',      'lang': TranslateLanguage.hindi,      'tts': 'hi-IN'},
    {'name': 'Telugu',     'lang': TranslateLanguage.telugu,     'tts': 'te-IN'},
    {'name': 'Kannada',    'lang': TranslateLanguage.kannada,    'tts': 'kn-IN'},
    {'name': 'Bengali',    'lang': TranslateLanguage.bengali,    'tts': 'bn-IN'},
    {'name': 'Gujarati',   'lang': TranslateLanguage.gujarati,   'tts': 'gu-IN'},
    {'name': 'Marathi',    'lang': TranslateLanguage.marathi,    'tts': 'mr-IN'},
    {'name': 'Urdu',       'lang': TranslateLanguage.urdu,       'tts': 'ur-PK'},
    {'name': 'Arabic',     'lang': TranslateLanguage.arabic,     'tts': 'ar-SA'},
    {'name': 'French',     'lang': TranslateLanguage.french,     'tts': 'fr-FR'},
    {'name': 'German',     'lang': TranslateLanguage.german,     'tts': 'de-DE'},
    {'name': 'Spanish',    'lang': TranslateLanguage.spanish,    'tts': 'es-ES'},
    {'name': 'Italian',    'lang': TranslateLanguage.italian,    'tts': 'it-IT'},
    {'name': 'Portuguese', 'lang': TranslateLanguage.portuguese, 'tts': 'pt-BR'},
    {'name': 'Russian',    'lang': TranslateLanguage.russian,    'tts': 'ru-RU'},
    {'name': 'Japanese',   'lang': TranslateLanguage.japanese,   'tts': 'ja-JP'},
    {'name': 'Korean',     'lang': TranslateLanguage.korean,     'tts': 'ko-KR'},
    {'name': 'Chinese',    'lang': TranslateLanguage.chinese,    'tts': 'zh-CN'},
    {'name': 'Thai',       'lang': TranslateLanguage.thai,       'tts': 'th-TH'},
    {'name': 'Vietnamese', 'lang': TranslateLanguage.vietnamese, 'tts': 'vi-VN'},
    {'name': 'Indonesian', 'lang': TranslateLanguage.indonesian, 'tts': 'id-ID'},
    {'name': 'Turkish',    'lang': TranslateLanguage.turkish,    'tts': 'tr-TR'},
    {'name': 'Dutch',      'lang': TranslateLanguage.dutch,      'tts': 'nl-NL'},
    {'name': 'Polish',     'lang': TranslateLanguage.polish,     'tts': 'pl-PL'},
    {'name': 'Swedish',    'lang': TranslateLanguage.swedish,    'tts': 'sv-SE'},
  ];

  String _selectedLangName = 'Tamil';
  TranslateLanguage _selectedLang = TranslateLanguage.tamil;
  String _selectedTts = 'ta-IN';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _t = const AppTheme(true); // default until prefs load
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'dark';
    final savedLang = prefs.getString('native_language') ?? 'Tamil';
    final match = _languages.firstWhere(
          (l) => l['name'] == savedLang,
      orElse: () => _languages[0],
    );
    setState(() {
      _themeMode = savedTheme;
      _t = AppTheme(_resolvedIsDark(savedTheme));
      _selectedLangName = match['name'];
      _selectedLang = match['lang'];
      _selectedTts = match['tts'];
    });
    await _tts.setLanguage(_selectedTts);
    await _tts.setSpeechRate(voiceSpeed);
    await _tts.setVolume(voiceVolume);
    await _tts.setPitch(voicePitch);
  }

  /// Returns true if dark mode should be active for the given theme_mode.
  bool _resolvedIsDark(String mode) {
    if (mode == 'light') return false;
    if (mode == 'dark') return true;
    // 'system' — follow the device brightness
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  Future<void> _setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    // Keep legacy 'is_dark_mode' key in sync so other screens still work
    await prefs.setBool('is_dark_mode', _resolvedIsDark(mode));
    setState(() {
      _themeMode = mode;
      _t = AppTheme(_resolvedIsDark(mode));
    });
  }

  // ── TTS preview ────────────────────────────────────────────────────────────
  Future<void> _previewVoice() async {
    await _tts.setLanguage(_selectedTts);
    await _tts.setSpeechRate(voiceSpeed);
    await _tts.setVolume(voiceVolume);
    await _tts.setPitch(voicePitch);
    await _tts.speak('Hello, this is a test voice');
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('native_language', _selectedLangName);
    TranslationService.instance
        .setTargetLanguage(_selectedLang, _selectedLangName);
    await _tts.setLanguage(_selectedTts);
    await _tts.setSpeechRate(voiceSpeed);
    await _tts.setVolume(voiceVolume);
    await _tts.setPitch(voicePitch);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Saved! Translating to $_selectedLangName'),
        ]),
        backgroundColor: const Color(0xFF10A37F),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context);
    }
  }

  // ── Language picker bottom sheet ───────────────────────────────────────────
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _t.bar,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: _t.bdr),
            left: BorderSide(color: _t.bdr),
            right: BorderSide(color: _t.bdr),
          ),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: _t.bdr2, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Select Native Language',
              style: TextStyle(color: _t.txPri, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('App will always translate TO this language',
              style: TextStyle(color: _t.txMut, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              itemBuilder: (ctx, i) {
                final lang = _languages[i];
                final isSelected = lang['name'] == _selectedLangName;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLangName = lang['name'];
                      _selectedLang = lang['lang'];
                      _selectedTts = lang['tts'];
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF10A37F).withOpacity(0.1)
                          : _t.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10A37F).withOpacity(0.4)
                            : _t.bdr3,
                      ),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(lang['name'],
                            style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF10A37F)
                                    : _t.txSec,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10A37F), size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.bg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _t.bar,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _t.bdr),
                    boxShadow: _t.barShadow,
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: _t.txSec, size: 17),
                ),
              ),
              const SizedBox(width: 12),
              Text('Settings',
                  style: TextStyle(color: _t.txPri, fontSize: 20,
                      fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            ]),
          ),

          // ── Body ───────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Appearance ────────────────────────────────────────
                  _sectionTitle('Appearance'),
                  const SizedBox(height: 10),
                  _card(
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row: icon + label
                          Row(children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10A37F).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.palette_rounded,
                                  color: Color(0xFF10A37F), size: 17),
                            ),
                            const SizedBox(width: 12),
                            Text('App Theme',
                                style: TextStyle(color: _t.txSec,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 14),

                          // ── Three option buttons ──────────────────
                          Row(children: [
                            _themeOption(
                              mode: 'light',
                              icon: Icons.light_mode_rounded,
                              label: 'Light',
                            ),
                            const SizedBox(width: 8),
                            _themeOption(
                              mode: 'dark',
                              icon: Icons.dark_mode_rounded,
                              label: 'Dark',
                            ),
                            const SizedBox(width: 8),
                            _themeOption(
                              mode: 'system',
                              icon: Icons.phone_android_rounded,
                              label: 'System',
                            ),
                          ]),
                          const SizedBox(height: 10),

                          // ── Hint text ─────────────────────────────
                          Row(children: [
                            Icon(Icons.info_outline_rounded,
                                size: 12, color: _t.txMut),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _themeMode == 'system'
                                    ? 'Follows your phone\'s display settings'
                                    : _themeMode == 'dark'
                                    ? 'Dark theme is active'
                                    : 'Light theme is active',
                                style: TextStyle(
                                    color: _t.txMut, fontSize: 11),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Native Language ───────────────────────────────────
                  _sectionTitle('Native Language'),
                  const SizedBox(height: 6),
                  Text('App always translates TO this language',
                      style: TextStyle(color: _t.txMut, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showLanguagePicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _t.bar,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF10A37F).withOpacity(0.3)),
                        boxShadow: _t.cardShadow,
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10A37F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.language_rounded,
                              color: Color(0xFF10A37F), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Translate to',
                                style: TextStyle(color: _t.txMut,
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(_selectedLangName,
                                style: TextStyle(color: _t.txPri,
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10A37F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF10A37F).withOpacity(0.2)),
                          ),
                          child: const Row(children: [
                            Text('Change',
                                style: TextStyle(color: Color(0xFF10A37F),
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF10A37F), size: 16),
                          ]),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── Voice Output ──────────────────────────────────────
                  _sectionTitle('Voice Output'),
                  const SizedBox(height: 10),
                  _card(Column(children: [
                    _sliderTile(
                      icon: Icons.speed_rounded,
                      title: 'Speech Speed',
                      tag: voiceSpeed <= 0.3
                          ? 'Slow'
                          : voiceSpeed <= 0.6 ? 'Normal' : 'Fast',
                      value: voiceSpeed, min: 0.1, max: 1.0,
                      onChanged: (v) => setState(() => voiceSpeed = v),
                    ),
                    _cardLine(),
                    _sliderTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Voice Volume',
                      tag: '${(voiceVolume * 100).toInt()}%',
                      value: voiceVolume, min: 0.0, max: 1.0,
                      onChanged: (v) => setState(() => voiceVolume = v),
                    ),
                    _cardLine(),
                    _sliderTile(
                      icon: Icons.music_note_rounded,
                      title: 'Voice Pitch',
                      tag: voicePitch < 0.8
                          ? 'Low'
                          : voicePitch > 1.2 ? 'High' : 'Normal',
                      value: voicePitch, min: 0.5, max: 2.0,
                      onChanged: (v) => setState(() => voicePitch = v),
                    ),
                    _cardLine(),
                    GestureDetector(
                      onTap: _previewVoice,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10A37F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                                Icons.play_circle_outline_rounded,
                                color: Color(0xFF10A37F), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text('Preview Voice',
                              style: TextStyle(color: Color(0xFF10A37F),
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('Tap to test',
                              style: TextStyle(
                                  color: _t.txMut, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ])),

                  const SizedBox(height: 22),

                  // ── Translation ───────────────────────────────────────
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

                  // ── Noise Cancellation ────────────────────────────────
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

                  // ── Activation Methods ────────────────────────────────
                  _sectionTitle('Activation Methods'),
                  const SizedBox(height: 4),
                  Text('Choose how to start/stop translation',
                      style: TextStyle(color: _t.txMut, fontSize: 12)),
                  const SizedBox(height: 10),
                  _card(Column(children: [
                    _toggleTile(
                      icon: Icons.touch_app_rounded,
                      title: 'In-App Orb Button',
                      subtitle: 'Tap the big orb on home screen',
                      value: inAppButton,
                      onChanged: (v) => setState(() => inAppButton = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.volume_down_rounded,
                      title: 'Double Press Volume \u2193',
                      subtitle: 'Works even with screen off',
                      value: volumeDoubleClick,
                      onChanged: (v) => setState(() => volumeDoubleClick = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Shake Phone',
                      subtitle: 'Shake device twice to activate',
                      value: shakeToActivate,
                      onChanged: (v) => setState(() => shakeToActivate = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.mic_rounded,
                      title: 'Voice Command',
                      subtitle: 'Say "Hey Translate" to activate',
                      value: voiceCommand,
                      onChanged: (v) => setState(() => voiceCommand = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.headphones_rounded,
                      title: 'Double Tap Earbud',
                      subtitle: 'Double tap your earbud',
                      value: doubleTapEarbud,
                      onChanged: (v) => setState(() => doubleTapEarbud = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.hearing_rounded,
                      title: 'Wear Detection',
                      subtitle: 'Auto-activate when earbuds are worn',
                      value: wearDetection,
                      onChanged: (v) => setState(() => wearDetection = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.auto_mode_rounded,
                      title: 'Auto Activate',
                      subtitle: 'Activates when foreign language detected',
                      value: autoActivate,
                      onChanged: (v) => setState(() => autoActivate = v),
                    ),
                    _cardLine(),
                    _toggleTile(
                      icon: Icons.schedule_rounded,
                      title: 'Schedule Activation',
                      subtitle: 'Set a time to auto-activate',
                      value: scheduleActivate,
                      onChanged: (v) => setState(() => scheduleActivate = v),
                    ),
                  ])),

                  const SizedBox(height: 24),

                  // ── Save button ───────────────────────────────────────
                  GestureDetector(
                    onTap: _isSaving ? null : _saveSettings,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity, height: 54,
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
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : const Text('Save Settings',
                            style: TextStyle(color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Theme option tile (Light / Dark / System) ──────────────────────────────
  Widget _themeOption({
    required String mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10A37F) : _t.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF10A37F) : _t.bdr,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: const Color(0xFF10A37F).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ]
                : [],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 20,
                color: isSelected ? Colors.white : _t.txSec),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                  color: isSelected ? Colors.white : _t.txSec,
                  fontSize: 12,
                  fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
                )),
          ]),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(color: _t.txPri, fontSize: 16,
          fontWeight: FontWeight.w700, letterSpacing: -0.3));

  Widget _card(Widget child) => Container(
      decoration: BoxDecoration(
          color: _t.bar,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _t.bdr2),
          boxShadow: _t.cardShadow),
      child: child);

  Widget _cardLine() => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: _t.divider);

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
      child: Column(children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: const Color(0xFF10A37F).withOpacity(0.08),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: const Color(0xFF10A37F), size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(color: _t.txSec, fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF10A37F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(7)),
            child: Text(tag,
                style: const TextStyle(color: Color(0xFF10A37F),
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF10A37F),
            inactiveTrackColor: const Color(0xFF10A37F).withOpacity(0.12),
            thumbColor: const Color(0xFF10A37F),
            overlayColor: const Color(0xFF10A37F).withOpacity(0.1),
            trackHeight: 3,
            thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child:
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ]),
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
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF10A37F).withOpacity(0.08),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: const Color(0xFF10A37F), size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: _t.txSec, fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: _t.txDead, fontSize: 11)),
          ],
        )),
        Transform.scale(
          scale: 0.82,
          child: Switch(
            value: value,
            activeColor: const Color(0xFF10A37F),
            activeTrackColor: const Color(0xFF10A37F).withOpacity(0.3),
            inactiveThumbColor: _t.iconBg,
            inactiveTrackColor: _t.bdr,
            onChanged: onChanged,
          ),
        ),
      ]),
    );
  }
}