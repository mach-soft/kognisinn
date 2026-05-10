import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'digit_span/digit_span_screen.dart';
import 'dual_n_back/dual_n_back_screen.dart';
import 'stroop/stroop_screen.dart';
import 'e_corsi/e_corsi_screen.dart';
import 'memory_palace/memory_palace_screen.dart';
import 'global_settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Future<void> _showExitDialog(BuildContext context, bool isDark) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'dialog_exit_title'.tr(),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B), 
            fontWeight: FontWeight.bold
          )
        ),
        content: Text(
          'dialog_exit_body'.tr(),
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('global_btn_stay'.tr(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('global_btn_exit'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);
    
    return PopScope(
      canPop: false, 
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _showExitDialog(context, isDark);
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, 
              end: Alignment.bottomCenter, 
              colors: [bgTop, bgBottom]
            )
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7000FF)]
                      ).createShader(bounds),
                      child: Text(
                        'menu_title'.tr(),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6)
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(15) : const Color(0xFF7000FF).withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFF7000FF).withAlpha(30)),
                      ),
                      child: Text(
                        'menu_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.w800, 
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF), 
                          letterSpacing: 3
                        )
                      ),
                    ),
                    const SizedBox(height: 50),
                    _menuBtn(context, 'menu_btn_dnb'.tr(), Icons.memory_rounded, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DualNBackScreen()))),
                    const SizedBox(height: 18),
                    _menuBtn(context, 'menu_btn_digit_span'.tr(), Icons.onetwothree_rounded, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitSpanScreen()))),
                    const SizedBox(height: 18),
                    _menuBtn(context, 'menu_btn_stroop'.tr(), Icons.palette_rounded, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StroopScreen()))),
                    const SizedBox(height: 18),
                    _menuBtn(context, 'menu_btn_ecorsi'.tr(), Icons.apps_rounded, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ECorsiScreen()))),
                    const SizedBox(height: 18),
                    _menuBtn(context, 'menu_btn_palace'.tr(), Icons.account_balance_rounded, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryPalaceScreen()))),
                    const SizedBox(height: 50),
                    _buildSettingsButton(context, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuBtn(BuildContext context, String title, IconData icon, bool isDark, VoidCallback onTap) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Container(
      width: 320, 
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), 
        boxShadow: isDark ? [BoxShadow(color: accent.withAlpha(15), blurRadius: 20, offset: const Offset(0, 8))] : []
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, 
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF23253A), const Color(0xFF161828)] 
                  : [Colors.white, const Color(0xFFF1F5F9)]
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? accent.withAlpha(40) : accent.withAlpha(30), width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                Icon(icon, size: 24, color: accent),
                const SizedBox(width: 20),
                Text(
                  title, 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, bool isDark) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSettingsScreen())),
      icon: const Icon(Icons.tune_rounded, size: 20),
      label: Text('menu_btn_settings'.tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white54 : Colors.black54,
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
