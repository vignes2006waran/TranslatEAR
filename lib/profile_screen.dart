import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'translation_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get user => FirebaseAuth.instance.currentUser;

  static final List<Map<String, dynamic>> _languages = [
    {'name': 'Tamil',      'lang': TranslateLanguage.tamil},
    {'name': 'Hindi',      'lang': TranslateLanguage.hindi},
    {'name': 'Telugu',     'lang': TranslateLanguage.telugu},
    {'name': 'Kannada',    'lang': TranslateLanguage.kannada},
    {'name': 'Bengali',    'lang': TranslateLanguage.bengali},
    {'name': 'Gujarati',   'lang': TranslateLanguage.gujarati},
    {'name': 'Marathi',    'lang': TranslateLanguage.marathi},
    {'name': 'Urdu',       'lang': TranslateLanguage.urdu},
    {'name': 'Arabic',     'lang': TranslateLanguage.arabic},
    {'name': 'French',     'lang': TranslateLanguage.french},
    {'name': 'German',     'lang': TranslateLanguage.german},
    {'name': 'Spanish',    'lang': TranslateLanguage.spanish},
    {'name': 'Italian',    'lang': TranslateLanguage.italian},
    {'name': 'Portuguese', 'lang': TranslateLanguage.portuguese},
    {'name': 'Russian',    'lang': TranslateLanguage.russian},
    {'name': 'Japanese',   'lang': TranslateLanguage.japanese},
    {'name': 'Korean',     'lang': TranslateLanguage.korean},
    {'name': 'Chinese',    'lang': TranslateLanguage.chinese},
    {'name': 'Thai',       'lang': TranslateLanguage.thai},
    {'name': 'Vietnamese', 'lang': TranslateLanguage.vietnamese},
    {'name': 'Indonesian', 'lang': TranslateLanguage.indonesian},
    {'name': 'Turkish',    'lang': TranslateLanguage.turkish},
    {'name': 'Dutch',      'lang': TranslateLanguage.dutch},
    {'name': 'Polish',     'lang': TranslateLanguage.polish},
    {'name': 'Swedish',    'lang': TranslateLanguage.swedish},
  ];

  String _selectedLangName = 'Tamil';
  TranslateLanguage _selectedLang = TranslateLanguage.tamil;

  int get totalTranslations => TranslationHistory.sessions
      .fold(0, (sum, s) => sum + (s['conversations'] as List).length);
  int get todaySessions =>
      TranslationHistory.sessions.where((s) => s['date'] == 'Today').length;
  int get languagesUsed =>
      TranslationHistory.sessions.map((s) => '${s['from']}_${s['to']}').toSet().length;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('native_language') ?? 'Tamil';
    final match = _languages.firstWhere(
            (l) => l['name'] == saved, orElse: () => _languages[0]);
    setState(() {
      _selectedLangName = match['name'];
      _selectedLang = match['lang'];
    });
  }

  Future<void> _saveLanguage(String name, TranslateLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('native_language', name);
    TranslationService.instance.setTargetLanguage(lang, name);
    setState(() { _selectedLangName = name; _selectedLang = lang; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Native language set to $name'),
        backgroundColor: const Color(0xFF10A37F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E2E)),
            left: BorderSide(color: Color(0xFF1E1E2E)),
            right: BorderSide(color: Color(0xFF1E1E2E)),
          ),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Native Language',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('App will always translate TO this language',
              style: TextStyle(color: Color(0xFF444460), fontSize: 12)),
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
                    Navigator.pop(ctx);
                    _saveLanguage(lang['name'], lang['lang']);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF10A37F).withOpacity(0.1)
                          : const Color(0xFF0C0C18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10A37F).withOpacity(0.4)
                            : const Color(0xFF1A1A2A),
                      ),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(lang['name'],
                          style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF888899),
                              fontSize: 14, fontWeight: FontWeight.w600))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
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
                const Text('Profile',
                    style: TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ]),
            ),
            const SizedBox(height: 28),

            // Avatar
            Stack(alignment: Alignment.bottomRight, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF12B589), Color(0xFF0B7D5C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFF10A37F).withOpacity(0.35),
                      blurRadius: 24, spreadRadius: 2)],
                ),
                child: user?.photoURL != null
                    ? ClipOval(child: Image.network(user!.photoURL!, fit: BoxFit.cover))
                    : Center(child: Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700))),
              ),
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                    color: const Color(0xFF10A37F), shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0A0A0F), width: 2)),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
              ),
            ]),
            const SizedBox(height: 14),
            Text(user?.displayName ?? 'User',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user?.email ?? '',
                style: const TextStyle(color: Color(0xFF444460), fontSize: 13)),
            const SizedBox(height: 24),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF141425)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _stat(totalTranslations.toString(), 'Total', Icons.translate_rounded),
                  _vDivider(),
                  _stat(todaySessions.toString(), 'Today', Icons.today_rounded),
                  _vDivider(),
                  _stat(languagesUsed.toString(), 'Languages', Icons.language_rounded),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // Native Language selector — synced with settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showLanguagePicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF10A37F).withOpacity(0.3)),
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
                        const Text('Native Language',
                            style: TextStyle(color: Color(0xFF444460),
                                fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(_selectedLangName,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        const Text('Synced with Settings',
                            style: TextStyle(color: Color(0xFF10A37F), fontSize: 10)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10A37F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10A37F).withOpacity(0.2)),
                      ),
                      child: const Row(children: [
                        Text('Change', style: TextStyle(color: Color(0xFF10A37F),
                            fontSize: 12, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF10A37F), size: 16),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF141425)),
                ),
                child: Column(children: [
                  _option(Icons.notifications_rounded, 'Notifications', 'Manage alerts',
                          () => _showComingSoon('Notifications')),
                  _hDivider(),
                  _option(Icons.privacy_tip_rounded, 'Privacy Policy', 'How we use your data',
                          () => _showComingSoon('Privacy Policy')),
                  _hDivider(),
                  _option(Icons.help_rounded, 'Help & Support', 'Get assistance',
                          () => _showComingSoon('Help & Support')),
                  _hDivider(),
                  _option(Icons.info_rounded, 'About TranslateAR', 'Version 1.0.0',
                          () => showAboutDialog(
                        context: context,
                        applicationName: 'TranslateAR',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.translate,
                            color: Color(0xFF10A37F), size: 40),
                        children: [const Text(
                            'Real-time AI translation. Translate conversations directly to your earbuds.',
                            style: TextStyle(fontSize: 14))],
                      )),
                ]),
              ),
            ),
            const SizedBox(height: 14),

            // Sign out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF0F0F1A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFF1E1E2E))),
                      title: const Text('Sign Out',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      content: const Text('Are you sure you want to sign out?',
                          style: TextStyle(color: Color(0xFF555570))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel',
                                style: TextStyle(color: Color(0xFF555570)))),
                        TextButton(onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                              (route) => false);
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 17),
                    SizedBox(width: 8),
                    Text('Sign Out', style: TextStyle(color: Colors.red,
                        fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature coming soon!'),
      backgroundColor: const Color(0xFF10A37F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _stat(String value, String label, IconData icon) => Column(children: [
    Text(value, style: const TextStyle(color: Color(0xFF10A37F),
        fontSize: 24, fontWeight: FontWeight.w700)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Color(0xFF444460), fontSize: 12)),
  ]);

  Widget _vDivider() =>
      Container(width: 1, height: 34, color: const Color(0xFF141425));

  Widget _hDivider() => Container(height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF141425));

  Widget _option(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: const Color(0xFF10A37F), size: 17)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Color(0xFF8888A8),
                fontSize: 14, fontWeight: FontWeight.w500)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF2A2A3A), fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF2A2A3A), size: 18),
        ]),
      ),
    );
  }
}