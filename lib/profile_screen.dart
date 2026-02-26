import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // List of 200 languages
  final List<Map<String, String>> languages = [
    {'name': 'Tamil', 'code': 'tam_Taml'},
    {'name': 'English', 'code': 'eng_Latn'},
    {'name': 'Hindi', 'code': 'hin_Deva'},
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
    {'name': 'Telugu', 'code': 'tel_Telu'},
    {'name': 'Malayalam', 'code': 'mal_Mlym'},
    {'name': 'Kannada', 'code': 'kan_Knda'},
    {'name': 'Bengali', 'code': 'ben_Beng'},
    {'name': 'Urdu', 'code': 'urd_Arab'},
    {'name': 'Turkish', 'code': 'tur_Latn'},
    {'name': 'Dutch', 'code': 'nld_Latn'},
  ];

  String selectedLanguage = 'Tamil';
  String selectedLanguageCode = 'tam_Taml';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Profile Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF10A37F),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ??
                        'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10A37F),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF212121),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // Native Language Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: Color(0xFF10A37F),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Native Language',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Translations will be done to this language',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF212121),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedLanguage,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: languages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['name'],
                          child: Text(lang['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLanguage = value!;
                          selectedLanguageCode = languages.firstWhere(
                                (l) => l['name'] == value,
                          )['code']!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('Total', '24', 'Translations'),
                  _buildDivider(),
                  _buildStat('Today', '5', 'Translations'),
                  _buildDivider(),
                  _buildStat('Languages', '3', 'Used'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Settings Options
            _buildOption(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildOption(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            _buildOption(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {},
            ),
            _buildOption(
              icon: Icons.info,
              title: 'About TranslateAR',
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                          (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF10A37F),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF10A37F)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}