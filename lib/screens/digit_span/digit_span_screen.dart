import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/digit_span/digit_span_bloc.dart';
import '../../bloc/digit_span/digit_span_event.dart';
import '../../bloc/digit_span/digit_span_state.dart';

class DigitSpanScreen extends StatelessWidget {
  const DigitSpanScreen({super.key});

  Future<bool> _showInterruptDialog(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('global_interrupt_title'.tr(), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        content: Text('ds_interrupt_body'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('global_btn_stay'.tr(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('global_btn_exit'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
        ],
      )
    ) ?? false;
  }

  void _showModuleInfoDialog(BuildContext context, bool isDark, Color accent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.psychology_rounded, color: accent),
            const SizedBox(width: 10),
            Expanded(child: Text('ds_title'.tr(), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('module_info_goal'.tr(), 'ds_info_goal_desc'.tr(), Icons.track_changes_rounded, accent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_rules'.tr(), 'ds_info_rules_desc'.tr(), Icons.rule_rounded, Colors.orangeAccent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_practice'.tr(), 'ds_info_prac_desc'.tr(), Icons.lightbulb_outline_rounded, const Color(0xFF00E676), isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogSection(String title, String content, IconData icon, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 6),
        Text(content, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);

    return BlocProvider(
      create: (context) => DigitSpanBloc()..add(InitializeHardwareEvent()),
      child: BlocConsumer<DigitSpanBloc, DigitSpanState>(
        listenWhen: (previous, current) {
          return previous.phase != GamePhase.gameOver && current.phase == GamePhase.gameOver;
        },
        listener: (context, state) async {
          // Záměrně prázdné - BLoC se stará o veškeré ukládání sám (Single Source of Truth)
        },
        builder: (context, state) {
          bool showBackgroundEffects = state.isEmphaticMode && state.isGamificationEnabled && state.gameType == GameType.gameMode;

          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == GamePhase.menu || state.phase == GamePhase.splash) {
                return true;
              } else if (state.phase == GamePhase.settings || state.phase == GamePhase.showingResults || state.phase == GamePhase.choosingMode || state.phase == GamePhase.choosingLevel) {
                context.read<DigitSpanBloc>().add(ReturnToMenuEvent());
                return false;
              } else {
                bool quit = await _showInterruptDialog(context, isDark);
                if (!context.mounted) return false;
                if (quit) context.read<DigitSpanBloc>().add(ReturnToMenuEvent());
                return false;
              }
            },
            child: Scaffold(
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  border: showBackgroundEffects
                      ? Border.all(color: const Color(0xFF00E5FF), width: 4)
                      : Border.all(color: Colors.transparent, width: 4),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, 
                    colors: showBackgroundEffects
                        ? [isDark ? const Color(0xFF101B2B) : const Color(0xFFE0F7FA), bgBottom]
                        : [bgTop, bgBottom]
                  )
                ),
                child: SafeArea(
                  child: state.phase == GamePhase.splash
                      ? _buildSplash(context)
                      : Column(
                          children: [
                            _buildHeader(isDark, state),
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: _buildBody(context, state, isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, DigitSpanState state) {
    if (state.phase == GamePhase.showingSequence || state.phase == GamePhase.waitingForInput || state.phase == GamePhase.showingSuccess || state.phase == GamePhase.showingFailure) {
      return const SizedBox(height: 20);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7000FF)]).createShader(bounds),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.onetwothree, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Text('ds_title'.tr(), style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplash(BuildContext context) {
    Future.microtask(() { if (context.mounted) context.read<DigitSpanBloc>().add(SplashFinishedEvent()); });
    return const SizedBox.shrink();
  }

  Widget _buildBody(BuildContext context, DigitSpanState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    switch (state.phase) {
      case GamePhase.menu:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Icon(Icons.onetwothree_rounded, size: 80, color: accent.withAlpha(150)),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showModuleInfoDialog(context, isDark, accent),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withAlpha(20),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withAlpha(50)),
                          ),
                          child: Icon(Icons.help_outline_rounded, size: 20, color: accent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              _menuBtn(context, 'ds_mode_fast'.tr(), () {
                context.read<DigitSpanBloc>().add(SetLanguageEvent(context.locale.languageCode));
                context.read<DigitSpanBloc>().add(const SelectGameTypeEvent(GameType.fastTest));
              }, isDark, icon: Icons.bolt_rounded, isPrimary: true),
              const SizedBox(height: 16),
              
              _menuBtn(context, 'ds_mode_continuous'.tr(), () {
                context.read<DigitSpanBloc>().add(SetLanguageEvent(context.locale.languageCode));
                context.read<DigitSpanBloc>().add(const SelectGameTypeEvent(GameType.gameMode));
              }, isDark, icon: Icons.play_arrow_rounded),
              const SizedBox(height: 16),
              
              _menuBtn(context, 'ds_mode_free'.tr(), () {
                context.read<DigitSpanBloc>().add(SetLanguageEvent(context.locale.languageCode));
                context.read<DigitSpanBloc>().add(const SelectGameTypeEvent(GameType.training));
              }, isDark, icon: Icons.model_training_rounded),
              const SizedBox(height: 40),
              
              _menuBtn(context, 'global_analytics'.tr(), () => context.read<DigitSpanBloc>().add(ShowResultsEvent()), isDark, icon: Icons.insights_rounded, isSecondary: true),
              const SizedBox(height: 16),
              _menuBtn(context, 'global_settings'.tr(), () => context.read<DigitSpanBloc>().add(ShowSettingsEvent()), isDark, icon: Icons.tune_rounded, isSecondary: true),
              const SizedBox(height: 32),
              _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.of(context).pop(), isDark, icon: Icons.power_settings_new_rounded, isDanger: true),
            ],
          ),
        );

      case GamePhase.settings:
        return _neuroCard(isDark, accent, Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ds_settings_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
              const SizedBox(height: 30),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text('ds_settings_gamification'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent.withAlpha(40)),
                      ),
                      child: Text('ds_mode_continuous'.tr().toUpperCase(), style: TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('ds_settings_gamification_desc'.tr(), style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
                ),
                trailing: Switch(
                  value: state.isGamificationEnabled,
                  activeThumbColor: accent,
                  onChanged: (val) {
                    context.read<DigitSpanBloc>().add(ToggleGamificationEvent(val));
                  },
                ),
              ),
              const Divider(color: Colors.white12),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('ds_settings_dictation'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                trailing: DropdownButton<SoundSetting>(
                  dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  value: state.soundSetting == SoundSetting.numbersOnly ? SoundSetting.off : state.soundSetting,
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  onChanged: (val) => context.read<DigitSpanBloc>().add(ChangeSettingsEvent(sound: val)),
                  items: [
                    DropdownMenuItem(value: SoundSetting.off, child: Text("ds_settings_visual_only".tr())),
                    DropdownMenuItem(value: SoundSetting.numbersAndFeedback, child: Text("ds_settings_full_feedback".tr())),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              
              Text('ds_settings_speed'.tr(), style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
              Slider(
                activeColor: accent,
                value: state.speedFactor, min: 0.5, max: 1.5, divisions: 10,
                onChanged: (val) => context.read<DigitSpanBloc>().add(ChangeSettingsEvent(speed: val)),
              ),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              
              Text('${'ds_settings_fast_start'.tr()}: ${state.fastTestStartingLevel}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
              Slider(
                activeColor: accent,
                value: state.fastTestStartingLevel.toDouble(), min: 3, max: 12, divisions: 9,
                onChanged: (val) => context.read<DigitSpanBloc>().add(ChangeSettingsEvent(fastStartLevel: val.toInt())),
              ),
              
              const SizedBox(height: 30),
              _menuBtn(context, 'global_btn_save'.tr(), () => context.read<DigitSpanBloc>().add(ReturnToMenuEvent()), isDark, isPrimary: true),
            ],
          ),
        );

      case GamePhase.choosingLevel:
        return _neuroCard(isDark, accent, Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ds_level_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: Icon(Icons.remove_circle_outline, size: 40, color: accent), onPressed: () => context.read<DigitSpanBloc>().add(const ChangeTrainingLevelEvent(-1))),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    width: 100, alignment: Alignment.center,
                    child: Text('${state.sequenceLength}', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: textColor)),
                  ),
                  IconButton(icon: Icon(Icons.add_circle_outline, size: 40, color: accent), onPressed: () => context.read<DigitSpanBloc>().add(const ChangeTrainingLevelEvent(1))),
                ],
              ),
              const SizedBox(height: 40),
              _menuBtn(context, 'ds_btn_init'.tr(), () => context.read<DigitSpanBloc>().add(PlayNextRoundEvent()), isDark, isPrimary: true),
              const SizedBox(height: 10),
              TextButton(onPressed: () => context.read<DigitSpanBloc>().add(ReturnToMenuEvent()), child: Text('global_btn_back'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 2))),
            ],
          ),
        );

      case GamePhase.choosingMode:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ds_select_mode_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
            const SizedBox(height: 30),
            _menuBtn(context, 'ds_mode_forward'.tr(), () => context.read<DigitSpanBloc>().add(const ModeSelectedEvent(GameMode.forward)), isDark, icon: Icons.arrow_forward_rounded),
            const SizedBox(height: 16),
            _menuBtn(context, 'ds_mode_reverse'.tr(), () => context.read<DigitSpanBloc>().add(const ModeSelectedEvent(GameMode.reverse)), isDark, icon: Icons.keyboard_double_arrow_left_rounded),
            const SizedBox(height: 16),
            _menuBtn(context, 'ds_mode_ascending'.tr(), () => context.read<DigitSpanBloc>().add(const ModeSelectedEvent(GameMode.ascending)), isDark, icon: Icons.sort_rounded),
            const SizedBox(height: 30),
            TextButton(onPressed: () => context.read<DigitSpanBloc>().add(ReturnToMenuEvent()), child: Text('global_btn_cancel'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 2))),
          ],
        );

      case GamePhase.showingSequence:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isGamificationEnabled && state.gameType == GameType.gameMode) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withAlpha(40))),
                child: Text('ds_status_info'.tr(args: [_translateMode(state.gameMode).toUpperCase(), state.sequenceLength.toString()]),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
              ),
              if (state.consecutiveSuccesses >= 5) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Úspěchů v řadě: ${state.consecutiveSuccesses}',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 60),
            Text(
              state.currentlyDisplayedDigit,
              key: ValueKey(state.currentlyDisplayedDigit),
              style: TextStyle(
                fontSize: 160, 
                fontWeight: FontWeight.w900, 
                color: textColor, 
                shadows: state.isEmphaticMode && state.isGamificationEnabled && state.gameType == GameType.gameMode 
                    ? [Shadow(color: accent.withAlpha(150), blurRadius: 30)] : []
              ),
            ),
            const SizedBox(height: 80),
          ],
        );

      case GamePhase.showingFailure:
        return _buildStatusMessage('ds_phase_interrupted'.tr(), Icons.bolt_rounded, Colors.redAccent, isDark);

      case GamePhase.showingSuccess:
        return _buildStatusMessage('ds_phase_success'.tr(), Icons.check_circle_rounded, const Color(0xFF00E676), isDark);

      case GamePhase.waitingForInput:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isGamificationEnabled && state.gameType == GameType.gameMode) ...[
              Text('ds_phase_reconstruct'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 4)),
              if (state.consecutiveSuccesses >= 5) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Úspěchů v řadě: ${state.consecutiveSuccesses}',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                state.userInput.padRight(state.expectedSequence.length, '_').split('').join(' '),
                style: TextStyle(fontSize: 44, letterSpacing: 8, fontWeight: FontWeight.w900, color: textColor),
              ),
            ),
            const SizedBox(height: 40),
            _buildNeuroNumpad(context, state, isDark, accent),
            const SizedBox(height: 40),
            if (state.gameType == GameType.gameMode)
              _menuBtn(context, 'ds_btn_save_exit'.tr(), () => context.read<DigitSpanBloc>().add(SaveGameAndExitEvent()), isDark, isPrimary: true, icon: Icons.save_rounded),
          ],
        );

      case GamePhase.gameOver:
        return _neuroCard(isDark, accent, Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.redAccent),
              const SizedBox(height: 10),
              Text('ds_capacity_empty'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2)),
              const SizedBox(height: 24),
              _resRow('ds_res_shown'.tr(), state.currentSequence.join(' '), isDark),
              _resRow('ds_res_entered'.tr(), state.userInput.isEmpty ? '---' : state.userInput.split('').join(' '), isDark),
              _resRow('ds_res_target'.tr(), state.expectedSequence.join(' '), isDark, color: const Color(0xFF00E676)),
              const SizedBox(height: 32),
              _menuBtn(context, 'global_btn_restart'.tr(), () {
                if (state.gameType == GameType.training) {
                  context.read<DigitSpanBloc>().add(const SelectGameTypeEvent(GameType.training));
                } else {
                  context.read<DigitSpanBloc>().add(PlayNextRoundEvent());
                }
              }, isDark, isPrimary: true),
              const SizedBox(height: 16),
              _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<DigitSpanBloc>().add(ReturnToMenuEvent()), isDark, isSecondary: true),
            ],
          ),
        );

      case GamePhase.showingResults:
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final prefs = snapshot.data!;
            // Získání čisté historie v naturálním formátu 
            List<String> rawHistory = prefs.getStringList('ds_raw_history') ?? [];

            return Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: _neuroCard(isDark, accent, Column(
                      children: [
                        Text('ds_analytics_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _scBadge('ds_badge_seq'.tr(), state.highScores[GameMode.forward] ?? 0, accent, isDark),
                            _scBadge('ds_badge_rev'.tr(), state.highScores[GameMode.reverse] ?? 0, accent, isDark),
                            _scBadge('ds_badge_asc'.tr(), state.highScores[GameMode.ascending] ?? 0, accent, isDark),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _buildGraph(context, rawHistory, isDark, true, state.isGamificationEnabled), 
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _menuBtn(context, 'global_btn_back'.tr(), () => context.read<DigitSpanBloc>().add(ReturnToMenuEvent()), isDark),
                const SizedBox(height: 10),
              ],
            );
          }
        );

      default: return const Center(child: CircularProgressIndicator());
    }
  }

  // --- NOVÝ DIGIT SPAN GRAF ---
  Widget _buildGraph(BuildContext context, List<String> rawHistory, bool isDark, bool is24h, bool isGamificationEnabled) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    
    if (rawHistory.isEmpty) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text('global_no_data'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          )
      );
    }

    List<Map<String, dynamic>> parsedHistory = [];
    double maxY = 1.0;
    
    for (var item in rawHistory) {
      if (!item.contains('|')) continue;
      final parts = item.split('|');
      if (parts.length >= 3) {
        DateTime date = DateTime.tryParse(parts[0]) ?? DateTime.now();
        GameMode mode = GameMode.values.firstWhere((e) => e.name == parts[1], orElse: () => GameMode.forward);
        double span = double.tryParse(parts[2]) ?? 0.0;
        
        // ZMĚNA: Přepočet na KCI za letu pro graf, pokud je gamifikace aktivní
        double finalValue = isGamificationEnabled 
            ? DigitSpanBloc.calculateKci(span, mode).toDouble() 
            : span;
            
        if (finalValue > maxY) maxY = finalValue;
        
        parsedHistory.add({'date': date, 'mode': mode, 'value': finalValue, 'rawSpan': span});
      }
    }

    if (parsedHistory.isEmpty) return const SizedBox.shrink();

    final DateFormat dateFormat = DateFormat('dd.MM.yyyy');
    Map<String, List<Map<String, dynamic>>> groupedHistory = {};
    for (var item in parsedHistory) {
      String dayKey = dateFormat.format(item['date']);
      if (!groupedHistory.containsKey(dayKey)) groupedHistory[dayKey] = [];
      groupedHistory[dayKey]!.add(item);
    }

    List<Widget> graphColumns = [];
    
    groupedHistory.forEach((dateString, dayItems) {
      graphColumns.add(
        Padding(
          padding: const EdgeInsets.only(right: 16.0), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              Container(width: 2, height: 140, color: isDark ? Colors.white12 : Colors.black12), 
              const SizedBox(height: 12),
              Text(dateString, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: accent)),
            ],
          ),
        )
      );

      for (var item in dayItems) {
        double heightFactor = item['value'] / (maxY > 0 ? maxY : 1);
        Color barColor = accent; 
        
        // Vizuální odlišení módů
        if (item['mode'] == GameMode.reverse) barColor = const Color(0xFFFF007F);
        if (item['mode'] == GameMode.ascending) barColor = const Color(0xFF00E676);

        String timeStr = is24h 
            ? DateFormat('HH:mm').format(item['date']) 
            : DateFormat('h:mm a').format(item['date']);

        graphColumns.add(
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${item['value'].toInt()}', style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Container(
                  width: 34, 
                  height: 120 * heightFactor + 10, 
                  decoration: BoxDecoration(
                    color: barColor, 
                    borderRadius: BorderRadius.circular(8), 
                    boxShadow: [BoxShadow(color: barColor.withAlpha(80), blurRadius: 6)]
                  )
                ),
                const SizedBox(height: 10),
                Text(timeStr, style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                if (isGamificationEnabled) 
                  Text('(${item['rawSpan'].toInt()})', style: TextStyle(fontSize: 8, color: isDark ? Colors.white38 : Colors.black38)),
                const SizedBox(height: 16), 
              ],
            ),
          )
        );
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5), 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : accent.withAlpha(5), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20))
      ),
      child: Column(
        children: [
          Text(isGamificationEnabled ? 'KCI HISTORIE' : 'HISTORIE KAPACIT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white : const Color(0xFF1E293B))), 
          const SizedBox(height: 24),
          SizedBox(
            height: 260, 
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, 
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: graphColumns,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusMessage(String text, IconData icon, Color color, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(20), boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 40)]),
            child: Icon(icon, size: 100, color: color),
          ),
          const SizedBox(height: 30),
          Text(text, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: color)),
        ],
      ),
    );
  }

  Widget _buildNeuroNumpad(BuildContext context, DigitSpanState state, bool isDark, Color accent) {
    return SizedBox(
      width: 320,
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.3, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (index == 9) return const SizedBox.shrink();
          if (index == 11) {
            return InkWell(
              onTap: () => context.read<DigitSpanBloc>().add(BackspacePressedEvent()),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(color: Colors.redAccent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withAlpha(50))),
                child: const Icon(Icons.backspace_rounded, color: Colors.redAccent),
              ),
            );
          }
          int n = index == 10 ? 0 : index + 1;
          return InkWell(
            onTap: () => context.read<DigitSpanBloc>().add(NumberPressedEvent(n)),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isDark ? [const Color(0xFF23253A), const Color(0xFF161828)] : [Colors.white, const Color(0xFFF1F5F9)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(30), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(n.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isDark ? Colors.white : accent)),
            ),
          );
        },
      ),
    );
  }

  Widget _neuroCard(bool isDark, Color accent, Widget child, {double padding = 24}) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(color: accent.withAlpha(15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _menuBtn(BuildContext context, String label, VoidCallback onTap, bool isDark, {IconData? icon, bool isPrimary = false, bool isSecondary = false, bool isDanger = false}) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? (isSecondary ? Colors.white54 : Colors.white) : (isSecondary ? Colors.black54 : const Color(0xFF1E293B));
    
    return Container(
      width: 320, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: (isPrimary && isDark) ? [BoxShadow(color: accent.withAlpha(30), blurRadius: 20, offset: const Offset(0, 5))] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSecondary ? null : LinearGradient(colors: isDark ? [const Color(0xFF23253A), const Color(0xFF161828)] : [Colors.white, const Color(0xFFF1F5F9)]),
              color: isSecondary ? Colors.transparent : (isDanger ? Colors.redAccent.withAlpha(20) : null),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDanger ? Colors.redAccent.withAlpha(50) : (isSecondary ? (isDark ? Colors.white12 : Colors.black12) : (isDark ? accent.withAlpha(40) : accent.withAlpha(30))), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 22, color: isDanger ? Colors.redAccent : textColor), const SizedBox(width: 12)],
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDanger ? Colors.redAccent : textColor, letterSpacing: 1.5)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scBadge(String label, int score, Color accent, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: accent.withAlpha(15), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withAlpha(30))),
          child: Text(score > 0 ? score.toString() : '---', style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  String _translateMode(GameMode mode) {
    switch (mode) {
      case GameMode.forward: return 'ds_tr_forward'.tr();
      case GameMode.reverse: return 'ds_tr_reverse'.tr();
      case GameMode.ascending: return 'ds_tr_ascending'.tr();
    }
  }

  Widget _resRow(String label, String value, bool isDark, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color ?? (isDark ? Colors.white : Colors.black87), letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
