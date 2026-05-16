import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart'; // SCHVÁLNĚ ODSTRANĚNO (zajišťuje easy_localization)
import '../../bloc/stroop/stroop_bloc.dart';
import '../../bloc/stroop/stroop_event.dart';
import '../../bloc/stroop/stroop_state.dart';

class StroopScreen extends StatelessWidget {
  const StroopScreen({super.key});

  final Map<String, Color> _colorMap = const {
    'ČERVENÁ': Color(0xFFFF5252),
    'MODRÁ': Color(0xFF448AFF),
    'ZELENÁ': Color(0xFF69F0AE),
    'ŽLUTÁ': Color(0xFFFFD740),
    'ORANŽOVÁ': Color(0xFFFFAB40),
    'FIALOVÁ': Color(0xFFE040FB),
  };

  // --- FUNKCE: EXPORT DO KOGNITIVNÍHO PROFILU ---
  Future<void> _saveTestToProfile(double rawReactionTime, double successRate) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (successRate < 0.8) return; 

    double rawScore = (2.0 - rawReactionTime) * 10.0;
    if (rawScore < 0) rawScore = 0; 

    List<String> dailyHistory = prefs.getStringList('stroop_daily_history') ?? [];
    Map<String, double> dailyMaxes = {};

    for (var entry in dailyHistory) {
      final parts = entry.split('|');
      if (parts.length == 2) {
        dailyMaxes[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
      }
    }

    if (dailyMaxes.containsKey(today)) {
      if (rawScore > dailyMaxes[today]!) {
        dailyMaxes[today] = rawScore;
      }
    } else {
      dailyMaxes[today] = rawScore;
    }

    var sortedKeys = dailyMaxes.keys.toList()..sort();
    if (sortedKeys.length > 10) {
      sortedKeys = sortedKeys.sublist(sortedKeys.length - 10);
    }

    List<String> newHistoryToSave = [];
    List<double> valuesForMedian = [];

    for (var key in sortedKeys) {
      newHistoryToSave.add('$key|${dailyMaxes[key]}');
      valuesForMedian.add(dailyMaxes[key]!);
    }

    await prefs.setStringList('stroop_daily_history', newHistoryToSave);

    valuesForMedian.sort();
    double median = 0.0;
    int length = valuesForMedian.length;
    if (length > 0) {
      if (length % 2 == 1) {
        median = valuesForMedian[length ~/ 2];
      } else {
        median = (valuesForMedian[(length ~/ 2) - 1] + valuesForMedian[length ~/ 2]) / 2;
      }
    }

    await prefs.setDouble('metric_inhibition', median);
    await prefs.setInt('validity_inhibition', length);
  }

