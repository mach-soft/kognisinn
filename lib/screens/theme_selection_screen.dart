import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings/settings_bloc.dart'; 
import 'onboarding_screen.dart'; // OPRAVENÝ IMPORT

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  Future<void> _selectThemeAndContinue(BuildContext context, bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);

    if (!context.mounted) return;

    context.read<SettingsBloc>().add(UpdateTheme(isDark));

    // OPRAVENÉ PŘESMĚROVÁNÍ (nyní vede na Onboarding)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFF00E5FF);
    const Color textColor = Colors.white;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter, 
            colors: [Color(0xFF0B0F19), Color(0xFF1A1A2E)], 
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.palette_rounded, 
                  size: 80, 
                  color: accentColor,
                ),
                const SizedBox(height: 32),
                Text(
                  'choose_theme_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'choose_theme_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),

                _ThemeCard(
                  title: 'theme_light'.tr(),
                  icon: Icons.wb_sunny_rounded,
                  color: Colors.orange,
                  onTap: () => _selectThemeAndContinue(context, false),
                ),
                const SizedBox(height: 16),

                _ThemeCard(
                  title: 'theme_dark'.tr(),
                  icon: Icons.nightlight_round,
                  color: Colors.indigoAccent,
                  onTap: () => _selectThemeAndContinue(context, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15), 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
