import 'package:flutter/material.dart';
import 'translation_service.dart';
import 'home_screen.dart';

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});
  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  bool _downloading = false;
  bool _done = false;
  String? _error;
  double _progress = 0;

  Future<void> _download() async {
    setState(() { _downloading = true; _error = null; _progress = 0; });
    try {
      await TranslationService.instance.downloadModels(
        onProgress: (p) => setState(() => _progress = p),
      );
      await TranslationService.instance.loadModels();
      setState(() { _done = true; });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() { _error = e.toString(); _downloading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10A37F).withOpacity(0.3)),
                ),
                child: const Icon(Icons.download_rounded, color: Color(0xFF10A37F), size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Download Tamil Model',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Small 30MB download.\nWorks fully offline after!',
                  style: TextStyle(color: Color(0xFF666680), fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E1E2E)),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(
                        _done ? Icons.check_circle_rounded : Icons.language_rounded,
                        color: _done ? const Color(0xFF10A37F) : const Color(0xFF444460),
                        size: 20),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Tamil Language Model',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
                    const Text('~30 MB', style: TextStyle(color: Color(0xFF444460), fontSize: 12)),
                  ]),
                  if (_downloading && !_done) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: const Color(0xFF1A1A2A),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF10A37F)),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 4,
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10A37F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10A37F).withOpacity(0.2)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.offline_bolt_rounded, color: Color(0xFF10A37F), size: 16),
                  SizedBox(width: 8),
                  Text('Fast • Lightweight • Offline forever',
                      style: TextStyle(color: Color(0xFF10A37F), fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Error: $_error',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                      textAlign: TextAlign.center),
                ),
              if (!_done)
                GestureDetector(
                  onTap: _downloading ? null : _download,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _downloading ? const Color(0xFF0F2A24) : const Color(0xFF10A37F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: _downloading
                        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Color(0xFF10A37F), strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Downloading...', style: TextStyle(color: Color(0xFF10A37F), fontWeight: FontWeight.w600)),
                    ])
                        : Text(_error != null ? 'Retry' : 'Download & Install',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}