import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Single source of truth for all theme colors ──────────────
const kAccent = Color(0xFF10A37F);

class AppTheme {
  final bool isDark;
  const AppTheme(this.isDark);

  // backgrounds
  Color get bg     => isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF7F7F8);
  Color get card   => isDark ? const Color(0xFF0C0C18) : const Color(0xFFFFFFFF);
  Color get bar    => isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFFFFFF);

  // borders
  Color get bdr    => isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE5E5E5);
  Color get bdr2   => isDark ? const Color(0xFF141425) : const Color(0xFFEEEEEE);
  Color get bdr3   => isDark ? const Color(0xFF1A1A2A) : const Color(0xFFDDDDDD);

  // text
  Color get txPri  => isDark ? Colors.white            : const Color(0xFF0D0D0D);
  Color get txSec  => isDark ? const Color(0xFF8888A8) : const Color(0xFF555570);
  Color get txMut  => isDark ? const Color(0xFF444460) : const Color(0xFF8E8EA0);
  Color get txDead => isDark ? const Color(0xFF2A2A3A) : const Color(0xFFCCCCCC);
  Color get txDd2  => isDark ? const Color(0xFF2E2E45) : const Color(0xFFAAAAAA);
  Color get txNav  => isDark ? const Color(0xFF555570) : const Color(0xFFAAAAAA);

  // dividers / separators
  Color get divider => isDark ? const Color(0xFF141425) : const Color(0xFFEEEEEE);

  // icon bg
  Color get iconBg => isDark ? const Color(0xFF1A1A2A) : const Color(0xFFEEEEEE);

  // card shadows (light mode only)
  List<BoxShadow> get cardShadow => isDark ? [] : [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))
  ];

  List<BoxShadow> get barShadow => isDark ? [] : [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))
  ];

  static Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_dark_mode') ?? true;
  }

  static Future<void> save(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }
}