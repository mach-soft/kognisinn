import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../bloc/dual_n_back/dual_n_back_bloc.dart';
import '../../bloc/dual_n_back/dual_n_back_event.dart';
import '../../bloc/dual_n_back/dual_n_back_state.dart';
import '../../bloc/settings/settings_bloc.dart'; // IMPORT PRO FORMÁT ČASU

class DualNBackScreen extends StatelessWidget {
  const DualNBackScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);

    final String langCode = context.locale.languageCode;

    return BlocProvider(
      create: (context) {
        final bloc = DualNBackBloc();
        bloc.add(SetLanguageEvent(langCode));
        return bloc;
      },
      child: BlocBuilder<DualNBackBloc, DualNBackState>(
        builder: (context, state) {
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == DualNBackPhase.playing) {
                context.read<DualNBackBloc>().add(PauseGame());
                return false;
              } else if (state.phase == DualNBackPhase.paused) {
                context.read<DualNBackBloc>().add(ResumeGame());
                return false;
              } else if (state.phase == DualNBackPhase.menu || state.phase == DualNBackPhase.preTraining) {
                if (state.phase == DualNBackPhase.preTraining) { context.read<DualNBackBloc>().add(ResetDualNBack()); return false; }
                return true;
              } else if (state.phase == DualNBackPhase.result || state.phase == DualNBackPhase.history || state.phase == DualNBackPhase.settings) {
                context.read<DualNBackBloc>().add(ResetDualNBack()); return false;
              } else {
                bool quit = await _showInterruptDialog(context, isDark);
                if (!context.mounted) return false;
                if (quit) context.read<DualNBackBloc>().add(ResetDualNBack());
                return false;
              }
            },
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])),
                child: SafeArea(child: Column(children: [_buildHeader(isDark, state), Expanded(child: _buildBody(context, state, isDark))])),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, DualNBackState state) {
    if (state.phase == DualNBackPhase.playing) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7000FF)]).createShader(bounds),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory_rounded, color: Colors.white, size: 36), const SizedBox(width: 12),
              Text('dnb_title'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DualNBackState state, bool isDark) {
    if (state.phase == DualNBackPhase.menu) return _buildMenu(context, isDark);
    if (state.phase == DualNBackPhase.preTraining) return _buildPreTraining(context, state, isDark);
    if (state.phase == DualNBackPhase.settings) return _buildSettings(context, state, isDark);
    if (state.phase == DualNBackPhase.result) return _buildResult(context, state, isDark);
    if (state.phase == DualNBackPhase.history) return _buildHistory(context, state, isDark);
    if (state.phase == DualNBackPhase.paused) return _buildPaused(context, state, isDark);

    final Color accentColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    bool canAnswer = state.currentRound > state.currentN;

    String speedStr = state.isVariableSpeed ? 'dnb_speed_var'.tr() : '${(state.currentSpeedMs / 1000).toStringAsFixed(1)}s';
    String statusText = 'N=${state.currentN} | $speedStr | ${state.currentRound}/${state.totalRounds}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(color: accentColor.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withAlpha(40))),
          child: Text(statusText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 2)),
        ),
        const SizedBox(height: 40),
        Container(
          width: 300, height: 300,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white12 : accentColor.withAlpha(20), width: 1.5), boxShadow: isDark ? [] : [BoxShadow(color: accentColor.withAlpha(15), blurRadius: 20, offset: const Offset(0, 10))]),
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: 9,
            itemBuilder: (context, index) {
              bool isActive = state.activeSquareIndex == index;
              return AnimatedContainer(duration: const Duration(milliseconds: 150), decoration: BoxDecoration(color: isActive ? accentColor : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)), borderRadius: BorderRadius.circular(12), boxShadow: isActive ? [BoxShadow(color: accentColor.withAlpha(100), blurRadius: 15)] : []));
            },
          ),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionBtn('dnb_btn_position'.tr(), state.positionMatchClicked, () => context.read<DualNBackBloc>().add(PositionMatchClicked()), isDark, accentColor, canAnswer: canAnswer, isError: state.isPositionError),
            _actionBtn('dnb_btn_audio'.tr(), state.audioMatchClicked, () => context.read<DualNBackBloc>().add(AudioMatchClicked()), isDark, accentColor, canAnswer: canAnswer, isError: state.isAudioError),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _actionBtn(String label, bool isClicked, VoidCallback onTap, bool isDark, Color accentColor, {bool canAnswer = true, bool isError = false}) {
    Color btnColor = isDark ? const Color(0xFF23253A) : Colors.white;
    Color borderColor = isDark ? Colors.white12 : Colors.black12;
    Color textColor = isDark ? Colors.white70 : Colors.black87;
    List<BoxShadow> glow = [];

    if (isError) {
      btnColor = isDark ? Colors.redAccent.withAlpha(80) : Colors.redAccent; borderColor = Colors.redAccent; textColor = Colors.white; glow = [BoxShadow(color: Colors.redAccent.withAlpha(100), blurRadius: 15)];
    } else if (isClicked) {
      btnColor = accentColor; borderColor = accentColor; textColor = Colors.white; glow = [BoxShadow(color: accentColor.withAlpha(100), blurRadius: 15)];
    }

    Widget btnVisual = AnimatedContainer(duration: const Duration(milliseconds: 150), width: 140, height: 60, alignment: Alignment.center, decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor, width: 2), boxShadow: glow), child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2)));
    if (!canAnswer) return Opacity(opacity: 0.2, child: btnVisual);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: btnVisual);
  }

  Widget _buildPaused(BuildContext context, DualNBackState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pause_circle_filled_rounded, size: 80, color: accent),
          const SizedBox(height: 30),
          Text('TRÉNINK POZASTAVEN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: 2)),
          const SizedBox(height: 50),
          _menuBtn(context, 'global_btn_continue'.tr(), () => context.read<DualNBackBloc>().add(ResumeGame()), isDark, isPrimary: true, icon: Icons.play_arrow_rounded),
          const SizedBox(height: 16),
          _menuBtn(context, 'global_btn_exit'.tr(), () async {
              bool quit = await _showInterruptDialog(context, isDark);
              if (quit && context.mounted) context.read<DualNBackBloc>().add(ResetDualNBack());
            }, isDark, isDanger: true, icon: Icons.stop_rounded),
        ],
      ),
    );
  }

  Widget _buildPreTraining(BuildContext context, DualNBackState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final String modeName = state.isAdaptive ? 'global_mode_adaptive'.tr() : 'global_mode_manual'.tr();
    final int startN = state.isAdaptive ? state.currentN : state.manualN;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(state.isAdaptive ? Icons.auto_graph_rounded : Icons.tune_rounded, size: 80, color: accent.withAlpha(150)), const SizedBox(height: 30),
          Text(modeName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: 2)), const SizedBox(height: 10),
          Text('${'dnb_settings_level'.tr()}: N=$startN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent, letterSpacing: 1.5)), const SizedBox(height: 50),
          _menuBtn(context, 'global_btn_start_training'.tr(), () => context.read<DualNBackBloc>().add(StartGame(adaptive: state.isAdaptive)), isDark, isPrimary: true, icon: Icons.play_arrow_rounded), const SizedBox(height: 16),
          _menuBtn(context, 'global_btn_back'.tr(), () => context.read<DualNBackBloc>().add(ResetDualNBack()), isDark, isSecondary: true),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.memory_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF).withAlpha(150) : const Color(0xFF7000FF).withAlpha(150)), const SizedBox(height: 40),
          _menuBtn(context, 'global_mode_adaptive'.tr(), () => context.read<DualNBackBloc>().add(const ShowPreTraining(adaptive: true)), isDark, isPrimary: true, icon: Icons.auto_graph_rounded), const SizedBox(height: 16),
          _menuBtn(context, 'global_mode_manual'.tr(), () => context.read<DualNBackBloc>().add(const ShowPreTraining(adaptive: false)), isDark, icon: Icons.tune_rounded), const SizedBox(height: 40),
          _menuBtn(context, 'global_analytics'.tr(), () => context.read<DualNBackBloc>().add(ShowHistory()), isDark, icon: Icons.insights_rounded, isSecondary: true), const SizedBox(height: 16),
          _menuBtn(context, 'global_settings'.tr(), () => context.read<DualNBackBloc>().add(ShowSettings()), isDark, icon: Icons.settings_rounded, isSecondary: true), const SizedBox(height: 32),
          _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.pop(context), isDark, icon: Icons.power_settings_new_rounded, isDanger: true),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, DualNBackState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
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
                    _buildAdaptBtn(context, 1, 'dnb_settings_adapt_1'.tr(), state.adaptationSpeed, isDark, accent),
                    _buildAdaptBtn(context, 3, 'dnb_settings_adapt_3'.tr(), state.adaptationSpeed, isDark, accent),
                    _buildAdaptBtn(context, 7, 'dnb_settings_adapt_7'.tr(), state.adaptationSpeed, isDark, accent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150), borderRadius: BorderRadius.circular(32), border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5)),
            child: Column(
              children: [
                Text('dnb_settings_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2), textAlign: TextAlign.center), const SizedBox(height: 24),
                Text('dnb_settings_level'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(children: [Expanded(child: Slider(value: state.manualN.toDouble(), min: 1, max: 9, divisions: 8, activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12, onChanged: (val) => context.read<DualNBackBloc>().add(UpdateSettings(manualN: val.round())))), Text("${state.manualN}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))]),
                const Divider(color: Colors.white12, height: 30),
                Text('dnb_settings_speed'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                Row(children: [Expanded(child: Slider(value: state.manualSpeedMs / 1000, min: 1.0, max: 4.0, divisions: 6, activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12, onChanged: (val) => context.read<DualNBackBloc>().add(UpdateSettings(manualSpeedMs: (val * 1000).round())))), Text("${(state.manualSpeedMs / 1000).toStringAsFixed(1)}s", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor))]),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_btn_save_back'.tr(), () => context.read<DualNBackBloc>().add(ResetDualNBack()), isDark, isPrimary: true), const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAdaptBtn(BuildContext context, int value, String label, int currentValue, bool isDark, Color accent) {
    bool isSelected = value == currentValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<DualNBackBloc>().add(UpdateSettings(adaptationSpeed: value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? accent : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? accent : (isDark ? Colors.white12 : Colors.black12))),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54))))),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, DualNBackState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    double percent = state.totalRounds > 0 ? (state.score / (state.totalRounds * 2)) * 100 : 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: accent), const SizedBox(height: 30),
          Text('global_training_complete'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, color: isDark ? Colors.white54 : Colors.black54)), const SizedBox(height: 10),
          Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('dnb_success_rate'.tr(args: [state.currentN.toString()]), style: TextStyle(fontSize: 18, color: accent, fontWeight: FontWeight.bold)), const SizedBox(height: 50),
          _menuBtn(context, 'global_btn_continue'.tr(), () => context.read<DualNBackBloc>().add(StartGame(adaptive: state.isAdaptive)), isDark, isPrimary: true, icon: Icons.play_arrow_rounded), const SizedBox(height: 16),
          _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<DualNBackBloc>().add(ResetDualNBack()), isDark, isSecondary: true),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, DualNBackState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(indicatorColor: accent, labelColor: accent, unselectedLabelColor: isDark ? Colors.white38 : Colors.black38, tabs: [Tab(icon: const Icon(Icons.auto_graph_rounded), text: 'global_tab_adaptive'.tr()), Tab(icon: const Icon(Icons.tune_rounded), text: 'global_tab_manual'.tr())]),
          Expanded(child: TabBarView(children: [SingleChildScrollView(padding: const EdgeInsets.only(top: 20), child: _buildGraph(context, state, true, 'dnb_graph_adaptive'.tr(), isDark)), SingleChildScrollView(padding: const EdgeInsets.only(top: 20), child: _buildGraph(context, state, false, 'dnb_graph_manual'.tr(), isDark))])),
          const SizedBox(height: 20), _menuBtn(context, 'global_btn_back'.tr(), () => context.read<DualNBackBloc>().add(ResetDualNBack()), isDark), const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGraph(BuildContext context, DualNBackState state, bool adaptive, String title, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final history = state.history.where((e) => e.isAdaptive == adaptive).toList();
    
    if (history.isEmpty) {
      return Center(child: Text('global_no_data'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
    }

    double calculatePoints(DualNBackHistoryItem item) {
      double speedMultiplier = item.isVariableSpeed ? 2.0 : 2500 / item.speedMs; 
      return item.score * item.nLevel * speedMultiplier;
    }

    double maxPoints = 1.0;
    for (var item in history) {
      double pts = calculatePoints(item);
      if (pts > maxPoints) maxPoints = pts;
    }

    // Načtení preferovaného formátu času z globálního nastavení
    final bool is24h = context.read<SettingsBloc>().state.is24HourFormat;
    final DateFormat timeFormat = is24h ? DateFormat('HH:mm') : DateFormat('h:mm a');
    final DateFormat dateFormat = DateFormat('dd.MM.yyyy');

    // Seskupení podle dnů
    Map<String, List<DualNBackHistoryItem>> groupedHistory = {};
    for (var item in history) {
      String dayKey = dateFormat.format(item.date);
      if (!groupedHistory.containsKey(dayKey)) groupedHistory[dayKey] = [];
      groupedHistory[dayKey]!.add(item);
    }

    List<Widget> graphColumns = [];
    
    groupedHistory.forEach((dateString, dayItems) {
      // Datum a svislá oddělovací čára
      graphColumns.add(
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 16.0, bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, 
            children: [
              Text(dateString, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accent)),
              const SizedBox(height: 10),
              Container(width: 2, height: 200, color: isDark ? Colors.white12 : Colors.black12), 
            ],
          ),
        )
      );

      // Sloupce tréninků v daném dni
      for (var item in dayItems) {
        double pts = calculatePoints(item);
        double heightFactor = pts / maxPoints;
        double successRate = item.score / (state.totalRounds * 2); 
        
        Color barColor;
        if (successRate < 0.5) {
          barColor = Colors.redAccent;
        } else {
          double lerpFactor = (successRate - 0.5) * 2.0;
          barColor = Color.lerp(Colors.redAccent, Colors.greenAccent, lerpFactor) ?? Colors.greenAccent;
        }

        String speedStr = item.isVariableSpeed ? "1.5-2.5s" : "${(item.speedMs / 1000).toStringAsFixed(1)}s";
        String timeStr = timeFormat.format(item.date);

        graphColumns.add(
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(timeStr, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${pts.round()} ${'global_pts'.tr()}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('N=${item.nLevel}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                RotatedBox(quarterTurns: 3, child: Text(speedStr, style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                Container(width: 30, height: 120 * heightFactor + 10, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: barColor.withAlpha(100), blurRadius: 4)])),
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
            height: 300, 
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
