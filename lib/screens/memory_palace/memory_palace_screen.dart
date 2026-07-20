import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../../bloc/memory_palace/memory_palace_bloc.dart';
import '../../bloc/settings/settings_bloc.dart';

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
            Expanded(child: Text('palace_title'.tr(), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('module_info_goal'.tr(), 'palace_info_goal_desc'.tr(), Icons.track_changes_rounded, accent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_rules'.tr(), 'palace_info_rules_desc'.tr(), Icons.rule_rounded, Colors.orangeAccent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('module_info_practice'.tr(), 'palace_info_prac_desc'.tr(), Icons.lightbulb_outline_rounded, const Color(0xFF00E676), isDark),
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
      create: (context) => MemoryPalaceBloc(),
      child: BlocConsumer<MemoryPalaceBloc, MemoryPalaceState>(
        listenWhen: (previous, current) {
          return previous.phase != PalacePhase.result && current.phase == PalacePhase.result;
        },
        listener: (context, state) {
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              
              if (state.phase == PalacePhase.menu) {
                Navigator.of(context).pop();
                return;
              } else if (state.phase == PalacePhase.result || state.phase == PalacePhase.history || state.phase == PalacePhase.settings || state.phase == PalacePhase.setup) {
                context.read<MemoryPalaceBloc>().add(ResetPalace());
                return;
              } else {
                bool quit = await _showInterruptDialog(context, isDark);
                if (!context.mounted) return;
                if (quit) context.read<MemoryPalaceBloc>().add(ResetPalace());
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

  String _getDifficultyLabel(MemoryPalaceState state) {
    if (state.itemsPerLocation >= 3 && (state.randomizeLocations || state.randomizeItems)) {
      return 'palace_diff_expert_plus'.tr();
    } else if (state.itemsPerLocation > 1 || state.randomizeLocations) {
      return 'palace_diff_expert'.tr();
    }
    return 'palace_diff_standard'.tr();
  }

  Color _getDifficultyColor(MemoryPalaceState state) {
    if (state.itemsPerLocation >= 3 && (state.randomizeLocations || state.randomizeItems)) {
      return const Color(0xFFD500F9); // Fialová pro Expert+
    } else if (state.itemsPerLocation > 1 || state.randomizeLocations) {
      return Colors.orangeAccent; // Oranžová pro Expert
    }
    return const Color(0xFF00E676); // Zelená pro Standard
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
            Text('palace_inst_prep'.tr(), textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 3)
      ),
          ] else if (state.currentIndex < (state.currentSpan * state.itemsPerLocation)) ...[
            Text('palace_inst_encode'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54, letterSpacing: 2)),
            const SizedBox(height: 40),
            
            Builder(
              builder: (context) {
                int targetLocIndex = state.currentIndex ~/ state.itemsPerLocation;
                String loc = state.activeLocations[targetLocIndex];
                String item = state.activeItems[state.currentIndex];
                
                String locDisplay = loc.tr();
                if (state.itemsPerLocation > 1) {
                  int itemPos = (state.currentIndex % state.itemsPerLocation) + 1;
                  locDisplay += " ($itemPos/${state.itemsPerLocation})";
                }

                return _neuroCard(isDark, accentColor, Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, size: 60, color: accentColor.withAlpha(150)),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(locDisplay, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(item.tr().toUpperCase(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: textColor, shadows: [Shadow(color: accentColor.withAlpha(100), blurRadius: 20)])),
                    ),
                  ],
                ));
              }
            )
          ] else ...[
            const CircularProgressIndicator(),
          ]
        ] else if (state.phase == PalacePhase.recall) ...[
          Text('palace_inst_recall'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54, letterSpacing: 2)),
          const SizedBox(height: 30),
          
          Builder(
            builder: (context) {
              int targetItemIndex = state.recallQueue[state.currentIndex];
              int targetLocIndex = targetItemIndex ~/ state.itemsPerLocation;
              String loc = state.activeLocations[targetLocIndex];
              
              String locDisplay = loc.tr();
              if (state.itemsPerLocation > 1) {
                int itemPos = (targetItemIndex % state.itemsPerLocation) + 1;
                locDisplay += " ($itemPos/${state.itemsPerLocation})";
              }

              return _neuroCard(isDark, accentColor, Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, size: 30, color: accentColor),
                  const SizedBox(width: 15),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(locDisplay, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                    ),
                  ),
                ],
              ), padding: 20);
            }
          ),
          const SizedBox(height: 50),
          Wrap(
            spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
            children: state.currentOptions.map((option) => _menuBtn(context, option.tr(), () => context.read<MemoryPalaceBloc>().add(AnswerSelected(option)), isDark, width: 150)).toList(),
          ),
        ],
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final MemoryPalaceState state = context.read<MemoryPalaceBloc>().state;
    final diffLabel = _getDifficultyLabel(state);
    final diffColor = _getDifficultyColor(state);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 80.0, left: 24.0, right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Icon(Icons.account_balance_rounded, size: 80, color: accent.withAlpha(150)),
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
              
              _menuBtn(context, 'global_mode_adaptive'.tr(), () => context.read<MemoryPalaceBloc>().add(StartAdaptive()), isDark, isPrimary: true, icon: Icons.auto_graph_rounded, badgeText: diffLabel, badgeColor: diffColor),
              const SizedBox(height: 16),
              _menuBtn(context, 'ds_mode_free'.tr(), () => context.read<MemoryPalaceBloc>().add(StartFreeTraining()), isDark, icon: Icons.tune_rounded, badgeText: diffLabel, badgeColor: diffColor),
              const SizedBox(height: 40),
              _menuBtn(context, 'global_analytics'.tr(), () => context.read<MemoryPalaceBloc>().add(ShowPalaceHistory()), isDark, icon: Icons.insights_rounded, isSecondary: true),
              const SizedBox(height: 16),
              _menuBtn(context, 'global_settings'.tr(), () => context.read<MemoryPalaceBloc>().add(ShowSettings()), isDark, icon: Icons.settings_rounded, isSecondary: true),
              const SizedBox(height: 32),
              _menuBtn(context, 'global_exit_module'.tr(), () => Navigator.pop(context), isDark, icon: Icons.power_settings_new_rounded, isDanger: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context, MemoryPalaceState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 80.0, left: 24.0, right: 24.0),
          child: Column(
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
                  const Divider(color: Colors.white12, height: 30),
                  
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
                  const Divider(color: Colors.white12, height: 30),

                  Text('palace_settings_items_per_loc'.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: isDark ? Colors.white54 : Colors.black54)),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: state.itemsPerLocation.toDouble(), min: 1, max: 5, divisions: 4,
                          activeColor: Colors.orangeAccent, inactiveColor: isDark ? Colors.white12 : Colors.black12,
                          onChanged: (val) {
                            context.read<MemoryPalaceBloc>().add(UpdateSettings(itemsPerLoc: val.round()));
                            if (val.round() == 1 && state.randomizeItems) {
                              context.read<MemoryPalaceBloc>().add(UpdateSettings(randItems: false));
                            }
                          },
                        ),
                      ),
                      Text("${state.itemsPerLocation}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: Colors.orangeAccent,
                    title: Text('palace_settings_rand_locs'.tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    value: state.randomizeLocations,
                    onChanged: (val) => context.read<MemoryPalaceBloc>().add(UpdateSettings(randLocs: val)),
                  ),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: Colors.orangeAccent,
                    title: Text('palace_settings_rand_items'.tr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    value: state.randomizeItems,
                    onChanged: (val) {
                      context.read<MemoryPalaceBloc>().add(UpdateSettings(randItems: val));
                      if (val == true && state.itemsPerLocation == 1) {
                        context.read<MemoryPalaceBloc>().add(UpdateSettings(itemsPerLoc: 2));
                      }
                    },
                  ),

                ]
              ), padding: 24),
              const SizedBox(height: 40),
              _menuBtn(context, 'global_btn_save_back'.tr(), () => context.read<MemoryPalaceBloc>().add(ResetPalace()), isDark, isPrimary: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetup(BuildContext context, MemoryPalaceState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 80.0, left: 24.0, right: 24.0),
          child: Column(
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
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text, IconData icon, Color color, bool isDark, bool isSuccess, MemoryPalaceState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 80.0, left: 24.0, right: 24.0),
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
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(List<PalaceHistoryItem> history, String title, bool isDark, Color accent, bool showGamifiedValues) {
    if (history.isEmpty) return const SizedBox.shrink();

    final displayData = history.length > 10 ? history.sublist(history.length - 10) : history;
    
    List<double> yValues = displayData.map((e) {
      if (showGamifiedValues) {
        return MemoryPalaceBloc.calculateKci(e.score, e.itemsPerLocation, e.randomizeLocations, e.randomizeItems).toDouble();
      } else {
        return e.maxSpan.toDouble();
      }
    }).toList();

    double minY = yValues.reduce((a, b) => a < b ? a : b);
    double maxY = yValues.reduce((a, b) => a > b ? a : b);
    
    if (showGamifiedValues) {
      minY = (minY - 10).clamp(0, double.infinity);
      maxY = maxY + 10;
    } else {
      minY = (minY - 1).clamp(0, double.infinity);
      maxY = maxY + 1;
    }

    final spots = displayData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), yValues[e.key]);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title, 
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)
          ),
        ),
        Container(
          height: 160,
          width: double.infinity,
          padding: const EdgeInsets.only(right: 24, left: 10, top: 16, bottom: 10),
          margin: const EdgeInsets.only(bottom: 20.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                horizontalInterval: showGamifiedValues ? 20 : 1, 
                getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white12 : Colors.black12, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: showGamifiedValues ? 50 : 1,
                    reservedSize: 35,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (displayData.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: accent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(radius: 4, color: accent, strokeWidth: 2, strokeColor: isDark ? const Color(0xFF1A1A2E) : Colors.white);
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: accent.withAlpha(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, MemoryPalaceState state, bool isDark) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    final adaptiveHistory = state.history.where((e) => e.isAdaptive).toList();

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final showGamified = settingsState.showGamifiedValues;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 80.0, left: 24.0, right: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.hub_rounded, size: 80, color: accent),
                  const SizedBox(height: 30),
                  Text('ds_capacity_empty'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 3, color: isDark ? Colors.white54 : Colors.black54)),
                  const SizedBox(height: 10),
                  Text('palace_res_capacity'.tr(args: [state.currentSpan.toString()]), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  
                  if (showGamified)
                    Text('global_score_kci'.tr(args: [MemoryPalaceBloc.calculateKci(state.score, state.itemsPerLocation, state.randomizeLocations, state.randomizeItems).toString()]), 
                      style: TextStyle(fontSize: 18, color: accent, fontWeight: FontWeight.bold))
                  else
                    Text('palace_res_score'.tr(args: [state.score.toString()]), 
                      style: TextStyle(fontSize: 18, color: accent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),

                  if (adaptiveHistory.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft, 
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text('global_progress'.tr(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black)),
                      )
                    ),
                    _buildPerformanceChart(adaptiveHistory, 'global_mode_adaptive'.tr(), isDark, accent, showGamified),
                  ],

                  const SizedBox(height: 30),
                  _menuBtn(context, 'global_btn_to_menu'.tr(), () => context.read<MemoryPalaceBloc>().add(ResetPalace()), isDark, isPrimary: true),
                ],
              ),
            ),
          ),
        );
      },
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

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final showGamified = settingsState.showGamifiedValues;

        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 20),
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildPerformanceChart(filtered, adaptive ? 'global_mode_adaptive'.tr() : 'palace_tab_free'.tr(), isDark, accent, showGamified),
              ),
              
            ...filtered.reversed.map((item) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : accent.withAlpha(10), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: ListTile(
                title: Builder(
                  builder: (context) {
                    String subScore;
                    if (showGamified) {
                      String kciText = 'global_score_kci'.tr(args: [MemoryPalaceBloc.calculateKci(item.score, item.itemsPerLocation, item.randomizeLocations, item.randomizeItems).toString()]);
                      subScore = '${item.score} | $kciText';
                    } else {
                      subScore = item.score.toString();
                    }
                    
                    return Text('palace_hist_item'.tr(args: [item.maxSpan.toString(), subScore]), 
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)));
                  },
                ),
                subtitle: Text('${item.date.day}.${item.date.month}. | ${item.date.hour}:${item.date.minute.toString().padLeft(2,'0')}', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              ),
            )),
          ],
        );
      }
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

  Widget _menuBtn(BuildContext context, String label, VoidCallback onTap, bool isDark, {double width = 320, bool isPrimary = false, bool isSecondary = false, bool isDanger = false, IconData? icon, String? badgeText, Color? badgeColor}) {
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
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20, color: isDanger ? Colors.redAccent : textColor), const SizedBox(width: 12)],
                    Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDanger ? Colors.redAccent : textColor, letterSpacing: 1.5)))),
                  ],
                ),
                if (badgeText != null && badgeColor != null)
                  Positioned(
                    top: -1.5, right: -1.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(isDark ? 50 : 30),
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomLeft: Radius.circular(10)),
                        border: Border.all(color: badgeColor.withAlpha(80)),
                      ),
                      child: Text(badgeText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: badgeColor, letterSpacing: 1.2)),
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
