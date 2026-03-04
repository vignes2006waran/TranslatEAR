import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'home_screen.dart'; // for TranslationHistory

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get user => FirebaseAuth.instance.currentUser;

  final List<Map<String, String>> languages = [
    {'name': 'Tamil', 'code': 'tam_Taml'},
    {'name': 'Hindi', 'code': 'hin_Deva'},
    {'name': 'Telugu', 'code': 'tel_Telu'},
    {'name': 'Malayalam', 'code': 'mal_Mlym'},
    {'name': 'Kannada', 'code': 'kan_Knda'},
    {'name': 'Bengali', 'code': 'ben_Beng'},
    {'name': 'Urdu', 'code': 'urd_Arab'},
    {'name': 'English', 'code': 'eng_Latn'},
    {'name': 'French', 'code': 'fra_Latn'},
    {'name': 'Spanish', 'code': 'spa_Latn'},
    {'name': 'Arabic', 'code': 'arb_Arab'},
    {'name': 'Chinese', 'code': 'zho_Hans'},
    {'name': 'Japanese', 'code': 'jpn_Jpan'},
    {'name': 'Korean', 'code': 'kor_Hang'},
    {'name': 'German', 'code': 'deu_Latn'},
    {'name': 'Italian', 'code': 'ita_Latn'},
    {'name': 'Portuguese', 'code': 'por_Latn'},
    {'name': 'Russian', 'code': 'rus_Cyrl'},
    {'name': 'Turkish', 'code': 'tur_Latn'},
    {'name': 'Dutch', 'code': 'nld_Latn'},
  ];

  String selectedLanguage = 'Tamil';

  int get totalTranslations => TranslationHistory.sessions
      .fold(0, (sum, s) => sum + (s['conversations'] as List).length);

  int get todaySessions {
    final today = DateTime.now();
    return TranslationHistory.sessions
        .where((s) => s['date'] == 'Today')
        .length;
  }

  int get languagesUsed {
    final langs = TranslationHistory.sessions
        .map((s) => '${s['from']}_${s['to']}')
        .toSet();
    return langs.isEmpty ? 0 : langs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    const Text('Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF12B589), Color(0xFF0B7D5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10A37F).withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: user?.photoURL != null
                        ? ClipOval(
                        child: Image.network(user!.photoURL!,
                            fit: BoxFit.cover))
                        : Center(
                      child: Text(
                        user?.displayName
                            ?.substring(0, 1)
                            .toUpperCase() ??
                            'U',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10A37F),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0A0A0F), width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 13),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                user?.displayName ?? 'User',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                    color: Color(0xFF444460), fontSize: 13),
              ),

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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(totalTranslations.toString(), 'Total', Icons.translate_rounded),
                      _vDivider(),
                      _stat(todaySessions.toString(), 'Today', Icons.today_rounded),
                      _vDivider(),
                      _stat(languagesUsed.toString(), 'Languages', Icons.language_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Language selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F1A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF141425)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.language_rounded,
                              color: Color(0xFF10A37F), size: 17),
                          SizedBox(width: 8),
                          Text('Native Language',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Translations will output in this language',
                        style:
                        TextStyle(color: Color(0xFF444460), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141420),
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: const Color(0xFF1E1E2E)),
                        ),
                        child: DropdownButton<String>(
                          value: selectedLanguage,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF141420),
                          underline: const SizedBox(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF555570)),
                          items: languages
                              .map((lang) => DropdownMenuItem<String>(
                            value: lang['name'],
                            child: Text(lang['name']!),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedLanguage = value!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Native language set to $value'),
                                backgroundColor:
                                const Color(0xFF10A37F),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                  child: Column(
                    children: [
                      _option(
                        Icons.notifications_rounded,
                        'Notifications',
                        'Manage alerts',
                            () => _showComingSoon('Notifications'),
                      ),
                      _hDivider(),
                      _option(
                        Icons.privacy_tip_rounded,
                        'Privacy Policy',
                        'How we use your data',
                            () => _showComingSoon('Privacy Policy'),
                      ),
                      _hDivider(),
                      _option(
                        Icons.help_rounded,
                        'Help & Support',
                        'Get assistance',
                            () => _showComingSoon('Help & Support'),
                      ),
                      _hDivider(),
                      _option(
                        Icons.info_rounded,
                        'About TranslateAR',
                        'Version 1.0.0',
                            () => showAboutDialog(
                          context: context,
                          applicationName: 'TranslateAR',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(
                            Icons.translate,
                            color: Color(0xFF10A37F),
                            size: 40,
                          ),
                          children: [
                            const Text(
                              'Real-time AI translation using NLLB-200 model. Translate conversations directly to your earbuds.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                          side:
                          const BorderSide(color: Color(0xFF1E1E2E)),
                        ),
                        title: const Text('Sign Out',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                        content: const Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(color: Color(0xFF555570)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancel',
                                style:
                                TextStyle(color: Color(0xFF555570))),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Sign Out',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthScreen()),
                              (route) => false,
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.red, size: 17),
                        SizedBox(width: 8),
                        Text('Sign Out',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF10A37F),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Color(0xFF10A37F),
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF444460), fontSize: 12)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 34, color: const Color(0xFF141425));

  Widget _hDivider() => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF141425));

  Widget _option(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFF8888A8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF2A2A3A), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF2A2A3A), size: 18),
          ],
        ),
      ),
    );
  }
}