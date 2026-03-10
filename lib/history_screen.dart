import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // for TranslationHistory
import 'app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FlutterTts _tts = FlutterTts();
  late AppTheme _t;

  @override
  void initState() {
    super.initState();
    _t = const AppTheme(true); // default until prefs load
    _tts.setLanguage('ta-IN');
    _tts.setSpeechRate(0.5);
    _loadTheme();
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

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  List<Map<String, dynamic>> get sessions => TranslationHistory.sessions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
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
                Text('History',
                    style: TextStyle(
                        color: _t.txPri,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5)),
                const Spacer(),
                if (sessions.isNotEmpty)
                  GestureDetector(
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => _clearDialog()),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border:
                        Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 17),
                    ),
                  ),
              ]),
            ),

            if (sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  Text('${sessions.length} session(s)',
                      style: TextStyle(color: _t.txMut, fontSize: 13)),
                ]),
              ),

            const SizedBox(height: 8),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: _t.bar,
                        shape: BoxShape.circle,
                        border: Border.all(color: _t.bdr),
                      ),
                      child: Icon(Icons.history_rounded,
                          size: 36, color: _t.txDead),
                    ),
                    const SizedBox(height: 16),
                    Text('No history yet',
                        style: TextStyle(
                            color: _t.txSec,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      'Start translating to see\nconversations here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _t.txDead, fontSize: 13),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return Dismissible(
                    key: Key('session_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3)),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.red, size: 22),
                    ),
                    onDismissed: (_) {
                      setState(() =>
                          TranslationHistory.sessions.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Session deleted'),
                          backgroundColor:
                          Colors.red.withOpacity(0.8),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationDetailScreen(
                            session: session,
                            onSpeak: _speak,
                            isDark: _t.isDark,
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _t.bar,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _t.bdr2),
                          boxShadow: _t.cardShadow,
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10A37F)
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF10A37F), size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10A37F)
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${session['from']} → ${session['to']}',
                                      style: const TextStyle(
                                          color: Color(0xFF10A37F),
                                          fontSize: 10,
                                          fontWeight:
                                          FontWeight.w600),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${session['date']} · ${session['time']}',
                                    style: TextStyle(
                                        color: _t.txDead,
                                        fontSize: 11),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Text(
                                  '${(session['conversations'] as List).length} translations',
                                  style: TextStyle(
                                      color: _t.txPri,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  session['summary'] ?? '',
                                  style: TextStyle(
                                      color: _t.txMut,
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: _t.txDead, size: 20),
                        ]),
                      ),
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

  Widget _clearDialog() {
    return AlertDialog(
      backgroundColor: _t.bar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _t.bdr),
      ),
      title: Text('Clear History',
          style: TextStyle(
              color: _t.txPri, fontWeight: FontWeight.w700)),
      content: Text('Delete all translation history?',
          style: TextStyle(color: _t.txSec)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: _t.txSec)),
        ),
        TextButton(
          onPressed: () {
            setState(() => TranslationHistory.sessions.clear());
            Navigator.pop(context);
          },
          child: const Text('Delete All',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Conversation Detail ────────────────────────────────────────────────────────

class ConversationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;
  final Function(String) onSpeak;
  final bool isDark;

  const ConversationDetailScreen({
    super.key,
    required this.session,
    required this.onSpeak,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme(isDark);
    final conversations =
    (session['conversations'] as List).cast<Map<String, String>>();

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: t.bar,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.bdr),
                    boxShadow: t.barShadow,
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: t.txSec, size: 17),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session['from']} → ${session['to']}',
                      style: TextStyle(
                          color: t.txPri,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${session['date']} · ${session['time']}',
                      style: TextStyle(color: t.txMut, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Conversation list ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                ...conversations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final conv = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: t.bar,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.bdr2),
                      boxShadow: t.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original text row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: t.iconBg,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text('#${i + 1}',
                                    style: TextStyle(
                                        color: t.txMut,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(conv['original'] ?? '',
                                    style: TextStyle(
                                        color: t.txSec,
                                        fontSize: 14,
                                        height: 1.5)),
                              ),
                            ],
                          ),
                        ),
                        // Divider with green gradient
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              const Color(0xFF10A37F).withOpacity(0.3),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                        // Translated text row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.translate_rounded,
                                  color: Color(0xFF10A37F), size: 15),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(conv['translated'] ?? '',
                                    style: TextStyle(
                                        color: t.txPri,
                                        fontSize: 16,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500)),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    onSpeak(conv['translated'] ?? ''),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(Icons.volume_up_rounded,
                                      color: t.txMut, size: 17),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 8),

                // ── Summary card ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF10A37F).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10A37F).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.summarize_rounded,
                              color: Color(0xFF10A37F), size: 15),
                        ),
                        const SizedBox(width: 10),
                        const Text('Conversation Summary',
                            style: TextStyle(
                                color: Color(0xFF10A37F),
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        session['summary'] ?? '',
                        style: TextStyle(
                            color: t.txSec, fontSize: 14, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}