  Future<void> _saveTestToHistory(String historyKey, double newResult) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(historyKey) ?? [];
    history.add(newResult.toString());
    if (history.length > 50) history.removeAt(0); 
    await prefs.setStringList(historyKey, history);
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
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('global_btn_exit'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38))),
        ],
      )
    ) ?? false;
  }

  // --- NOVÁ FUNKCE PRO VYSVĚTLUJÍCÍ DIALOG K MODULU ---
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
            Expanded(child: Text('stroop_title'.tr(), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('module_info_goal'.tr(), 'stroop_info_goal_desc'.tr(), Icons.track_changes_rounded, accent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_rules'.tr(), 'stroop_info_rules_desc'.tr(), Icons.rule_rounded, Colors.orangeAccent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_practice'.tr(), 'stroop_info_prac_desc'.tr(), Icons.lightbulb_outline_rounded, const Color(0xFF00E676), isDark),
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
      create: (context) => StroopBloc(),
      child: BlocConsumer<StroopBloc, StroopState>(
        listenWhen: (previous, current) {
          return previous.phase != StroopPhase.result && current.phase == StroopPhase.result;
        },
        listener: (context, state) async {
          if (state.activeGameType == StroopGameType.standard) {
            final standardHistory = state.history.where((e) => e.gameType == StroopGameType.standard).toList();
            if (standardHistory.isNotEmpty) {
              final lastRun = standardHistory.last;
              double reactionTime = lastRun.medianReactionTime;
              double successRate = lastRun.score / lastRun.total;
              
              await _saveTestToHistory('history_stroop', reactionTime);
              await _saveTestToProfile(reactionTime, successRate);
            }
          }
        },
        builder: (context, state) {
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == StroopPhase.menu) {
                 return true;
              } else if (state.phase == StroopPhase.result || state.phase == StroopPhase.history) {
                 context.read<StroopBloc>().add(ResetStroop());
                 return false;
              } else {
                 bool quit = await _showInterruptDialog(context, isDark);
                 if (!context.mounted) return false;
                 if (quit) context.read<StroopBloc>().add(ResetStroop());
                 return false;
              }
            },
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(isDark, state),
                      Expanded(child: _buildBody(context, state, isDark)),
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

  Widget _buildHeader(bool isDark, StroopState state) {
    if (state.phase == StroopPhase.playing) {
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
              const Icon(Icons.palette_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Text('stroop_title'.tr(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, StroopState state, bool isDark) {
    if (state.phase == StroopPhase.menu) return _buildMenu(context, isDark);
    if (state.phase == StroopPhase.result) return _buildResults(context, state, isDark);
    if (state.phase == StroopPhase.history) return _buildHistory(context, state, isDark);

    String instruction = state.activeGameType == StroopGameType.standard
        ? 'stroop_inst_color'.tr()
        : (state.activeGameType == StroopGameType.reverse ? 'stroop_inst_meaning'.tr() : 'stroop_inst_match'.tr());

    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(color: accent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withAlpha(40))),
          child: Text('stroop_status'.tr(args: [state.currentRound.toString(), state.totalRounds.toString()]), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
        ),
        const SizedBox(height: 20),
        Text(instruction, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54, letterSpacing: 1.5)),
        const Spacer(),
        
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5),
            boxShadow: isDark ? [] : [BoxShadow(color: accent.withAlpha(15), blurRadius: 30, offset: const Offset(0, 15))],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              state.currentWord.tr(),
              style: TextStyle(
                fontSize: 72, fontWeight: FontWeight.w900, color: state.currentInkColor,
                shadows: [Shadow(color: state.currentInkColor.withAlpha(100), blurRadius: 20)],
              ),
            ),
          ),
        ),
        
        const Spacer(),
        _buildOptions(context, state, isDark),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildOptions(BuildContext context, StroopState state, bool isDark) {
    if (state.activeGameType == StroopGameType.trueFalse) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _menuBtn(context, 'stroop_btn_true'.tr(), () => context.read<StroopBloc>().add(const AnswerSelected('PRAVDA')), isDark, width: 150, color: const Color(0xFF00E676)),
          _menuBtn(context, 'stroop_btn_false'.tr(), () => context.read<StroopBloc>().add(const AnswerSelected('NEPRAVDA')), isDark, width: 150, color: Colors.redAccent),
        ],
      );
    }
    
    return SizedBox(
      width: 330,
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.0, crossAxisSpacing: 16, mainAxisSpacing: 16),
        itemCount: state.options.length,
        itemBuilder: (context, index) {
          final ans = state.options[index]; 
          final Color btnColor = _colorMap[ans]!;
          
          return GestureDetector(
            onTap: () => context.read<StroopBloc>().add(AnswerSelected(ans)),
            child: Container(
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: btnColor.withAlpha(80), blurRadius: 15, offset: const Offset(0, 5))],
                border: Border.all(color: Colors.white.withAlpha(50), width: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- UPRAVENÁ HLAVNÍ IKONA S TLAČÍTKEM NÁPOVĚDY ---
          Stack(
            alignment: Alignment.topRight,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Icon(Icons.palette_rounded, size: 80, color: accent.withAlpha(150)),
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
          const SizedBox(height: 40),
          
          _menuBtn(context, 'stroop_mode_standard'.tr(), () => context.read<StroopBloc>().add(const StartStroopGame(gameType: StroopGameType.standard)), isDark, isPrimary: true, icon: Icons.palette_rounded),
          const SizedBox(height: 16),
          _menuBtn(context, 'stroop_mode_reverse'.tr(), () => context.read<StroopBloc>().add(const StartStroopGame(gameType: StroopGameType.reverse)), isDark, icon: Icons.flip_rounded),
          const SizedBox(height: 16),
          _menuBtn(context, 'stroop_mode_tf'.tr(), () => context.read<StroopBloc>().add(const StartStroopGame(gameType: StroopGameType.trueFalse)), isDark, icon: Icons.thumbs_up_down_rounded),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_analytics'.tr(), () => context.read<StroopBloc>().add(ShowStroopHistory()), isDark, icon: Icons.insights_rounded, isSecondary: true),
          const SizedBox(height: 16),
          _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.pop(context), isDark, icon: Icons.power_settings_new_rounded, isDanger: true),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, StroopState state, bool isDark) {
    double percent = state.totalRounds > 0 ? (state.score / state.totalRounds) * 100 : 0;
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: accent),
          const SizedBox(height: 30),
          Text('global_training_complete'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 10),
          Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('stroop_result_score'.tr(args: [state.score.toString(), state.totalRounds.toString()]), style: TextStyle(fontSize: 18, color: accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<StroopBloc>().add(ResetStroop()), isDark, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, StroopState state, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSingleGraph(context, state, StroopGameType.standard, 'stroop_mode_standard'.tr(), isDark),
          const SizedBox(height: 30),
          _buildSingleGraph(context, state, StroopGameType.reverse, 'stroop_mode_reverse'.tr(), isDark),
          const SizedBox(height: 30),
          _buildSingleGraph(context, state, StroopGameType.trueFalse, 'stroop_mode_tf'.tr(), isDark),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_btn_back'.tr(), () => context.read<StroopBloc>().add(ResetStroop()), isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSingleGraph(BuildContext context, StroopState state, StroopGameType type, String title, bool isDark) {
    final typeHistory = state.history.where((e) => e.gameType == type).toList();
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    if (typeHistory.isEmpty) {
      return Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 10),
          Text('global_no_data'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
        ]
      );
    }
    
    double maxTime = typeHistory.map((e) => e.medianReactionTime).reduce((a, b) => a > b ? a : b);
    if (maxTime <= 0) maxTime = 1.0; 

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : accent.withAlpha(5), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text('stroop_median'.tr(args: [state.last5Median(type).toStringAsFixed(3)]), style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 160, width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: typeHistory.map((item) {
                  double successRate = item.total > 0 ? item.score / item.total : 0.0;
                  Color barColor = successRate >= 0.9 ? const Color(0xFF00E676) : (successRate >= 0.7 ? Colors.amber : Colors.redAccent);
                  double heightFactor = item.medianReactionTime / maxTime;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0), 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(item.medianReactionTime.toStringAsFixed(2), style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          width: 24, height: 120 * heightFactor + 10, 
                          decoration: BoxDecoration(
                            color: barColor.withAlpha(isDark ? 200 : 255), 
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: isDark ? [BoxShadow(color: barColor.withAlpha(50), blurRadius: 10)] : [],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            )
          )
        ]
      )
    );
  }

  Widget _menuBtn(BuildContext context, String label, VoidCallback onTap, bool isDark,
      {double width = 320, Color? color, bool isPrimary = false, bool isSecondary = false, bool isDanger = false, IconData? icon, Color? indicatorColor}) {
    
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? (isSecondary ? Colors.white54 : Colors.white) : (isSecondary ? Colors.black54 : const Color(0xFF1E293B));
    
    return Container(
      width: width, height: 60,
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
              gradient: (isSecondary || isDanger) ? null : LinearGradient(colors: isDark ? [const Color(0xFF23253A), const Color(0xFF161828)] : [Colors.white, const Color(0xFFF1F5F9)]),
              color: isSecondary ? Colors.transparent : (isDanger ? Colors.redAccent.withAlpha(20) : color?.withAlpha(40)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDanger ? Colors.redAccent.withAlpha(50) : (color?.withAlpha(60) ?? (isDark ? accent.withAlpha(40) : accent.withAlpha(30))), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: isDanger ? Colors.redAccent : textColor), const SizedBox(width: 12)],
                if (indicatorColor != null) ...[
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: indicatorColor.withAlpha(150), blurRadius: 8)])),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown, 
                    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDanger ? Colors.redAccent : (color ?? textColor), letterSpacing: 1.5))
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
