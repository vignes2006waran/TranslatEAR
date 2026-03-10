import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'app_theme.dart';

class EarbudScreen extends StatefulWidget {
  const EarbudScreen({super.key});

  @override
  State<EarbudScreen> createState() => _EarbudScreenState();
}

class _EarbudScreenState extends State<EarbudScreen>
    with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('bluetooth_devices');
  List<Map<String, String>> devices = [];
  Map<String, String>? selectedDevice;
  bool isLoading = false;
  late AppTheme _t;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _earbudKeywords = [
    'ear', 'bud', 'pod', 'headphone', 'headset', 'airpod',
    'galaxy buds', 'nothing', 'pixel buds', 'jabra', 'sony',
    'beats', 'bose', 'sennheiser', 'jbl', 'anker', 'soundcore',
    'tws', 'true wireless', 'bt', 'wh-', 'wf-', 'ep-'
  ];

  @override
  void initState() {
    super.initState();
    _t = const AppTheme(true);
    _loadTheme();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _getDevices();
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  bool _isEarbud(String name) {
    final lower = name.toLowerCase();
    return _earbudKeywords.any((k) => lower.contains(k));
  }

  Future<void> _getDevices() async {
    setState(() => isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      final List<dynamic> result =
      await platform.invokeMethod('getConnectedDevices');
      final fetched = result.map((d) => Map<String, String>.from(d)).toList();

      Map<String, String>? autoSelected;
      for (final d in fetched) {
        if (_isEarbud(d['name'] ?? '')) {
          autoSelected = d;
          break;
        }
      }
      if (autoSelected == null && fetched.isNotEmpty) {
        autoSelected = fetched.first;
      }

      setState(() {
        devices = fetched;
        selectedDevice = autoSelected;
        isLoading = false;
      });
    } catch (e) {
      print('Bluetooth error: $e');
      setState(() => isLoading = false);
    }
  }

  void _goHome() {
    if (selectedDevice != null) {
      ConnectedEarbud.name = selectedDevice!['name'];
      ConnectedEarbud.address = selectedDevice!['address'];
    }
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.bg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Header ──────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10A37F).withOpacity(0.2),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 86, height: 86,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10A37F).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF10A37F).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.headphones_rounded,
                                size: 40, color: Color(0xFF10A37F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Connect Earbuds',
                        style: TextStyle(
                          color: _t.txPri,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your earbuds to continue',
                        style: TextStyle(color: _t.txSec, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Refresh button ──────────────────────────────────────────
                GestureDetector(
                  onTap: isLoading ? null : _getDevices,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _t.bar,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                          color: const Color(0xFF10A37F).withOpacity(0.3)),
                      boxShadow: _t.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isLoading
                            ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Color(0xFF10A37F), strokeWidth: 2),
                        )
                            : const Icon(Icons.refresh_rounded,
                            color: Color(0xFF10A37F), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isLoading ? 'Searching...' : 'Refresh Devices',
                          style: const TextStyle(
                            color: Color(0xFF10A37F),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Count + auto-select notice ──────────────────────────────
                Row(children: [
                  Text(
                    '${devices.length} device(s) found',
                    style: TextStyle(color: _t.txSec, fontSize: 13),
                  ),
                  if (selectedDevice != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10A37F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Auto-selected',
                        style: TextStyle(
                            color: Color(0xFF10A37F),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ]),

                const SizedBox(height: 12),

                // ── Device list ─────────────────────────────────────────────
                Expanded(
                  child: devices.isEmpty && !isLoading
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
                          child: Icon(Icons.headphones_rounded,
                              size: 36, color: _t.txDead),
                        ),
                        const SizedBox(height: 16),
                        Text('No earbuds connected',
                            style: TextStyle(
                                color: _t.txSec,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          'Connect your earbuds via\nBluetooth and tap refresh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _t.txDead, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final isSelected =
                          selectedDevice?['address'] == device['address'];
                      final isEarbudDevice =
                      _isEarbud(device['name'] ?? '');

                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedDevice = device),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF10A37F).withOpacity(0.08)
                                : _t.bar,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF10A37F).withOpacity(0.5)
                                  : _t.bdr,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: _t.cardShadow,
                          ),
                          child: Row(children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10A37F)
                                    .withOpacity(0.15)
                                    : _t.iconBg,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                isEarbudDevice
                                    ? Icons.headphones_rounded
                                    : Icons.bluetooth_rounded,
                                color: isSelected
                                    ? const Color(0xFF10A37F)
                                    : _t.txSec,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(
                                      device['name'] ?? 'Unknown Device',
                                      style: TextStyle(
                                        color: isSelected
                                            ? _t.txPri
                                            : _t.txSec,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (isEarbudDevice) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10A37F)
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Earbuds',
                                          style: TextStyle(
                                            color: Color(0xFF10A37F),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 3),
                                  Text(
                                    device['address'] ?? '',
                                    style: TextStyle(
                                        color: _t.txMut, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24, height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10A37F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 14),
                              ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Continue button ─────────────────────────────────────────
                GestureDetector(
                  onTap: _goHome,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: selectedDevice != null
                          ? const Color(0xFF10A37F)
                          : const Color(0xFF10A37F).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selectedDevice != null
                          ? [
                        BoxShadow(
                          color: const Color(0xFF10A37F).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        selectedDevice != null
                            ? 'Continue with ${selectedDevice!['name']}'
                            : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Skip ────────────────────────────────────────────────────
                GestureDetector(
                  onTap: _goHome,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                        color: _t.txSec,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}