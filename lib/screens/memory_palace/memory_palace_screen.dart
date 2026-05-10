import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../bloc/memory_palace/memory_palace_bloc.dart';

class MemoryPalaceScreen extends StatelessWidget {
  const MemoryPalaceScreen({super.key});

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

    return BlocProvider(
      create: (context) => MemoryPalaceBloc(),
      child: BlocBuilder<MemoryPalaceBloc, MemoryPalaceState>(
        builder: (context, state) {
          // OPRAVA PRO SAMSUNG: WillPopScope
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == PalacePhase.menu) {
                return true;
              } else if (state.phase == PalacePhase.result || state.phase == PalacePhase.history || state.phase == PalacePhase.settings || state.phase == PalacePhase.setup) {
                context.read<MemoryPalaceBloc>().add(ResetPalace());
                return false;
              } else {
                bool quit = await _showInterruptDialog(context, isDark);
                if (!context.mounted) return false;
                if (quit) context.read<MemoryPalaceBloc>().add(ResetPalace());
                return false;
              }
            },
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7000FF)]).createShader(bounds),
          child: Text('palace_title'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MemoryPalaceState state, bool isDark) {
    if (state.phase == PalacePhase.menu) return _buildMenu(context, isDark);
    if (state.phase == PalacePhase.settings) return _buildSettings(context, state, isDark);
    if (state.phase == PalacePhase.setup) return _buildSetup(context, state, isDark);
    if (state.phase == PalacePhase.result) return _buildResult(context, state, isDark);
    if (state.phase == PalacePhase.history) return _buildHistory(context, state, isDark);
    
    if (state.phase == PalacePhase.success) return _buildMessage(context, state.isAdaptive ? 'palace_phase_expanded'.tr() : 'palace_phase_mastered'.tr(), Icons.account_balance_rounded, const Color(0xFF00E676), isDark, true, state);
    if (state.phase == PalacePhase.failure) return _buildMessage(context, 'palace_phase_failure'.tr(), Icons.warning_rounded, Colors.redAccent, isDark, false, state);

    final Color accentColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: accentColor.withAlpha(20), borderRadius: BorderRadius.circular(12), border: Border.all(color: accentColor.withAlpha(40))),
                child: Text('palace_capacity'.tr(args: [state.currentSpan.toString()]), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accentColor)),
              ),
              if (state.isAdaptive)
                Row(children: List.generate(3, (index) => Icon(Icons.favorite, size: 20, color: index < state.lives ? Colors.redAccent : (isDark ? Colors.white12 : Colors.black12)))),
            ],
          ),
        ),
        const Spacer(),
        
        if (state.phase == PalacePhase.encoding) ...[
          if (state.currentIndex < 0) ...[
            Icon(Icons.psychology_alt_rounded, size: 80, color: accentColor.withAlpha(150)),
            const SizedBox(height: 20),
            Text('palace_inst_prep'.tr(), textAlign: TextAlign.center, // <--- TOTO ZARUČÍ VŽDY STŘED 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 3)
      ),

          ] else if (state.currentIndex < state.currentSpan) ...[
            Text('palace_inst_encode'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54, letterSpacing: 2)),
            const SizedBox(height: 40),
            _neuroCard(isDark, accentColor, Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 60, color: accentColor.withAlpha(150)),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  // OPRAVA 1: Překlad lokace v UI
                  child: Text(state.activeLocations[state.currentIndex].tr(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  // OPRAVA 2: Překlad předmětu v UI
                  child: Text(state.activeItems[state.currentIndex].tr().toUpperCase(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(color: accentColor.withAlpha(100), blurRadius: 20)])),
                ),
              ],
            )),
          ] else ...[
            const CircularProgressIndicator(),
          ]
        ] else if (state.phase == PalacePhase.recall) ...[
          Text('palace_inst_recall'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54, letterSpacing: 2)),
          const SizedBox(height: 30),
          _neuroCard(isDark, accentColor, Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 30, color: accentColor),
              const SizedBox(width: 15),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  // OPRAVA 3: Překlad lokace při vzpomínání
                  child: Text(state.activeLocations[state.currentIndex].tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                ),
              ),
            ],
          ), padding: 20),
          const SizedBox(height: 50),
          Wrap(
            spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
            // OPRAVA 4: Překlad na samotném tlačítku, do eventu AnswerSelected jde ale dál nepřeložený klíč
            children: state.currentOptions.map((option) => _menuBtn(context, option.tr(), () => context.read<MemoryPalaceBloc>().add(AnswerSelected(option)), isDark, width: 150)).toList(),
          ),
        ],
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF).withAlpha(150) : const Color(0xFF7000FF).withAlpha(150)),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_mode_adaptive'.tr(), () => context.read<MemoryPalaceBloc>().add(StartAdaptive()), isDark, isPrimary: true, icon: Icons.auto_graph_rounded),
          const SizedBox(height: 16),
          _menuBtn(context, 'ds_mode_free'.tr(), () => context.read<MemoryPalaceBloc>().add(StartFreeTraining()), isDark, icon: Icons.tune_rounded),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_analytics'.tr(), () => context.read<MemoryPalaceBloc>().add(ShowPalaceHistory()), isDark, icon: Icons.insights_rounded, isSecondary: true),
          const SizedBox(height: 16),
          _menuBtn(context, 'global_settings'.tr(), () => context.read<MemoryPalaceBloc>().add(ShowSettings()), isDark, icon: Icons.settings_rounded, isSecondary: true),
          const SizedBox(height: 32),
          _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.pop(context), isDark, icon: Icons.power_settings_new_rounded, isDanger: true),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, MemoryPalaceState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _neuroCard(isDark, accent, Column(
          children: [
            Text('palace_settings_global'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
            const SizedBox(height: 30),
            
            Text('palace_settings_start_adaptive'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.defaultAdaptiveSpan.toDouble(), min: 1, max: 10, divisions: 9,
                    activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12,
                    onChanged: (val) => context.read<MemoryPalaceBloc>().add(UpdateSettings(span: val.round())),
                  ),
                ),
                Text("${state.defaultAdaptiveSpan}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
              ],
            ),
            const Divider(color: Colors.white12, height: 40),
            
            Text('palace_settings_time'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.defaultSpeedMs / 1000, min: 1.0, max: 5.0, divisions: 8,
                    activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12,
                    onChanged: (val) => context.read<MemoryPalaceBloc>().add(UpdateSettings(speedMs: (val * 1000).round())),
                  ),
                ),
                Text("${(state.defaultSpeedMs / 1000).toStringAsFixed(1)}s", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
              ],
            ),
          ]
        ), padding: 24),
        const SizedBox(height: 50),
        _menuBtn(context, 'global_btn_save_back'.tr(), () => context.read<MemoryPalaceBloc>().add(ResetPalace()), isDark, isPrimary: true),
      ],
    );
  }

  Widget _buildSetup(BuildContext context, MemoryPalaceState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _neuroCard(isDark, accent, Column(
          children: [
            Text('palace_setup_title'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent, letterSpacing: 2)),
            const SizedBox(height: 30),
            
            Text('palace_setup_capacity'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.currentSpan.toDouble(), min: 1, max: 18, divisions: 17,
                    activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12,
                    onChanged: (val) => context.read<MemoryPalaceBloc>().add(UpdateSetup(span: val.round())),
                  ),
                ),
                Text("${state.currentSpan}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
              ],
            ),
            const Divider(color: Colors.white12, height: 40),
            
            Text('palace_setup_time_item'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: state.currentSpeedMs / 1000, min: 1.0, max: 5.0, divisions: 8,
                    activeColor: accent, inactiveColor: isDark ? Colors.white12 : Colors.black12,
                    onChanged: (val) => context.read<MemoryPalaceBloc>().add(UpdateSetup(speedMs: (val * 1000).round())),
                  ),
                ),
                Text("${(state.currentSpeedMs / 1000).toStringAsFixed(1)}s", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
              ],
            ),
          ]
        ), padding: 24),
        const SizedBox(height: 50),
        _menuBtn(context, 'palace_btn_start_round'.tr(), () => context.read<MemoryPalaceBloc>().add(NextRound()), isDark, isPrimary: true, icon: Icons.play_arrow_rounded),
        const SizedBox(height: 16),
        _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<MemoryPalaceBloc>().add(ResetPalace()), isDark, isSecondary: true),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, String text, IconData icon, Color color, bool isDark, bool isSuccess, MemoryPalaceState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(20), boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 40)]),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 30),
          Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: color)),
          const SizedBox(height: 50),
          if (state.isAdaptive)
            _menuBtn(context, isSuccess ? 'palace_btn_next_room'.tr() : 'palace_btn_repeat'.tr(), () => context.read<MemoryPalaceBloc>().add(NextRound()), isDark, isPrimary: true)
          else
            _menuBtn(context, 'palace_btn_setup_next'.tr(), () => context.read<MemoryPalaceBloc>().add(ShowSetup()), isDark, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, MemoryPalaceState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF)),
          const SizedBox(height: 30),
          Text('ds_capacity_empty'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 10),
          Text('palace_res_capacity'.tr(args: [state.currentSpan.toString()]), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('palace_res_score'.tr(args: [state.score.toString()]), style: TextStyle(fontSize: 18, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<MemoryPalaceBloc>().add(ResetPalace()), isDark, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, MemoryPalaceState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            tabs: [
              Tab(icon: const Icon(Icons.auto_graph_rounded), text: 'global_tab_adaptive'.tr()),
              Tab(icon: const Icon(Icons.tune_rounded), text: 'palace_tab_free'.tr()),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPalaceHistoryList(state, true, isDark, accent),
                _buildPalaceHistoryList(state, false, isDark, accent),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _menuBtn(context, 'global_btn_back'.tr(), () => context.read<MemoryPalaceBloc>().add(ResetPalace()), isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPalaceHistoryList(MemoryPalaceState state, bool adaptive, bool isDark, Color accent) {
    final filtered = state.history.where((item) => item.isAdaptive == adaptive).toList();
    if (filtered.isEmpty) return Center(child: Text('global_no_data'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered.reversed.toList()[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : accent.withAlpha(10), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: ListTile(
            title: Text('palace_hist_item'.tr(args: [item.maxSpan.toString(), item.score.toString()]), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            subtitle: Text('${item.date.day}.${item.date.month}. | ${item.date.hour}:${item.date.minute.toString().padLeft(2,'0')}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
        );
      },
    );
  }

  Widget _neuroCard(bool isDark, Color accent, Widget child, {double padding = 30}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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

  Widget _menuBtn(BuildContext context, String label, VoidCallback onTap, bool isDark, {double width = 320, bool isPrimary = false, bool isSecondary = false, bool isDanger = false, IconData? icon}) {
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
              gradient: isSecondary ? null : LinearGradient(colors: isDark ? [const Color(0xFF23253A), const Color(0xFF161828)] : [Colors.white, const Color(0xFFF1F5F9)]),
              color: isSecondary ? Colors.transparent : (isDanger ? Colors.redAccent.withAlpha(20) : null),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDanger ? Colors.redAccent.withAlpha(50) : (isSecondary ? (isDark ? Colors.white12 : Colors.black12) : (isDark ? accent.withAlpha(40) : accent.withAlpha(30))), width: 1.5),
            ),
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
