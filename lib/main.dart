import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation_service.dart';
import 'model_download_screen.dart';
import 'home_screen.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const TranslateARApp());
}

class TranslateARApp extends StatelessWidget {
  const TranslateARApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TranslateAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0F)),
      home: const AppStartup(),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});
  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  String _status = 'Starting...';
  AppTheme _t = const AppTheme(true); // default dark until prefs load

  @override
  void initState() {
    super.initState();
    _loadThemeAndInit();
  }

  Future<void> _loadThemeAndInit() async {
    // Load theme first so splash matches user preference
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode') ?? 'dark';
    final isDark = _resolvedIsDark(savedMode);
    if (mounted) setState(() => _t = AppTheme(isDark));

    // Then proceed with normal startup
    try {
      setState(() => _status = 'Checking models...');
      final downloaded =
      await TranslationService.instance.areModelsDownloaded();
      if (!downloaded) {
        if (!mounted) return;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ModelDownloadScreen()));
        return;
      }
      setState(() => _status = 'Loading translator...');
      await TranslationService.instance.loadModels();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  bool _resolvedIsDark(String mode) {
    if (mode == 'light') return false;
    if (mode == 'dark') return true;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _t.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF10A37F).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF10A37F).withOpacity(0.3),
                    width: 1.5),
              ),
              child: const Icon(Icons.translate,
                  color: Color(0xFF10A37F), size: 44),
            ),
            const SizedBox(height: 24),
            Text('TranslateAR',
                style: TextStyle(
                    color: _t.txPri,
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Offline AI Translation',
                style: TextStyle(color: _t.txSec, fontSize: 13)),
            const SizedBox(height: 40),
            const SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                    color: Color(0xFF10A37F), strokeWidth: 2.5)),
            const SizedBox(height: 16),
            Text(_status,
                style: TextStyle(color: _t.txSec, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}