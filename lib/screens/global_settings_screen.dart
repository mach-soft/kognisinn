// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'; 
import '../bloc/settings/settings_bloc.dart';
import 'about_app_screen.dart';

class GlobalSettingsScreen extends StatelessWidget {
  const GlobalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        bool isDark = state.isDarkMode;
        final Color accentColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
        final Color cardBg = isDark ? Colors.white.withAlpha(15) : accentColor.withAlpha(10);
        final Color borderColor = isDark ? Colors.white12 : accentColor.withAlpha(30);
        final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

        return WillPopScope(
          onWillPop: () async => true,
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, 
                  end: Alignment.bottomCenter, 
                  colors: isDark 
                    ? [const Color(0xFF0B0F19), const Color(0xFF1A1A2E)] 
                    : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)]
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      iconTheme: IconThemeData(color: textColor),
                      title: Text(
                        'settings_title'.tr(), 
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 16)
                      ),
                      centerTitle: true,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _sectionTitle('settings_section_graphics'.tr(), accentColor),
                          _card(cardBg, borderColor, SwitchListTile(
                            title: Text('settings_dark_mode'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            subtitle: Text(state.isDarkMode ? 'settings_dark_mode_on'.tr() : 'settings_dark_mode_off'.tr(), style: const TextStyle(fontSize: 12)),
                            value: state.isDarkMode,
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withAlpha(80),
                            onChanged: (val) => context.read<SettingsBloc>().add(UpdateTheme(val)),
                          )),
                          
                          const SizedBox(height: 32),

                          _sectionTitle('settings_section_sounds'.tr(), accentColor),
                          _card(cardBg, borderColor, Column(
                            children: [
                              SwitchListTile(
                                title: Text('settings_mute_all'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                value: state.isMuted,
                                activeThumbColor: Colors.redAccent,
                                activeTrackColor: Colors.redAccent.withAlpha(80),
                                onChanged: (val) => context.read<SettingsBloc>().add(ToggleMute(val)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.volume_down, color: accentColor, size: 20),
                                    Expanded(child: Slider(
                                      value: state.volume,
                                      activeColor: accentColor,
                                      onChanged: state.isMuted ? null : (v) => context.read<SettingsBloc>().add(UpdateVolume(v)),
                                    )),
                                    Icon(Icons.volume_up, color: accentColor, size: 20),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: borderColor),
                              SwitchListTile(
                                title: Text('settings_haptic_feedback'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                subtitle: Text('settings_haptic_desc'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                                value: state.isHapticEnabled,
                                activeThumbColor: accentColor,
                                activeTrackColor: accentColor.withAlpha(80),
                                onChanged: (val) => context.read<SettingsBloc>().add(ToggleHaptic(val)),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('settings_haptic_duration'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text('${state.hapticDuration} ms', style: TextStyle(color: state.isHapticEnabled ? accentColor : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.vibration_rounded, color: state.isHapticEnabled ? accentColor : Colors.grey, size: 18),
                                        Expanded(
                                          child: Slider(
                                            value: state.hapticDuration.toDouble(),
                                            min: 100.0,
                                            max: 800.0,
                                            divisions: 7, 
                                            activeColor: state.isHapticEnabled ? accentColor : Colors.grey,
                                            inactiveColor: isDark ? Colors.white12 : Colors.black12,
                                            onChanged: state.isHapticEnabled ? (v) => context.read<SettingsBloc>().add(UpdateHapticDuration(v.round())) : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )),

                          const SizedBox(height: 32),

                          _sectionTitle('settings_section_time_format'.tr(), accentColor),
                          _card(cardBg, borderColor, Column(
                            children: [
                              RadioListTile<bool>(
                                title: Text('settings_time_format_24h'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                value: true,
                                groupValue: state.is24HourFormat,
                                activeColor: accentColor,
                                onChanged: (val) => context.read<SettingsBloc>().add(UpdateTimeFormat(true)),
                              ),
                              RadioListTile<bool>(
                                title: Text('settings_time_format_12h'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                value: false,
                                groupValue: state.is24HourFormat,
                                activeColor: accentColor,
                                onChanged: (val) => context.read<SettingsBloc>().add(UpdateTimeFormat(false)),
                              ),
                            ],
                          )),

                          const SizedBox(height: 32),

                          _sectionTitle('settings_section_language'.tr(), accentColor),
                          _card(cardBg, borderColor, Column(
                            children: [
                              _langTile(context, 'English', 'en', '🇺🇸', textColor),
                              _langTile(context, 'Deutsch', 'de', '🇩🇪', textColor),
                              _langTile(context, 'Čeština', 'cs', '🇨🇿', textColor),
                            ],
                          )),
                          
                          const SizedBox(height: 32),
                          
                          // Nové tlačítko O aplikaci
                          _card(cardBg, borderColor, ListTile(
                            leading: Icon(Icons.info_outline_rounded, color: accentColor),
                            title: Text('settings_about_app'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen())),
                          )),
                          
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
  );

  Widget _card(Color bg, Color border, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: bg, 
      borderRadius: BorderRadius.circular(24), 
      border: Border.all(color: border, width: 1.5)
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _langTile(BuildContext context, String label, String code, String flag, Color textColor) {
    bool isSel = context.locale.languageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: TextStyle(color: textColor, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF)) : null,
      onTap: () => context.setLocale(Locale(code)),
    );
  }
}
