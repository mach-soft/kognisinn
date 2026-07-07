import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import '../../bloc/multi_n_back/multi_n_back_bloc.dart';
import '../../bloc/multi_n_back/multi_n_back_event.dart';
import '../../bloc/multi_n_back/multi_n_back_state.dart';
import '../../bloc/settings/settings_bloc.dart';

class MultiNBackScreen extends StatelessWidget {
  const MultiNBackScreen({super.key});

  // Definice 3. a 4. modality
  static const List<Color> targetColors = [
    Colors.red, Colors.green, Colors.blue, Colors.yellow, 
    Colors.purple, Colors.orange, Colors.teal, Colors.pink, Colors.amber
  ];
  static const List<IconData> targetShapes = [
    Icons.circle, Icons.square, Icons.star, Icons.favorite, 
    Icons.change_history, Icons.hexagon, Icons.diamond, Icons.shield, Icons.cloud
  ];

  Future<void> _saveTestToProfile(int nLevel, int score, int maxScore, bool isVar, int speedMs, int modalities) async {
    final prefs = await SharedPreferences.getInstance();
    
    double fT = 1.0;
    double sigmaT = 0.0;
    
    if (isVar) {
      fT = 1.0987; 
      sigmaT = 0.2828; 
    } else {
      double t = speedMs / 1000.0;
      if (t <= 0.1) t = 2.5; 
      fT = math.sqrt(2.5 / t);
    }

    // Multiplikátor zátěže (Dual = 1.0x, Triple = 1.5x, Quad = 2.0x)
    double modalityFactor = modalities / 2.0;
    double sSuccess = maxScore > 0 ? (score / maxScore) : 0.0;
    
    // Zapojení multiplikátoru do jádra KCI
    double nEff = nLevel * modalityFactor * fT * (1 + 0.5 * sigmaT) * math.pow((sSuccess / 0.8), 2);
    double qScore = 75.0 + (12.5 * nEff);
    if (qScore.isNaN || qScore.isInfinite) qScore = 75.0;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<String> dailyHistory = prefs.getStringList('dnb_daily_history') ?? [];
    Map<String, double> dailyMaxes = {};

    for (var entry in dailyHistory) {
      final parts = entry.split('|');
      if (parts.length >= 2) {
        double parsed = double.tryParse(parts[1]) ?? 0.0;
        if (!parsed.isNaN && !parsed.isInfinite) dailyMaxes[parts[0]] = parsed;
      }
    }

    if (dailyMaxes.containsKey(today)) {
      if (qScore > dailyMaxes[today]!) dailyMaxes[today] = qScore;
    } else {
      dailyMaxes[today] = qScore;
    }

    var sortedKeys = dailyMaxes.keys.toList()..sort();
    if (sortedKeys.length > 10) sortedKeys = sortedKeys.sublist(sortedKeys.length - 10);

    List<String> newHistoryToSave = [];
    List<double> valuesForMedian = [];
    for (var key in sortedKeys) {
      newHistoryToSave.add('$key|${dailyMaxes[key]}');
      valuesForMedian.add(dailyMaxes[key]!);
    }

    await prefs.setStringList('dnb_daily_history', newHistoryToSave);

    valuesForMedian.sort();
    double median = valuesForMedian.isNotEmpty 
        ? (valuesForMedian.length % 2 == 1 
            ? valuesForMedian[valuesForMedian.length ~/ 2] 
            : (valuesForMedian[(valuesForMedian.length ~/ 2) - 1] + valuesForMedian[valuesForMedian.length ~/ 2]) / 2) 
        : 0.0;

    await prefs.setDouble('metric_working_memory', median);
    await prefs.setDouble('metric_attention', median); 
    await prefs.setDouble('metric_executive', median); 
    await prefs.setInt('validity_working_memory', valuesForMedian.length); 
    await prefs.setInt('validity_attention', valuesForMedian.length); 
    await prefs.setInt('validity_executive', valuesForMedian.length); 
  }

