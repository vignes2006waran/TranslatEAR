import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'home_screen.dart'; // for TranslationHistory

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ta-IN');
    _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  List<Map<String, dynamic>> get sessions => TranslationHistory.sessions;

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
                  const Text('History',
                      style: TextStyle(
                          color: Colors.white,
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
                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red, size: 17),
                      ),
                    ),
                ],
              ),
            ),

            if (sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    Text('${sessions.length} session(s)',
                        style: const TextStyle(
                            color: Color(0xFF444460), fontSize: 13)),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: sessions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F1A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E1E2E)),
                      ),
                      child: const Icon(Icons.history_rounded,
                          size: 36, color: Color(0xFF2A2A3A)),
                    ),
                    const SizedBox(height: 16),
                    const Text('No history yet',
                        style: TextStyle(
                            color: Color(0xFF555570),
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Start translating to see\nconversations here',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(color: Color(0xFF2A2A3A), fontSize: 13),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                      setState(
                              () => TranslationHistory.sessions.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Session deleted'),
                          backgroundColor: Colors.red.withOpacity(0.8),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF141425)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10A37F)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
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
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
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
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${session['date']} · ${session['time']}',
                                        style: const TextStyle(
                                            color: Color(0xFF2A2A3A),
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${(session['conversations'] as List).length} translations',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    session['summary'] ?? '',
                                    style: const TextStyle(
                                        color: Color(0xFF444460),
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF2A2A3A), size: 20),
                          ],
                        ),
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
      backgroundColor: const Color(0xFF0F0F1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1E1E2E)),
      ),
      title: const Text('Clear History',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
      content: const Text('Delete all translation history?',
          style: TextStyle(color: Color(0xFF555570))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF555570))),
        ),
        TextButton(
          onPressed: () {
            setState(() => TranslationHistory.sessions.clear());
            Navigator.pop(context);
          },
          child: const Text('Delete All',
              style:
              TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class ConversationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;
  final Function(String) onSpeak;

  const ConversationDetailScreen({
    super.key,
    required this.session,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final conversations =
    (session['conversations'] as List).cast<Map<String, String>>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session['from']} → ${session['to']}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${session['date']} · ${session['time']}',
                          style: const TextStyle(
                              color: Color(0xFF444460), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                        color: const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF141425)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text('#${i + 1}',
                                      style: const TextStyle(
                                          color: Color(0xFF444460),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(conv['original'] ?? '',
                                      style: const TextStyle(
                                          color: Color(0xFF8888A8),
                                          fontSize: 14,
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          ),
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
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500)),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      onSpeak(conv['translated'] ?? ''),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.volume_up_rounded,
                                        color: Color(0xFF444460), size: 17),
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
                  // Summary card
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
                        Row(
                          children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color:
                                const Color(0xFF10A37F).withOpacity(0.12),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          session['summary'] ?? '',
                          style: const TextStyle(
                              color: Color(0xFF8888A8),
                              fontSize: 14,
                              height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}