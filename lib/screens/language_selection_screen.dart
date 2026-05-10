import 'main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String code) async {
    await context.setLocale(Locale(code));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F19), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.language_rounded, size: 80, color: Color(0xFF00E5FF)),
              const SizedBox(height: 40),
              const Text(
                'SELECT LANGUAGE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 50),
              // ZMĚNĚNÉ POŘADÍ: EN, DE, CS
              _langBtn(context, 'ENGLISH', 'en', '🇺🇸'),
              const SizedBox(height: 16),
              _langBtn(context, 'DEUTSCH', 'de', '🇩🇪'),
              const SizedBox(height: 16),
              _langBtn(context, 'ČEŠTINA', 'cs', '🇨🇿'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langBtn(BuildContext context, String label, String code, String flag) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withAlpha(10),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => _selectLanguage(context, code),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