  Future<bool> _showInterruptDialog(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
        title: Text('global_interrupt_title'.tr(), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)), 
        content: Text('global_interrupt_body'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)), 
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('global_btn_stay'.tr(), style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold))), 
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('global_btn_exit'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)))
        ]
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
            Expanded(child: Text('dnb_title'.tr(), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('module_info_goal'.tr(), 'dnb_info_goal_desc'.tr(), Icons.track_changes_rounded, accent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_rules'.tr(), 'dnb_info_rules_desc'.tr(), Icons.rule_rounded, Colors.orangeAccent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_practice'.tr(), 'dnb_info_prac_desc'.tr(), Icons.lightbulb_outline_rounded, const Color(0xFF00E676), isDark),
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
    final String langCode = context.locale.languageCode;
    final bool is24h = context.read<SettingsBloc>().state.is24HourFormat;

    return BlocProvider(
      create: (context) {
        final bloc = MultiNBackBloc();
        bloc.add(SetLanguageEvent(langCode));
        return bloc;
      },
      child: BlocConsumer<MultiNBackBloc, MultiNBackState>(
        listenWhen: (previous, current) => previous.phase == MultiNBackPhase.playing && current.phase == MultiNBackPhase.result,
        listener: (context, state) async {
          if (state.isAdaptive && state.history.isNotEmpty) {
            final lastItem = state.history.last;
            int maxScore = state.totalRounds * lastItem.modalities;
            await _saveTestToProfile(lastItem.nLevel, lastItem.score, maxScore, lastItem.isVariableSpeed, lastItem.speedMs, lastItem.modalities);
          }
        },
        builder: (context, state) {
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == MultiNBackPhase.playing) { context.read<MultiNBackBloc>().add(PauseGame()); return false; } 
              else if (state.phase == MultiNBackPhase.paused) { context.read<MultiNBackBloc>().add(ResumeGame()); return false; } 
              else if (state.phase == MultiNBackPhase.menu || state.phase == MultiNBackPhase.preTraining) { if (state.phase == MultiNBackPhase.preTraining) { context.read<MultiNBackBloc>().add(ResetMultiNBack()); return false; } return true; } 
              else if (state.phase == MultiNBackPhase.result || state.phase == MultiNBackPhase.history || state.phase == MultiNBackPhase.settings) { context.read<MultiNBackBloc>().add(ResetMultiNBack()); return false; } 
              else { bool quit = await _showInterruptDialog(context, isDark); if (!context.mounted) return false; if (quit) context.read<MultiNBackBloc>().add(ResetMultiNBack()); return false; }
            },
            child: Scaffold(
              body: Container(
                width: double.infinity, 
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])), 
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildHeader(isDark, state), 
                        Expanded(child: _buildBody(context, state, isDark, is24h))
                      ]
                    ),
                  )
                )
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, MultiNBackState state) {
    if (state.phase == MultiNBackPhase.playing) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10), 
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7000FF)]).createShader(bounds), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              const Icon(Icons.memory_rounded, color: Colors.white, size: 36), 
              const SizedBox(width: 12), 
              Text('Multi N-Back', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4))
            ]
          )
        )
      )
    );
  }

  Widget _buildBody(BuildContext context, MultiNBackState state, bool isDark, bool is24h) {
    if (state.phase == MultiNBackPhase.menu) return _buildMenu(context, state, isDark);
    if (state.phase == MultiNBackPhase.preTraining) return _buildPreTraining(context, state, isDark);
    if (state.phase == MultiNBackPhase.settings) return _buildSettings(context, state, isDark);
    if (state.phase == MultiNBackPhase.result) return _buildResult(context, state, isDark);
    if (state.phase == MultiNBackPhase.history) return _buildHistory(context, state, isDark, is24h);
    if (state.phase == MultiNBackPhase.paused) return _buildPaused(context, state, isDark);

    final Color accentColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    bool canAnswer = state.currentRound > state.currentN;

    String speedStr = state.isVariableSpeed ? 'VAR' : '${(state.currentSpeedMs / 1000).toStringAsFixed(1)}s';
    String statusText = 'N=${state.currentN} | $speedStr | ${state.currentRound}/${state.totalRounds}';

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), 
            decoration: BoxDecoration(color: accentColor.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withAlpha(40))), 
            child: Text(statusText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 2))
          ),
          const SizedBox(height: 40),
          
          Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), 
              borderRadius: BorderRadius.circular(20), 
              border: Border.all(color: isDark ? Colors.white12 : accentColor.withAlpha(20), width: 1.5), 
              boxShadow: isDark ? [] : [BoxShadow(color: accentColor.withAlpha(15), blurRadius: 20, offset: const Offset(0, 10))]
            ),
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), 
              itemCount: 9,
              itemBuilder: (context, index) {
                bool isActive = state.activeSquareIndex == index;
                
                Widget content = const SizedBox();
                if (isActive) {
                  Color activeColor = state.currentModalities >= 3 ? targetColors[state.activeColorIndex] : accentColor;
                  if (state.currentModalities >= 4) {
                    content = Icon(targetShapes[state.activeShapeIndex], color: activeColor, size: 40);
                  } else if (state.currentModalities == 3) {
                    content = Container(decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(8)));
                  } else {
                    content = const SizedBox();
                  }
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150), 
                  decoration: BoxDecoration(
                    color: (isActive && state.currentModalities < 3) ? accentColor : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)), 
                    borderRadius: BorderRadius.circular(12), 
                    boxShadow: (isActive && state.currentModalities < 3) ? [BoxShadow(color: accentColor.withAlpha(100), blurRadius: 15)] : []
                  ),
                  child: content,
                );
              },
            ),
          ),
          const SizedBox(height: 50),
          
          Wrap(
            spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
            children: [
              _actionBtn('dnb_btn_position'.tr().toUpperCase(), state.positionMatchClicked, () => context.read<MultiNBackBloc>().add(PositionMatchClicked()), isDark, accentColor, canAnswer: canAnswer, isError: state.isPositionError),
              _actionBtn('dnb_btn_audio'.tr().toUpperCase(), state.audioMatchClicked, () => context.read<MultiNBackBloc>().add(AudioMatchClicked()), isDark, accentColor, canAnswer: canAnswer, isError: state.isAudioError),
              if (state.currentModalities >= 3) _actionBtn('dnb_btn_color'.tr().toUpperCase(), state.colorMatchClicked, () => context.read<MultiNBackBloc>().add(ColorMatchClicked()), isDark, accentColor, canAnswer: canAnswer, isError: state.isColorError),
              if (state.currentModalities >= 4) _actionBtn('dnb_btn_shape'.tr().toUpperCase(), state.shapeMatchClicked, () => context.read<MultiNBackBloc>().add(ShapeMatchClicked()), isDark, accentColor, canAnswer: canAnswer, isError: state.isShapeError),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, bool isClicked, VoidCallback onTap, bool isDark, Color accentColor, {bool canAnswer = true, bool isError = false}) {
    Color btnColor = isDark ? const Color(0xFF23253A) : Colors.white;
    Color borderColor = isDark ? Colors.white12 : Colors.black12;
    Color textColor = isDark ? Colors.white70 : Colors.black87;
    List<BoxShadow> glow = [];

    if (isError) { 
      btnColor = isDark ? Colors.redAccent.withAlpha(80) : Colors.redAccent; 
      borderColor = Colors.redAccent; 
      textColor = Colors.white; 
      glow = [BoxShadow(color: Colors.redAccent.withAlpha(100), blurRadius: 15)]; 
    } else if (isClicked) { 
      btnColor = accentColor; 
      borderColor = accentColor; 
      textColor = Colors.white; 
      glow = [BoxShadow(color: accentColor.withAlpha(100), blurRadius: 15)]; 
    }

    Widget btnVisual = AnimatedContainer(
      duration: const Duration(milliseconds: 150), 
      width: 140, height: 60, 
      alignment: Alignment.center, 
      decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor, width: 2), boxShadow: glow), 
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2))
    );
    
    if (!canAnswer) return Opacity(opacity: 0.2, child: btnVisual);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: btnVisual);
  }

  Widget _buildPaused(BuildContext context, MultiNBackState state, bool isDark) { 
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.pause_circle_filled_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF)), 
          const SizedBox(height: 30), 
          Text('global_training_paused'.tr().toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 2)), 
          const SizedBox(height: 50), 
          _menuBtn(context, 'global_btn_continue'.tr(), () => context.read<MultiNBackBloc>().add(ResumeGame()), isDark, isPrimary: true, icon: Icons.play_arrow_rounded), 
          const SizedBox(height: 16), 
          _menuBtn(context, 'global_btn_exit'.tr(), () async { 
            bool quit = await _showInterruptDialog(context, isDark); 
            if (quit && context.mounted) context.read<MultiNBackBloc>().add(ResetMultiNBack()); 
          }, isDark, isDanger: true, icon: Icons.stop_rounded)
        ]
      )
    ); 
  }

  Widget _buildPreTraining(BuildContext context, MultiNBackState state, bool isDark) { 
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(state.isAdaptive ? Icons.auto_graph_rounded : Icons.tune_rounded, size: 80, color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF)).withAlpha(150)), 
          const SizedBox(height: 30), 
          Text(state.isAdaptive ? 'global_mode_adaptive'.tr() : 'global_mode_manual'.tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: 2)), 
          const SizedBox(height: 15), 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
            decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white12 : Colors.black12)), 
            child: Column(
              children: [
                Text('${'dnb_settings_level'.tr()}: N=${state.isAdaptive ? state.currentN : state.manualN}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF), letterSpacing: 1.5)), 
                const SizedBox(height: 4), 
                Text('${'dnb_settings_speed'.tr()}: ${(state.isAdaptive ? state.isVariableSpeed : false) ? 'VAR' : '${((state.isAdaptive ? state.currentSpeedMs : state.manualSpeedMs) / 1000).toStringAsFixed(1)}s'}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.2))
              ]
            )
          ), 
          const SizedBox(height: 50), 
          _menuBtn(context, 'global_btn_start_training'.tr(), () => context.read<MultiNBackBloc>().add(StartGame(adaptive: state.isAdaptive)), isDark, isPrimary: true, icon: Icons.play_arrow_rounded), 
          const SizedBox(height: 16), 
          _menuBtn(context, 'global_btn_back'.tr(), () => context.read<MultiNBackBloc>().add(ResetMultiNBack()), isDark, isSecondary: true)
        ]
      )
    ); 
  }

  Widget _buildMenu(BuildContext context, MultiNBackState state, bool isDark) { 
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF); 
    final Color cardBg = isDark ? Colors.white.withAlpha(15) : accent.withAlpha(10);
    final Color borderColor = isDark ? Colors.white12 : accent.withAlpha(30);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), 
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Icon(Icons.memory_rounded, size: 80, color: accent.withAlpha(150)),
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

            Container(
              width: 320,
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50, height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: state.dailyGoal > 0 ? (state.dailyCount / state.dailyGoal).clamp(0.0, 1.0) : 0,
                          backgroundColor: accent.withAlpha(30),
                          color: state.dailyCount >= state.dailyGoal ? Colors.greenAccent : accent,
                          strokeWidth: 5, strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Icon(
                            state.dailyCount >= state.dailyGoal ? Icons.check_rounded : Icons.fitness_center_rounded, 
                            color: state.dailyCount >= state.dailyGoal ? Colors.greenAccent : accent, 
                            size: 20
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'dnb_daily_progress'.tr().toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${state.dailyCount}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                            Text(' / ${state.dailyGoal}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            _menuBtn(context, 'global_mode_adaptive'.tr(), () => context.read<MultiNBackBloc>().add(const ShowPreTraining(adaptive: true)), isDark, isPrimary: true, icon: Icons.auto_graph_rounded), 
            const SizedBox(height: 16), 
            _menuBtn(context, 'global_mode_manual'.tr(), () => context.read<MultiNBackBloc>().add(const ShowPreTraining(adaptive: false)), isDark, icon: Icons.tune_rounded), 
            const SizedBox(height: 32), 
            _menuBtn(context, 'global_analytics'.tr(), () => context.read<MultiNBackBloc>().add(ShowHistory()), isDark, icon: Icons.insights_rounded, isSecondary: true), 
            const SizedBox(height: 16), 
            _menuBtn(context, 'global_settings'.tr(), () => context.read<MultiNBackBloc>().add(ShowSettings()), isDark, icon: Icons.settings_rounded, isSecondary: true), 
            const SizedBox(height: 32), 
            _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.pop(context), isDark, icon: Icons.power_settings_new_rounded, isDanger: true), 
            const SizedBox(height: 20)
          ]
        )
      )
    ); 
  }

  Widget _buildSettings(BuildContext context, MultiNBackState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(32), border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5)),
            child: Column(
              children: [
                Text('dnb_daily_goal'.tr().toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2), textAlign: TextAlign.center), const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.dailyGoal.toDouble(), min: 5, max: 30, divisions: 20, 
                        activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12, 
                        onChanged: (val) => context.read<MultiNBackBloc>().add(UpdateDailyGoalEvent(val.toInt()))
                      )
                    ), 
                    Text("${state.dailyGoal}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // MODALITY SELECTOR
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(32), border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5)),
            child: Column(
              children: [
                Text('dnb_settings_modalities'.tr().toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2), textAlign: TextAlign.center), 
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildModalityBtn(context, 2, 'DUAL', 'dnb_modality_standard'.tr(), state.activeModalities, isDark, accent),
                    _buildModalityBtn(context, 3, 'TRIPLE', 'dnb_modality_advanced'.tr(), state.activeModalities, isDark, accent),
                    _buildModalityBtn(context, 4, 'QUAD', 'dnb_modality_expert'.tr(), state.activeModalities, isDark, accent),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ADAPTACE
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(32), border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5)),
            child: Column(
              children: [
                Text('dnb_settings_adaptive_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2), textAlign: TextAlign.center), const SizedBox(height: 24),
                Text('dnb_settings_adaptation_speed'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)), const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    _buildAdaptBtn(context, 1, 'dnb_settings_adapt_1'.tr(), state.adaptationSpeed, isDark, accent, false), 
                    _buildAdaptBtn(context, 3, 'dnb_settings_adapt_3'.tr(), state.adaptationSpeed, isDark, accent, false), 
                    _buildAdaptBtn(context, 7, 'dnb_settings_adapt_7'.tr(), state.adaptationSpeed, isDark, accent, false)
                  ]
                ),
                const Divider(color: Colors.white12, height: 30),
                
                // Nejnižší časování
                Text('dnb_settings_adaptive_min'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.adaptiveSpeedMinMs / 1000, 
                        min: 1.0, 
                        max: 3.0, 
                        divisions: 20, 
                        activeColor: accent, 
                        inactiveColor: isDark ? Colors.white12 : Colors.black12, 
                        onChanged: (val) => context.read<MultiNBackBloc>().add(UpdateSettings(adaptiveSpeedMinMs: (val * 1000).round()))
                      )
                    ), 
                    Text("${(state.adaptiveSpeedMinMs / 1000).toStringAsFixed(1)}s", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))
                  ]
                ),
                const SizedBox(height: 16),

                // Zrychlení po úspěchu
                Text('dnb_settings_adaptive_step'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.adaptiveSpeedStepMs / 1000, 
                        min: 0.2, max: 0.5, divisions: 3, 
                        activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12, 
                        onChanged: (val) => context.read<MultiNBackBloc>().add(UpdateSettings(adaptiveSpeedStepMs: (val * 1000).round()))
                      )
                    ), 
                    Text("${(state.adaptiveSpeedStepMs / 1000).toStringAsFixed(1)}s", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))
                  ]
                ),
                const SizedBox(height: 16),

                // Počet adaptací před zvýšením N
                Text('dnb_settings_adaptive_count'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.adaptiveStepCount.toDouble(), 
                        min: 1, max: 4, divisions: 3, 
                        activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12, 
                        onChanged: (val) => context.read<MultiNBackBloc>().add(UpdateSettings(adaptiveStepCount: val.round()))
                      )
                    ), 
                    Text("${state.adaptiveStepCount}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))
                  ]
                ),
                const SizedBox(height: 16),

                // Tlačítko pro aktivaci Variabilního časování (VAR)
                GestureDetector(
                  onTap: () => context.read<MultiNBackBloc>().add(UpdateSettings(adaptiveUseVar: !state.adaptiveUseVar)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: state.adaptiveUseVar ? accent.withAlpha(20) : (isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: state.adaptiveUseVar ? accent : (isDark ? Colors.white12 : Colors.black12))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(state.adaptiveUseVar ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: state.adaptiveUseVar ? accent : (isDark ? Colors.white54 : Colors.black54), size: 20),
                        const SizedBox(width: 12),
                        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('dnb_settings_adaptive_var'.tr().toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: state.adaptiveUseVar ? accent : (isDark ? Colors.white54 : Colors.black54))))),
                      ]
                    )
                  )
                ),
                const SizedBox(height: 32),

                // Dynamická vizualizace aktuální sekvence časů
                Builder(
                  builder: (context) {
                    List<String> speedSequence = [];
                    for (int i = 0; i < state.adaptiveStepCount; i++) {
                      if (state.adaptiveUseVar && i == state.adaptiveStepCount - 1) {
                        speedSequence.add("VAR");
                      } else {
                        int spd = state.adaptiveSpeedMinMs + ((state.adaptiveStepCount - 1) - i) * state.adaptiveSpeedStepMs;
                        speedSequence.add("${(spd / 1000).toStringAsFixed(1)}s");
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: accent.withAlpha(15), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withAlpha(30))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text("dnb_settings_sequence_title".tr().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: accent, letterSpacing: 1.5), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8, runSpacing: 10,
                            children: speedSequence.asMap().entries.map((entry) {
                              bool isLast = entry.key == speedSequence.length - 1;
                              String step = entry.value;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: step == "VAR" ? Colors.orangeAccent.withAlpha(40) : accent.withAlpha(40),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: step == "VAR" ? Colors.orangeAccent.withAlpha(50) : accent.withAlpha(50))
                                    ),
                                    child: Text(step, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                                  ),
                                  if (!isLast) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: accent.withAlpha(150)),
                                  ]
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // MANUAL
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(32), border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5)),
            child: Column(
              children: [
                Text('dnb_settings_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2), textAlign: TextAlign.center), const SizedBox(height: 24),
                Text('dnb_settings_level'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(children: [Expanded(child: Slider(value: state.manualN.toDouble(), min: 1, max: 9, divisions: 8, activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12, onChanged: (val) => context.read<MultiNBackBloc>().add(UpdateSettings(manualN: val.round())))), Text("${state.manualN}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))]),
                const Divider(color: Colors.white12, height: 30),
                Text('dnb_settings_speed'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.manualSpeedMs / 1000, 
                        min: 1.3, 
                        max: 3.5, 
                        divisions: 22,  
                        activeColor: accent, 
                        inactiveColor: isDark ? Colors.white12 : Colors.black12, 
                        onChanged: (val) => context.read<MultiNBackBloc>().add(UpdateSettings(manualSpeedMs: (val * 1000).round()))
                      )
                    ), 
                    Text(
                      "${(state.manualSpeedMs / 1000).toStringAsFixed(1)}s", 
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)
                    )
                  ]
                ),
              ] 
            ),
          ),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_btn_save_back'.tr(), () => context.read<MultiNBackBloc>().add(ResetMultiNBack()), isDark, isPrimary: true), const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAdaptBtn(BuildContext context, int value, String label, int currentValue, bool isDark, Color accent, bool isModality) {
    bool isSelected = value == currentValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => isModality ? context.read<MultiNBackBloc>().add(UpdateSettings(activeModalities: value)) : context.read<MultiNBackBloc>().add(UpdateSettings(adaptationSpeed: value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? accent : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12))),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54))))),
        ),
      ),
    );
  }

  Widget _buildModalityBtn(BuildContext context, int value, String label, String subTitle, int currentValue, bool isDark, Color accent) {
    bool isSelected = value == currentValue;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(subTitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54))
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.read<MultiNBackBloc>().add(UpdateSettings(activeModalities: value)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), 
              margin: const EdgeInsets.symmetric(horizontal: 6), 
              padding: const EdgeInsets.symmetric(vertical: 14), 
              decoration: BoxDecoration(
                color: isSelected ? accent : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)), 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12))
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown, 
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54)))
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, MultiNBackState state, bool isDark) { 
    double percent = state.totalRounds > 0 ? (state.score / (state.totalRounds * state.currentModalities)) * 100 : 0; 
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.hub_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF)), 
          const SizedBox(height: 30), 
          Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))), 
          const SizedBox(height: 50), 
          _menuBtn(context, 'global_btn_continue'.tr(), () => context.read<MultiNBackBloc>().add(StartGame(adaptive: state.isAdaptive)), isDark, isPrimary: true), 
          const SizedBox(height: 16), 
          _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<MultiNBackBloc>().add(ResetMultiNBack()), isDark, isSecondary: true)
        ]
      )
    ); 
  }

  Widget _buildHistory(BuildContext context, MultiNBackState state, bool isDark, bool is24h) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: accent, labelColor: accent, unselectedLabelColor: isDark ? Colors.white38 : Colors.black38, 
            tabs: [Tab(icon: const Icon(Icons.auto_graph_rounded), text: 'global_tab_adaptive'.tr()), Tab(icon: const Icon(Icons.tune_rounded), text: 'global_tab_manual'.tr())]
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(padding: const EdgeInsets.only(top: 20), child: _buildGraph(context, state, true, 'dnb_graph_adaptive'.tr(), isDark, is24h)), 
                SingleChildScrollView(padding: const EdgeInsets.only(top: 20), child: _buildGraph(context, state, false, 'dnb_graph_manual'.tr(), isDark, is24h))
              ]
            )
          ),
          const SizedBox(height: 20), 
          _menuBtn(context, 'global_btn_back'.tr(), () => context.read<MultiNBackBloc>().add(ResetMultiNBack()), isDark), 
          const SizedBox(height: 40),
        ],
      ),
    );
  }

    Widget _buildGraph(BuildContext context, MultiNBackState state, bool adaptive, String title, bool isDark, bool is24h) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final history = state.history.where((e) => e.isAdaptive == adaptive).toList();
    
    // Zjištění stavu gamifikace z globálního nastavení
    final bool showGamified = context.read<SettingsBloc>().state.showGamifiedValues;

    if (history.isEmpty) {
      return Center(child: Text('global_no_data'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
    }

    double calculatePoints(MultiNBackHistoryItem item, double success) {
      double fT = 1.0;
      double sigmaT = 0.0;
      
      if (item.isVariableSpeed) {
        fT = 1.0987; 
        sigmaT = 0.2828; 
      } else {
        double t = item.speedMs / 1000.0;
        if (t <= 0.1) t = 2.5; 
        fT = math.sqrt(2.5 / t);
      }
      
      double modalityFactor = item.modalities / 2.0;
      double nEff = item.nLevel * modalityFactor * fT * (1 + 0.5 * sigmaT) * math.pow((success / 0.8), 2);
      
      double qScore = 75.0 + (12.5 * nEff);
      if (qScore.isNaN || qScore.isInfinite) return 75.0; 
      return qScore;
    }

    double maxPoints = 1.0;
    if (showGamified) {
      for (var item in history) {
        double successRate = item.date.isBefore(DateTime(2026, 7, 7)) 
            ? (item.score / (state.totalRounds * item.modalities)).clamp(0.0, 1.0)
            : (item.score / 100.0).clamp(0.0, 1.0);
        
        double pts = calculatePoints(item, successRate);
        if (pts > maxPoints) maxPoints = pts;
      }
    }

    final String langCode = context.locale.languageCode;
    final DateFormat dateFormat = DateFormat('dd.MM.yyyy');

    Map<String, List<MultiNBackHistoryItem>> groupedHistory = {};
    for (var item in history) {
      String dayKey = dateFormat.format(item.date);
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
        // Správný výpočet procent podle stáří záznamu
        double successRate = item.date.isBefore(DateTime(2026, 7, 7)) 
            ? (item.score / (state.totalRounds * item.modalities)).clamp(0.0, 1.0)
            : (item.score / 100.0).clamp(0.0, 1.0);
            
        double heightFactor;
        String topLabel;

        if (showGamified) {
          double pts = calculatePoints(item, successRate);
          heightFactor = maxPoints > 0 ? (pts / maxPoints) : 0.0;
          if (heightFactor.isNaN || heightFactor.isInfinite) heightFactor = 0.0;
          topLabel = '${pts.round()} ${'global_pts'.tr()}';
        } else {
          heightFactor = successRate; // Osa je rovnou 0-100%
          topLabel = '${(successRate * 100).round()} %';
        }

        Color barColor;
        if (successRate < 0.5) {
          barColor = Colors.redAccent;
        } else {
          double lerpFactor = (successRate - 0.5) * 2.0;
          barColor = Color.lerp(Colors.redAccent, Colors.greenAccent, lerpFactor) ?? Colors.greenAccent;
        }

        String speedStr = item.isVariableSpeed ? "VAR" : "${(item.speedMs / 1000).toStringAsFixed(1)}s";

        String timeStr;
        if (is24h) {
          timeStr = DateFormat('HH:mm').format(item.date);
        } else {
          int h = item.date.hour;
          int m = item.date.minute;
          String mStr = m.toString().padLeft(2, '0');
          bool isPm = h >= 12;
          int hour12 = h % 12 == 0 ? 12 : h % 12;
          String suffix = (langCode == 'cs') ? (isPm ? 'odp.' : 'dop.') : (langCode == 'de' ? (isPm ? 'nachm.' : 'vorm.') : (isPm ? 'PM' : 'AM'));
          timeStr = '$hour12:$mStr $suffix';
        }

        String modalityLabel = 'DUAL';
        if (item.modalities == 3) modalityLabel = 'TRIPLE';
        if (item.modalities == 4) modalityLabel = 'QUAD';

        graphColumns.add(
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(topLabel, style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Container(width: 30, height: 120 * heightFactor + 10, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: barColor.withAlpha(100), blurRadius: 4)])),
                const SizedBox(height: 10),
                Text('N=${item.nLevel}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(modalityLabel, style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(speedStr, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(timeStr, style: TextStyle(fontSize: 9, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(height: 28), 
              ],
            ),
          )
        );
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(5) : accent.withAlpha(5), borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20))),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white : const Color(0xFF1E293B))), const SizedBox(height: 24),
          SizedBox(
            height: 320, 
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, 
              physics: const BouncingScrollPhysics(),
              itemCount: graphColumns.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: graphColumns[index],
                );
              },
            ),
          )
        ],
      ),
    );
  }


  Widget _menuBtn(BuildContext context, String label, VoidCallback onTap, bool isDark, {double width = 320, bool isPrimary = false, bool isSecondary = false, bool isDanger = false, IconData? icon}) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? (isSecondary ? Colors.white54 : Colors.white) : (isSecondary ? Colors.black54 : const Color(0xFF1E293B));
    return Container(
      width: width, height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: (isPrimary && isDark) ? [BoxShadow(color: accent.withAlpha(30), blurRadius: 20, offset: const Offset(0, 5))] : []),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(gradient: isSecondary ? null : LinearGradient(colors: isDark ? [const Color(0xFF23253A), const Color(0xFF161828)] : [Colors.white, const Color(0xFFF1F5F9)]), color: isSecondary ? Colors.transparent : (isDanger ? Colors.redAccent.withAlpha(20) : null), borderRadius: BorderRadius.circular(20), border: Border.all(color: isDanger ? Colors.redAccent.withAlpha(50) : (isSecondary ? (isDark ? Colors.white12 : Colors.black12) : (isDark ? accent.withAlpha(40) : accent.withAlpha(30))), width: 1.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: isDanger ? Colors.redAccent : textColor), const SizedBox(width: 12)],
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDanger ? Colors.redAccent : textColor, letterSpacing: 1.5)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
