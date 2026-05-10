import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);

    return BlocProvider(
      create: (context) => DigitSpanBloc()..add(InitializeHardwareEvent()),
      child: BlocBuilder<DigitSpanBloc, DigitSpanState>(
        builder: (context, state) {
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
              body: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])),
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
              // NOVÁ VELKÁ IKONA V MENU MODULU
              Icon(Icons.onetwothree_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF).withAlpha(150) : const Color(0xFF7000FF).withAlpha(150)),
              const SizedBox(height: 40),
              
              // ZDE JSOU APLIKOVÁNY ÚPRAVY: Tlačítka nyní odesílají i informaci o jazyku
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
                title: Text('ds_settings_dictation'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                trailing: DropdownButton<SoundSetting>(
                  dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                  value: state.soundSetting,
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                  underline: const SizedBox(),
                  onChanged: (val) => context.read<DigitSpanBloc>().add(ChangeSettingsEvent(sound: val)),
                  items: [
                    DropdownMenuItem(value: SoundSetting.numbersOnly, child: Text("ds_settings_numbers_only".tr())),
                    DropdownMenuItem(value: SoundSetting.numbersAndFeedback, child: Text("ds_settings_full_feedback".tr())),
                    DropdownMenuItem(value: SoundSetting.off, child: Text("ds_settings_off".tr()))
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
            const SizedBox(height: 16),
            _menuBtn(context, 'ds_mode_nback'.tr(), () => context.read<DigitSpanBloc>().add(const ModeSelectedEvent(GameMode.nback)), isDark, icon: Icons.psychology_rounded),
            const SizedBox(height: 30),
            TextButton(onPressed: () => context.read<DigitSpanBloc>().add(ReturnToMenuEvent()), child: Text('global_btn_cancel'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold, letterSpacing: 2))),
          ],
        );

      case GamePhase.showingSequence:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withAlpha(40))),
              child: Text('ds_status_info'.tr(args: [_translateMode(state.gameMode).toUpperCase(), state.sequenceLength.toString()]),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
            ),
            const SizedBox(height: 60),
            Text(
              state.currentlyDisplayedDigit,
              key: ValueKey(state.currentlyDisplayedDigit),
              style: TextStyle(fontSize: 160, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(color: accent.withAlpha(150), blurRadius: 30)]),
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
            Text('ds_phase_reconstruct'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 4)),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _scBadge('ds_badge_asc'.tr(), state.highScores[GameMode.ascending] ?? 0, accent, isDark),
                        _scBadge('ds_badge_nback'.tr(), state.highScores[GameMode.nback] ?? 0, accent, isDark),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 40),
                    Expanded(
                      child: state.resultsHistory.isEmpty
                          ? Center(child: Text('global_no_data'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: state.resultsHistory.length,
                              itemBuilder: (context, index) {
                                final res = state.resultsHistory.reversed.toList()[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                                  child: ListTile(
                                    leading: Icon(res.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: res.isCorrect ? const Color(0xFF00E676) : Colors.redAccent),
                                    title: Text('${_translateMode(res.mode)} | N=${res.level}', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 13)),
                                    subtitle: Text('${res.timestamp.day}.${res.timestamp.month}. v ${res.timestamp.hour}:${res.timestamp.minute.toString().padLeft(2, '0')}', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                                  ),
                                );
                              },
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

      default: return const Center(child: CircularProgressIndicator());
    }
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
      case GameMode.nback: return 'ds_tr_nback'.tr();
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
