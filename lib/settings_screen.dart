import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Voice Settings
  double voiceSpeed = 0.5;
  double voiceVolume = 1.0;

  // ANC Setting
  bool ancEnabled = false;

  // Activation Method Settings
  bool shakeToActivate = false;
  bool inAppButton = true;
  bool voiceCommand = false;
  bool doubleTapEarbud = false;
  bool autoActivate = false;
  bool wearDetection = false;
  bool scheduleActivate = false;
  bool volumeButtonHold = false;

  // Auto detect language
  bool autoDetect = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Voice Settings
            _buildSectionTitle('🔊 Voice Settings'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Voice Speed
                  Row(
                    children: [
                      const Icon(
                        Icons.speed,
                        color: Color(0xFF10A37F),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Voice Speed',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        voiceSpeed <= 0.3
                            ? 'Slow'
                            : voiceSpeed <= 0.6
                            ? 'Normal'
                            : 'Fast',
                        style: const TextStyle(
                          color: Color(0xFF10A37F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: voiceSpeed,
                    min: 0.1,
                    max: 1.0,
                    activeColor: const Color(0xFF10A37F),
                    inactiveColor: Colors.grey.withOpacity(0.3),
                    onChanged: (value) {
                      setState(() => voiceSpeed = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // Voice Volume
                  Row(
                    children: [
                      const Icon(
                        Icons.volume_up,
                        color: Color(0xFF10A37F),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Voice Volume',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Text(
                        '${(voiceVolume * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF10A37F),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: voiceVolume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFF10A37F),
                    inactiveColor: Colors.grey.withOpacity(0.3),
                    onChanged: (value) {
                      setState(() => voiceVolume = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Translation Settings
            _buildSectionTitle('🌐 Translation Settings'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildToggle(
                    icon: Icons.auto_awesome,
                    title: 'Auto Detect Language',
                    subtitle: 'Automatically detect spoken language',
                    value: autoDetect,
                    onChanged: (value) {
                      setState(() => autoDetect = value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ANC Settings
            _buildSectionTitle('🎧 Noise Cancellation'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildToggle(
                icon: Icons.noise_control_off,
                title: 'Enable ANC',
                subtitle: 'Block background noise during translation',
                value: ancEnabled,
                onChanged: (value) {
                  setState(() => ancEnabled = value);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Activation Method
            _buildSectionTitle('🤌 Activation Method'),
            const SizedBox(height: 8),
            const Text(
              'Choose how to activate translation',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // 1
                  _buildToggle(
                    icon: Icons.touch_app,
                    title: 'In-App Button',
                    subtitle: 'Use the big button in home screen',
                    value: inAppButton,
                    onChanged: (value) {
                      setState(() => inAppButton = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // 2
                  _buildToggle(
                    icon: Icons.phone_android,
                    title: 'Shake Phone',
                    subtitle: 'Shake phone twice to activate/deactivate',
                    value: shakeToActivate,
                    onChanged: (value) {
                      setState(() => shakeToActivate = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // 3
                  _buildToggle(
                    icon: Icons.mic,
                    title: 'Voice Command',
                    subtitle: 'Say "Hey Translate" to activate',
                    value: voiceCommand,
                    onChanged: (value) {
                      setState(() => voiceCommand = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // 4
                  _buildToggle(
                    icon: Icons.headphones,
                    title: 'Double Tap Earbud',
                    subtitle: 'Double tap your earbud to activate',
                    value: doubleTapEarbud,
                    onChanged: (value) {
                      setState(() => doubleTapEarbud = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // 5
                  _buildToggle(
                    icon: Icons.hearing,
                    title: 'Wear Detection',
                    subtitle: 'Auto activate when earbuds are worn',
                    value: wearDetection,
                    onChanged: (value) {
                      setState(() => wearDetection = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // 6
                  _buildToggle(
                    icon: Icons.auto_mode,
                    title: 'Auto Activate',
                    subtitle: 'Activate when foreign speech is detected',
                    value: autoActivate,
                    onChanged: (value) {
                      setState(() => autoActivate = value);
                    },
                  ),

                  const Divider(color: Colors.grey),

                  // 7
                  _buildToggle(
                    icon: Icons.schedule,
                    title: 'Schedule Activation',
                    subtitle: 'Set time to auto activate translation',
                    value: scheduleActivate,
                    onChanged: (value) {
                      setState(() => scheduleActivate = value);
                    },
                  ),
                  const Divider(color: Colors.grey),

// 8
                  _buildToggle(
                    icon: Icons.volume_down,
                    title: 'Volume Button Hold',
                    subtitle: 'Hold volume down 3 seconds to activate (works with screen off)',
                    value: volumeButtonHold,
                    onChanged: (value) {
                      setState(() => volumeButtonHold = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved!'),
                      backgroundColor: Color(0xFF10A37F),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10A37F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    color: Colors.white,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10A37F)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFF10A37F),
          onChanged: onChanged,
        ),
      ],
    );
  }
}