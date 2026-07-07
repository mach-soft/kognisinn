import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kognisinn/screens/calibration/calibration_screen.dart';
// PŘIDÁNO: Import hlavního menu pro případ přeskočení kalibrace
import 'main_menu_screen.dart'; 
import '../bloc/settings/settings_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasAcceptedDisclaimer = false; 

  final Color accentCyan = const Color(0xFF00E5FF);
  final Color accentPurple = const Color(0xFF7000FF);
  final Color accentOrange = Colors.orangeAccent;
  final Color accentRed = const Color(0xFFFF4B4B); 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding(bool isGamified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);
    
    if (!mounted) return;
    
    // ZMĚNA: Přesměrování na základě zvolené gamifikace
    if (isGamified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CalibrationScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainMenuScreen(isCalibrated: false)),
      );
    }
  }

  void _nextPage() {
    // Načteme aktuální stav gamifikace z BLoCu
    final gamified = context.read<SettingsBloc>().state.showGamifiedValues;
    final totalSlides = gamified ? 6 : 5;
    final disclaimerIndex = totalSlides - 1;

    if (_currentPage < disclaimerIndex) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Jsme na posledním slidu (Disclaimer)
      if (_hasAcceptedDisclaimer) {
        _finishOnboarding(gamified);
      } else {
        Vibration.vibrate(duration: 200); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('onboard_disclaimer_error'.tr()),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _skipToDisclaimer() {
    final gamified = context.read<SettingsBloc>().state.showGamifiedValues;
    final disclaimerIndex = (gamified ? 6 : 5) - 1;
    
    _pageController.animateToPage(
      disclaimerIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          // Obaleno v BlocBuilder, aby Onboarding reagoval na změnu přepínače
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              final bool gamified = state.showGamifiedValues;
              final int totalSlides = gamified ? 6 : 5;
              final int disclaimerIndex = totalSlides - 1;

              // Dynamické sestavení slidů
              List<Widget> slides = [
                // SLIDE 1: Intro
                _buildSlide(
                  icon: Icons.psychology_rounded,
                  title: 'onboard_1_title'.tr(),
                  description: 'onboard_1_desc'.tr(),
                  isTitleHighlighted: true,
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                // SLIDE 2: Insights
                _buildSlide(
                  icon: Icons.insights_rounded,
                  title: 'onboard_2_title'.tr(),
                  description: 'onboard_2_desc'.tr(),
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                // SLIDE 3: Haptika
                _buildSlide(
                  icon: Icons.vibration_rounded,
                  title: 'onboard_haptic_title'.tr(), 
                  description: 'onboard_haptic_desc'.tr(), 
                  iconColor: accentOrange,
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  extraContent: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Vibration.vibrate(duration: 500, amplitude: 255);
                        },
                        icon: const Icon(Icons.waves_rounded, size: 20),
                        label: Text('onboard_haptic_test'.tr()), 
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentOrange,
                          side: BorderSide(color: accentOrange.withAlpha(150), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          AppSettings.openAppSettings(type: AppSettingsType.sound);
                        },
                        icon: Icon(Icons.settings_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                        label: Text(
                          'onboard_haptic_settings'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                                // SLIDE 4: Gamifikace
                _buildSlide(
                  icon: Icons.auto_graph_rounded,
                  title: 'onboarding_gamification_title'.tr(),
                  description: 'onboarding_gamification_desc'.tr(),
                  iconColor: accentCyan,
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  // ZMĚNA: Přesunuto z extraContent pod ikonu
                  contentBelowIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentCyan.withAlpha(50), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'global_settings_gamification'.tr(),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: gamified,
                          activeThumbColor: accentCyan,
                          activeTrackColor: accentCyan.withAlpha(80),
                          onChanged: (val) {
                            context.read<SettingsBloc>().add(ToggleGamification(val));
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              ];

              // SLIDE 5: Start / Rocket (Pouze pokud je zapnutá gamifikace)
              if (gamified) {
                slides.add(
                  _buildSlide(
                    icon: Icons.rocket_launch_rounded,
                    title: 'onboard_3_title'.tr(),
                    description: 'onboard_3_desc'.tr(),
                    iconColor: accentPurple,
                    isDark: isDark,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                  )
                );
              }

              // POSLEDNÍ SLIDE: Medical Disclaimer
              slides.add(
                _buildSlide(
                  icon: Icons.health_and_safety_outlined,
                  title: 'onboard_disclaimer_title'.tr(),
                  description: 'onboard_disclaimer_desc'.tr(),
                  iconColor: accentRed,
                  isDark: isDark,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  extraContent: GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasAcceptedDisclaimer = !_hasAcceptedDisclaimer;
                      });
                      if (_hasAcceptedDisclaimer) Vibration.vibrate(duration: 50);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasAcceptedDisclaimer ? accentRed : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _hasAcceptedDisclaimer,
                            activeColor: accentRed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (bool? value) {
                              setState(() {
                                _hasAcceptedDisclaimer = value ?? false;
                              });
                              if (_hasAcceptedDisclaimer) Vibration.vibrate(duration: 50);
                            },
                          ),
                          Expanded(
                            child: Text(
                              'onboard_disclaimer_checkbox'.tr(),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: _hasAcceptedDisclaimer ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              );

              return Column(
                children: [
                  // --- HORNÍ LIŠTA (Přeskočit) ---
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 10.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedOpacity(
                        opacity: _currentPage == disclaimerIndex ? 0.0 : 1.0, 
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _currentPage == disclaimerIndex ? null : _skipToDisclaimer, 
                          child: Text(
                            'onboard_btn_skip'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white.withAlpha(120) : Colors.black.withAlpha(100), 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- OBSAH SLIDŮ ---
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: slides,
                    ),
                  ),

                  // --- SPODNÍ NAVIGACE ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(totalSlides, (index) => _buildDot(index, isDark, disclaimerIndex)),
                        ),
                        const SizedBox(height: 40),
                        
                        // Hlavní tlačítko CTA
                        AnimatedOpacity(
                          opacity: (_currentPage == disclaimerIndex && !_hasAcceptedDisclaimer) ? 0.5 : 1.0, 
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: _nextPage,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _currentPage == disclaimerIndex
                                        ? [accentRed, accentOrange] 
                                        : (isDark ? const [Color(0xFF23253A), Color(0xFF161828)] : const [Colors.white, Color(0xFFF1F5F9)]),
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _currentPage == disclaimerIndex
                                        ? Colors.transparent 
                                        : (isDark ? Colors.white12 : Colors.black12), 
                                    width: 1.5
                                  ),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
  _currentPage == disclaimerIndex ? 'onboard_btn_start'.tr() : 'onboard_btn_next'.tr(), 
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
    color: _currentPage == disclaimerIndex 
        ? Colors.white 
        : (isDark ? accentCyan : accentPurple), 
  ),
),

                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- POMOCNÉ WIDGETY ---

    Widget _buildSlide({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    Color? iconColor,
    bool isTitleHighlighted = false,
    Widget? contentBelowIcon, // PŘIDÁNO: Widget hned pod ikonu
    Widget? extraContent, 
  }) {
    Color effectiveIconColor = iconColor ?? accentCyan;
    
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveIconColor.withAlpha(isDark ? 15 : 25),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveIconColor.withAlpha(isDark ? 30 : 40),
                      blurRadius: 50,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: Icon(
                  icon,
                  size: 100,
                  color: effectiveIconColor,
                ),
              ),
              
              // NOVÉ: Vykreslení obsahu hned pod ikonou
              if (contentBelowIcon != null) ...[
                const SizedBox(height: 30),
                contentBelowIcon,
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 50),
              ],

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isTitleHighlighted 
                      ? (isDark ? accentCyan : accentPurple) 
                      : textColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
              
              if (extraContent != null) ...[
                const SizedBox(height: 30),
                extraContent,
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDot(int index, bool isDark, int disclaimerIndex) {
    bool isActive = _currentPage == index;
    Color dotColor;
    if (isActive) {
      dotColor = index == disclaimerIndex ? accentRed : (isDark ? accentCyan : accentPurple);
    } else {
      dotColor = isDark ? Colors.white24 : Colors.black26;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: dotColor, 
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive 
            ? [BoxShadow(color: dotColor.withAlpha(100), blurRadius: 10)] 
            : [],
      ),
    );
  }
}
