import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';
import 'vosk_service.dart';
import 'app_theme.dart';

class LanguagesScreen extends StatefulWidget {
  const LanguagesScreen({super.key});
  @override
  State<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends State<LanguagesScreen> {
  final _modelManager = OnDeviceTranslatorModelManager();
  final Map<String, bool> _downloaded = {};
  final Map<String, bool> _downloading = {};
  final Map<String, bool> _voskDownloaded = {};
  final Map<String, bool> _voskDownloading = {};
  final TextEditingController _search = TextEditingController();
  String _query = '';
  late AppTheme _t;

  static final List<Map<String, dynamic>> _allLanguages = [
    {'name': 'Afrikaans',  'lang': TranslateLanguage.afrikaans},
    {'name': 'Albanian',   'lang': TranslateLanguage.albanian},
    {'name': 'Arabic',     'lang': TranslateLanguage.arabic},
    {'name': 'Belarusian', 'lang': TranslateLanguage.belarusian},
    {'name': 'Bengali',    'lang': TranslateLanguage.bengali},
    {'name': 'Bulgarian',  'lang': TranslateLanguage.bulgarian},
    {'name': 'Catalan',    'lang': TranslateLanguage.catalan},
    {'name': 'Chinese',    'lang': TranslateLanguage.chinese},
    {'name': 'Croatian',   'lang': TranslateLanguage.croatian},
    {'name': 'Czech',      'lang': TranslateLanguage.czech},
    {'name': 'Danish',     'lang': TranslateLanguage.danish},
    {'name': 'Dutch',      'lang': TranslateLanguage.dutch},
    {'name': 'English',    'lang': TranslateLanguage.english},
    {'name': 'Esperanto',  'lang': TranslateLanguage.esperanto},
    {'name': 'Estonian',   'lang': TranslateLanguage.estonian},
    {'name': 'Finnish',    'lang': TranslateLanguage.finnish},
    {'name': 'French',     'lang': TranslateLanguage.french},
    {'name': 'Galician',   'lang': TranslateLanguage.galician},
    {'name': 'Georgian',   'lang': TranslateLanguage.georgian},
    {'name': 'German',     'lang': TranslateLanguage.german},
    {'name': 'Greek',      'lang': TranslateLanguage.greek},
    {'name': 'Gujarati',   'lang': TranslateLanguage.gujarati},
    {'name': 'Hebrew',     'lang': TranslateLanguage.hebrew},
    {'name': 'Hindi',      'lang': TranslateLanguage.hindi},
    {'name': 'Hungarian',  'lang': TranslateLanguage.hungarian},
    {'name': 'Icelandic',  'lang': TranslateLanguage.icelandic},
    {'name': 'Indonesian', 'lang': TranslateLanguage.indonesian},
    {'name': 'Irish',      'lang': TranslateLanguage.irish},
    {'name': 'Italian',    'lang': TranslateLanguage.italian},
    {'name': 'Japanese',   'lang': TranslateLanguage.japanese},
    {'name': 'Kannada',    'lang': TranslateLanguage.kannada},
    {'name': 'Korean',     'lang': TranslateLanguage.korean},
    {'name': 'Latvian',    'lang': TranslateLanguage.latvian},
    {'name': 'Lithuanian', 'lang': TranslateLanguage.lithuanian},
    {'name': 'Macedonian', 'lang': TranslateLanguage.macedonian},
    {'name': 'Malay',      'lang': TranslateLanguage.malay},
    {'name': 'Maltese',    'lang': TranslateLanguage.maltese},
    {'name': 'Marathi',    'lang': TranslateLanguage.marathi},
    {'name': 'Norwegian',  'lang': TranslateLanguage.norwegian},
    {'name': 'Persian',    'lang': TranslateLanguage.persian},
    {'name': 'Polish',     'lang': TranslateLanguage.polish},
    {'name': 'Portuguese', 'lang': TranslateLanguage.portuguese},
    {'name': 'Romanian',   'lang': TranslateLanguage.romanian},
    {'name': 'Russian',    'lang': TranslateLanguage.russian},
    {'name': 'Slovak',     'lang': TranslateLanguage.slovak},
    {'name': 'Slovenian',  'lang': TranslateLanguage.slovenian},
    {'name': 'Spanish',    'lang': TranslateLanguage.spanish},
    {'name': 'Swahili',    'lang': TranslateLanguage.swahili},
    {'name': 'Swedish',    'lang': TranslateLanguage.swedish},
    {'name': 'Tagalog',    'lang': TranslateLanguage.tagalog},
    {'name': 'Tamil',      'lang': TranslateLanguage.tamil},
    {'name': 'Telugu',     'lang': TranslateLanguage.telugu},
    {'name': 'Thai',       'lang': TranslateLanguage.thai},
    {'name': 'Turkish',    'lang': TranslateLanguage.turkish},
    {'name': 'Ukrainian',  'lang': TranslateLanguage.ukrainian},
    {'name': 'Urdu',       'lang': TranslateLanguage.urdu},
    {'name': 'Vietnamese', 'lang': TranslateLanguage.vietnamese},
    {'name': 'Welsh',      'lang': TranslateLanguage.welsh},
  ];

  @override
  void initState() {
    super.initState();
    _t = const AppTheme(true);
    _loadTheme();
    _checkAll();
    _search.addListener(() => setState(() => _query = _search.text.toLowerCase()));
  }

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

  Future<void> _checkAll() async {
    for (final lang in _allLanguages) {
      final code = (lang['lang'] as TranslateLanguage).bcpCode;
      final mlOk = await _modelManager.isModelDownloaded(code);
      final voskOk = await VoskService.instance.isModelDownloaded(code);
      if (mounted) setState(() {
        _downloaded[code] = mlOk;
        _voskDownloaded[code] = voskOk;
      });
    }
  }

  Future<void> _download(TranslateLanguage lang) async {
    final code = lang.bcpCode;
    setState(() { _downloading[code] = true; _voskDownloading[code] = true; });
    try {
      // Download ML Kit translation model
      await _modelManager.downloadModel(code);
      if (mounted) setState(() { _downloaded[code] = true; _downloading.remove(code); });
      TranslationService.instance.reloadIfNeeded(lang);

      // Download Vosk speech model (runs in parallel phase)
      await VoskService.instance.downloadModel(
        code,
        onProgress: (p) {
          // Progress shown via _voskDownloading indicator
        },
      );
      if (mounted) setState(() {
        _voskDownloaded[code] = true;
        _voskDownloading.remove(code);
      });
    } catch (e) {
      if (mounted) setState(() {
        _downloading.remove(code);
        _voskDownloading.remove(code);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _delete(TranslateLanguage lang) async {
    final code = lang.bcpCode;
    await _modelManager.deleteModel(code);
    await VoskService.instance.deleteModel(code);
    if (mounted) setState(() {
      _downloaded[code] = false;
      _voskDownloaded[code] = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _allLanguages;
    return _allLanguages
        .where((l) => (l['name'] as String).toLowerCase().contains(_query))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _langEmoji(String name) {
    const map = {
      'Tamil': '🇮🇳', 'Hindi': '🇮🇳', 'Telugu': '🇮🇳', 'Kannada': '🇮🇳',
      'Malayalam': '🇮🇳', 'Bengali': '🇧🇩', 'Gujarati': '🇮🇳', 'Marathi': '🇮🇳',
      'Urdu': '🇵🇰', 'Arabic': '🇸🇦', 'French': '🇫🇷', 'German': '🇩🇪',
      'Spanish': '🇪🇸', 'Italian': '🇮🇹', 'Portuguese': '🇧🇷', 'Russian': '🇷🇺',
      'Japanese': '🇯🇵', 'Korean': '🇰🇷', 'Chinese': '🇨🇳', 'Thai': '🇹🇭',
      'Vietnamese': '🇻🇳', 'Indonesian': '🇮🇩', 'Malay': '🇲🇾', 'Turkish': '🇹🇷',
      'Dutch': '🇳🇱', 'Polish': '🇵🇱', 'Swedish': '🇸🇪', 'Norwegian': '🇳🇴',
      'Danish': '🇩🇰', 'Finnish': '🇫🇮', 'Greek': '🇬🇷', 'Hebrew': '🇮🇱',
      'Persian': '🇮🇷', 'Ukrainian': '🇺🇦', 'Romanian': '🇷🇴', 'Czech': '🇨🇿',
      'Hungarian': '🇭🇺', 'Bulgarian': '🇧🇬', 'Croatian': '🇭🇷', 'Slovak': '🇸🇰',
      'Tagalog': '🇵🇭', 'Swahili': '🇰🇪', 'Afrikaans': '🇿🇦', 'Welsh': '🏴',
      'Irish': '🇮🇪', 'Catalan': '🇪🇸', 'Galician': '🇪🇸',
    };
    return map[name] ?? '🌐';
  }

  void _showDeleteDialog(TranslateLanguage lang, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.bar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _t.bdr),
        ),
        title: Text('Delete $name?',
            style: TextStyle(color: _t.txPri, fontWeight: FontWeight.w700)),
        content: Text('This will remove the offline model for $name.',
            style: TextStyle(color: _t.txSec)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _t.txSec))),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _delete(lang);
              },
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _t.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF10A37F).withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: Color(0xFF10A37F), size: 18),
                ),
                const SizedBox(width: 10),
                Text('Languages',
                    style: TextStyle(
                        color: _t.txPri,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                    '${_downloaded.values.where((v) => v).length} downloaded',
                    style: TextStyle(color: _t.txMut, fontSize: 12)),
              ]),
            ),

            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _t.bar,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _t.bdr),
                  boxShadow: _t.cardShadow,
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: _t.txMut, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      style: TextStyle(color: _t.txPri, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search language...',
                        hintStyle: TextStyle(color: _t.txMut),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            // ── Info banner ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF10A37F).withOpacity(0.15)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF10A37F), size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Download languages for offline translation + speech. Each ~80 MB.',
                        style: TextStyle(
                            color: Color(0xFF10A37F), fontSize: 11)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            // ── Language list ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final item = filtered[i];
                  final name = item['name'] as String;
                  final lang = item['lang'] as TranslateLanguage;
                  final code = lang.bcpCode;
                  final isDownloaded = _downloaded[code] ?? false;
                  final isDownloading = _downloading[code] ?? false;
                  final isActive =
                      TranslationService.instance.currentTargetLang == lang;

                  return GestureDetector(
                    onTap: isDownloaded
                        ? () {
                      TranslationService.instance
                          .setTargetLanguage(lang, name);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Translating to $name'),
                          backgroundColor: const Color(0xFF10A37F),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF10A37F).withOpacity(0.08)
                            : _t.bar,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF10A37F).withOpacity(0.4)
                              : _t.bdr3,
                        ),
                        boxShadow: _t.cardShadow,
                      ),
                      child: Row(children: [
                        // Emoji icon
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: isDownloaded
                                ? const Color(0xFF10A37F).withOpacity(0.1)
                                : _t.iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                              child: Text(_langEmoji(name),
                                  style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),

                        // Name + status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: TextStyle(
                                    color: isDownloaded
                                        ? _t.txPri
                                        : _t.txSec,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                  isActive
                                      ? 'Active'
                                      : isDownloaded
                                      ? 'Tap to use'
                                      : '~80 MB',
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF10A37F)
                                        : _t.txMut,
                                    fontSize: 11,
                                  )),
                              if (isDownloading) ...[
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  backgroundColor: _t.bdr3,
                                  valueColor:
                                  const AlwaysStoppedAnimation(
                                      Color(0xFF10A37F)),
                                  minHeight: 3,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action button / indicator
                        if (isDownloading)
                          const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Color(0xFF10A37F), strokeWidth: 2))
                        else if (isDownloaded)
                          Row(children: [
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10A37F)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Active',
                                    style: TextStyle(
                                        color: Color(0xFF10A37F),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              )
                            else
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF10A37F), size: 20),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showDeleteDialog(lang, name),
                              child: Icon(Icons.delete_outline_rounded,
                                  color: _t.txMut, size: 18),
                            ),
                          ])
                        else
                          GestureDetector(
                            onTap: () => _download(lang),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10A37F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(children: [
                                Icon(Icons.download_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Get',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}