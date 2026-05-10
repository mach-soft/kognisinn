import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../bloc/e_corsi/e_corsi_bloc.dart';

class ECorsiScreen extends StatelessWidget {
  const ECorsiScreen({super.key});

  final List<Alignment> _blockPositions = const [
    Alignment(-0.8, -0.8), Alignment(0.2, -0.9), Alignment(0.8, -0.6),
    Alignment(-0.6, -0.2), Alignment(0.3, -0.1), Alignment(-0.9, 0.4),
    Alignment(-0.1, 0.7), Alignment(0.6, 0.8), Alignment(0.9, 0.2),
  ];

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
      create: (context) => ECorsiBloc(),
      child: BlocBuilder<ECorsiBloc, ECorsiState>(
        builder: (context, state) {
          // OPRAVA PRO SAMSUNG: WillPopScope
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == ECorsiPhase.menu) {
                return true;
              } else if (state.phase == ECorsiPhase.result || state.phase == ECorsiPhase.history) {
                context.read<ECorsiBloc>().add(ResetECorsi());
                return false;
              } else {
                bool quit = await _showInterruptDialog(context, isDark);
                if (!context.mounted) return false;
                if (quit) context.read<ECorsiBloc>().add(ResetECorsi());
                return false;
              }
            },
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Přidáno state pro dynamické skrývání
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

  Widget _buildHeader(bool isDark, ECorsiState state) {
    // Schováme hlavičku při samotném hraní a vyťukávání
    if (state.phase == ECorsiPhase.showing || state.phase == ECorsiPhase.input) {
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
              // PŘIDÁNA IKONA DO HLAVIČKY
              const Icon(Icons.apps_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Text('ecorsi_title'.tr(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ECorsiState state, bool isDark) {
    if (state.phase == ECorsiPhase.menu) return _buildMenu(context, isDark);
    if (state.phase == ECorsiPhase.result) return _buildResult(context, state, isDark);
    if (state.phase == ECorsiPhase.history) return _buildHistory(context, state, isDark);
    if (state.phase == ECorsiPhase.success) return _buildMessage(context, 'ecorsi_phase_success'.tr(), Icons.check_circle_outline, const Color(0xFF00E676), isDark, true);
    if (state.phase == ECorsiPhase.failure) return _buildMessage(context, 'ecorsi_phase_failure'.tr(), Icons.close, Colors.redAccent, isDark, false);

    String instruction = state.phase == ECorsiPhase.showing ? 'ecorsi_inst_watch'.tr() 
        : (state.mode == ECorsiMode.forward ? 'ecorsi_inst_forward'.tr() : 'ecorsi_inst_reverse'.tr());

    final Color accentColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

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
                child: Text('ecorsi_capacity'.tr(args: [state.currentSpan.toString()]), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accentColor)),
              ),
              Row(
                children: List.generate(3, (index) => Icon(Icons.favorite, size: 20, color: index < state.lives ? Colors.redAccent : (isDark ? Colors.white12 : Colors.black12))),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(instruction, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54, letterSpacing: 1.5)),
        const Spacer(),
        
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white12 : accentColor.withAlpha(20), width: 1.5),
              boxShadow: isDark ? [] : [BoxShadow(color: accentColor.withAlpha(15), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Stack(
              children: List.generate(9, (index) {
                bool isActive = state.activeBlockIndex == index;
                bool isTapped = state.userInputs.contains(index) && state.phase == ECorsiPhase.input;
                
                Color blockColor = isDark ? Colors.white.withAlpha(10) : accentColor.withAlpha(10);
                Color glowColor = Colors.transparent;
                
                if (isActive) { blockColor = accentColor; glowColor = accentColor; }
                if (isTapped) { blockColor = const Color(0xFF00E676); glowColor = const Color(0xFF00E676); }

                return Align(
                  alignment: _blockPositions[index],
                  child: GestureDetector(
                    onTap: () => context.read<ECorsiBloc>().add(BlockTapped(index)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive || isTapped ? 68 : 60, height: isActive || isTapped ? 68 : 60,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isActive || isTapped ? Colors.white : (isDark ? Colors.white24 : accentColor.withAlpha(30)), width: 2),
                        boxShadow: isActive || isTapped ? [BoxShadow(color: glowColor.withAlpha(150), blurRadius: 20, spreadRadius: 2)] : [],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, String text, IconData icon, Color color, bool isDark, bool isSuccess) {
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
          _menuBtn(context, isSuccess ? 'ecorsi_btn_increase'.tr() : 'ecorsi_btn_restart_round'.tr(), () => context.read<ECorsiBloc>().add(NextRound()), isDark, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // PŘIDÁNA VELKÁ IKONA DO MENU
          Icon(
            Icons.apps_rounded, 
            size: 80, 
            color: isDark ? const Color(0xFF00E5FF).withAlpha(150) : const Color(0xFF7000FF).withAlpha(150)
          ),
          const SizedBox(height: 40),
          
          _menuBtn(context, 'ecorsi_mode_forward'.tr(), () => context.read<ECorsiBloc>().add(StartECorsi(ECorsiMode.forward)), isDark, icon: Icons.arrow_forward_rounded, isPrimary: true),
          const SizedBox(height: 16),
          _menuBtn(context, 'ecorsi_mode_reverse'.tr(), () => context.read<ECorsiBloc>().add(StartECorsi(ECorsiMode.reverse)), isDark, icon: Icons.keyboard_double_arrow_left_rounded),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_analytics'.tr(), () => context.read<ECorsiBloc>().add(ShowECorsiHistory()), isDark, icon: Icons.insights_rounded, isSecondary: true),
          const SizedBox(height: 16),
          _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.pop(context), isDark, icon: Icons.power_settings_new_rounded, isSecondary: true),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, ECorsiState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_rounded, size: 80, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF)),
          const SizedBox(height: 30),
          Text('global_training_complete'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 10),
          Text('ecorsi_res_capacity'.tr(args: [state.currentSpan.toString()]), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          Text('ecorsi_res_score'.tr(args: [state.score.toString()]), style: TextStyle(fontSize: 18, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF), fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<ECorsiBloc>().add(ResetECorsi()), isDark, isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context, ECorsiState state, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (state.history.isEmpty)
             Center(child: Text("global_no_data".tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
          ...state.history.reversed.map((item) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : const Color(0xFF7000FF).withAlpha(10), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFF7000FF).withAlpha(20))
            ),
            child: ListTile(
              leading: Icon(item.mode == ECorsiMode.forward ? Icons.arrow_forward_rounded : Icons.keyboard_double_arrow_left_rounded, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF)),
              title: Text('ecorsi_hist_item'.tr(args: [item.maxSpan.toString(), item.score.toString()]), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              subtitle: Text('${item.date.day}.${item.date.month}. ${item.date.hour}:${item.date.minute.toString().padLeft(2,'0')}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ),
          )),
          const SizedBox(height: 40),
          _menuBtn(context, 'global_btn_back'.tr(), () => context.read<ECorsiBloc>().add(ResetECorsi()), isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _menuBtn(BuildContext context, String label, VoidCallback onTap, bool isDark, {bool isPrimary = false, bool isSecondary = false, IconData? icon}) {
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
              color: isSecondary ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSecondary ? (isDark ? Colors.white12 : Colors.black12) : (isDark ? accent.withAlpha(40) : accent.withAlpha(30)), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: textColor), const SizedBox(width: 12)],
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
