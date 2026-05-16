import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

import 'main_menu_screen.dart'; 

class CognitiveProfileScreen extends StatefulWidget {
  const CognitiveProfileScreen({super.key});

  @override
  State<CognitiveProfileScreen> createState() => _CognitiveProfileScreenState();
}

class _CognitiveProfileScreenState extends State<CognitiveProfileScreen> {
  bool _isLoading = true;

  // Hodnoty pro pavučinový graf (0 - 100)
  double _scoreWorkingMemory = 0;   
  double _scoreVisuospatial = 0;    
  double _scoreExecutive = 0;       
  double _scoreAssociative = 0;     
  double _scoreAttention = 0;       

  // Hodnoty pro validitu vzorku (0 - 10)
  int _valWorkingMemory = 0;
  int _valVisuospatial = 0;
  int _valExecutive = 0;
  int _valAssociative = 0;
  int _valAttention = 0;

  // Globální nastavení pro klouzavý medián
  int _medianWindowSize = 10; 

  @override
  void initState() {
    super.initState();
    _loadAndNormalizeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAndNormalizeData();
  }

  // --- FUNKCE: Výpočet klouzavého mediánu z historie ---
  double _getRollingMedian(SharedPreferences prefs, String historyKey, String calibKey, double defaultVal, {bool isInt = false}) {
    List<String>? history = prefs.getStringList(historyKey);
    List<double> values = [];

    if (history != null && history.isNotEmpty) {
      Iterable<String> recent = history.length > _medianWindowSize ? history.skip(history.length - _medianWindowSize) : history;
      values = recent.map((e) => double.tryParse(e) ?? defaultVal).toList();
    } else {
      if (isInt) {
        int? calib = prefs.getInt(calibKey);
        if (calib != null) values.add(calib.toDouble());
      } else {
        double? calib = prefs.getDouble(calibKey);
        if (calib != null) values.add(calib);
      }
    }

    if (values.isEmpty) return defaultVal;

    values.sort();
    int middle = values.length ~/ 2;
    if (values.length % 2 == 1) {
      return values[middle];
    } else {
      return (values[middle - 1] + values[middle]) / 2.0;
    }
  }

  Future<void> _loadAndNormalizeData() async {
    final prefs = await SharedPreferences.getInstance();

    _medianWindowSize = prefs.getInt('settings_median_window') ?? 10;

    final double stroopTime = _getRollingMedian(prefs, 'history_stroop', 'calib_stroop', 1200.0);
    final double digitSpan = _getRollingMedian(prefs, 'history_digit_span', 'calib_digit_span', 4.0, isInt: true);
    final double eCorsiSpan = _getRollingMedian(prefs, 'history_ecorsi', 'calib_ecorsi', 3.0, isInt: true);
    final double palaceScore = _getRollingMedian(prefs, 'history_palace', 'calib_palace', 0.0, isInt: true);
    final double dnbRate = _getRollingMedian(prefs, 'history_dnb', 'calib_dnb', 0.0);

    // Převod na základní indexy (0 - 100)
    double baseStroop = ((1200.0 - stroopTime) / (1200.0 - 400.0)) * 100.0;
    double baseDigit = ((digitSpan - 3.0) / (12.0 - 3.0)) * 100.0;
    double baseCorsi = ((eCorsiSpan - 2.0) / (7.0 - 2.0)) * 100.0;
    double basePalace = (palaceScore / 5.0) * 100.0;
    double baseDnb = dnbRate * 100.0;

    baseStroop = baseStroop.clamp(0.0, 100.0);
    baseDigit = baseDigit.clamp(0.0, 100.0);
    baseCorsi = baseCorsi.clamp(0.0, 100.0);
    basePalace = basePalace.clamp(0.0, 100.0);
    baseDnb = baseDnb.clamp(0.0, 100.0);

    // NAČTENÍ VALIDITY Z PAMĚTI
    int vDnb = prefs.getInt('validity_working_memory') ?? (prefs.getStringList('dnb_daily_history')?.length ?? 0);
    int vStroop = prefs.getInt('validity_inhibition') ?? (prefs.getStringList('stroop_daily_history')?.length ?? 0);
    int vDigit = prefs.getInt('validity_digit_span') ?? (prefs.getStringList('ds_daily_history')?.length ?? 0);
    int vCorsi = prefs.getInt('validity_visuospatial') ?? (prefs.getStringList('ecorsi_daily_history')?.length ?? 0);
    int vPalace = prefs.getInt('validity_associative') ?? (prefs.getStringList('palace_daily_history')?.length ?? 0);

    setState(() {
      // Vědecká syntéza skóre
      _scoreWorkingMemory = (baseDnb * 0.60) + (baseDigit * 0.40);
      _scoreVisuospatial = (baseCorsi * 0.80) + (baseDnb * 0.20);
      _scoreExecutive = (baseStroop * 0.70) + (baseDnb * 0.30);
      _scoreAssociative = basePalace;
      _scoreAttention = (baseStroop * 0.50) + (baseDnb * 0.50);

      // Syntéza validity 
      _valWorkingMemory = (vDnb < vDigit ? vDnb : vDigit).clamp(0, 10);
      _valVisuospatial = (vCorsi < vDnb ? vCorsi : vDnb).clamp(0, 10);
      _valExecutive = (vStroop < vDnb ? vStroop : vDnb).clamp(0, 10);
      _valAssociative = vPalace.clamp(0, 10);
      _valAttention = (vStroop < vDnb ? vStroop : vDnb).clamp(0, 10);

      _isLoading = false;
    });
  }

  Future<void> _resetCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_is_calibrated', false);
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainMenuScreen()), 
        (Route<dynamic> route) => false
      );
    }
  }

  Future<void> _showMedianSettingsDialog(Color accent, bool isDark) async {
    int tempValue = _medianWindowSize;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Nastavení mediánu', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Z kolika posledních testů se má profil počítat?\n\nAktuálně: $tempValue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: tempValue.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: accent,
                    inactiveColor: accent.withAlpha(50),
                    label: tempValue.toString(),
                    onChanged: (val) {
                      setDialogState(() => tempValue = val.toInt());
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Zrušit', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('settings_median_window', tempValue);
                    navigator.pop();
                    
                    if (mounted) {
                      setState(() => _isLoading = true);
                      _loadAndNormalizeData();
                    }
                  },
                  child: Text('Uložit a přepočítat', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])
        ),
        child: SafeArea(
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: accent))
            : Column(
                children: [
                  _buildHeader(context, isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildRadarChart(isDark, accent),
                          const SizedBox(height: 40),
                          _buildStatRows(context, isDark, accent),
                          const SizedBox(height: 30),
                          
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _resetCalibration,
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                label: Text('profile_debug_reset'.tr()), 
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showMedianSettingsDialog(accent, isDark),
                                icon: const Icon(Icons.auto_graph_rounded, size: 20),
                                label: const Text('Medián'), 
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: accent,
                                  side: BorderSide(color: accent),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF7000FF)]).createShader(bounds),
            child: Text('profile_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          ),
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildRadarChart(bool isDark, Color accent) {
    final titleStyle = TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 9, fontWeight: FontWeight.bold);

    return Container(
      height: 380,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(color: accent.withAlpha(15), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              dataEntries: List.generate(5, (_) => const RadarEntry(value: 100)),
            ),
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              dataEntries: List.generate(5, (_) => const RadarEntry(value: 0)),
            ),
            RadarDataSet(
              fillColor: accent.withAlpha(60),
              borderColor: accent,
              entryRadius: 4,
              dataEntries: [
                RadarEntry(value: _scoreWorkingMemory),
                RadarEntry(value: _scoreVisuospatial),
                RadarEntry(value: _scoreExecutive),
                RadarEntry(value: _scoreAssociative),
                RadarEntry(value: _scoreAttention),
              ],
            )
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 1.5),
          gridBorderData: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 1),
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.transparent), 
          tickBorderData: const BorderSide(color: Colors.transparent),
          
          titlePositionPercentageOffset: 0.15, 
          titleTextStyle: titleStyle, 
          
          getTitle: (index, angle) {
            switch (index) {
              case 0: return RadarChartTitle(text: 'profile_wm'.tr().replaceAll('\\n', '\n'));
              case 1: return RadarChartTitle(text: 'profile_vs'.tr().replaceAll('\\n', '\n'));
              case 2: return RadarChartTitle(text: 'profile_exe'.tr().replaceAll('\\n', '\n'));
              case 3: return RadarChartTitle(text: 'profile_asc'.tr().replaceAll('\\n', '\n'));
              case 4: return RadarChartTitle(text: 'profile_att'.tr().replaceAll('\\n', '\n'));
              default: return const RadarChartTitle(text: '');
            }
          },
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutExpo,
      ),
    );
  }

  Widget _buildStatRows(BuildContext context, bool isDark, Color accent) {
    double totalScore = (_scoreWorkingMemory + _scoreVisuospatial + _scoreExecutive + _scoreAssociative + _scoreAttention) / 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent.withAlpha(40), accent.withAlpha(10)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withAlpha(50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('profile_kci_title'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('profile_kci_subtitle'.tr(), style: TextStyle(fontSize: 10, color: accent)),
                  ],
                ),
                Text('${totalScore.round()}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ZDE VKLÁDÁME "domainKey" PRO SPRÁVNÉ NAČTENÍ PŘEKLADU V DIALOGU
          _statRow(context, 'profile_stat_wm'.tr(), 'wm', _scoreWorkingMemory, _valWorkingMemory, isDark, accent),
          _statRow(context, 'profile_stat_vs'.tr(), 'vs', _scoreVisuospatial, _valVisuospatial, isDark, accent),
          _statRow(context, 'profile_stat_exe'.tr(), 'exe', _scoreExecutive, _valExecutive, isDark, accent),
          _statRow(context, 'profile_stat_asc'.tr(), 'asc', _scoreAssociative, _valAssociative, isDark, accent),
          _statRow(context, 'profile_stat_att'.tr(), 'att', _scoreAttention, _valAttention, isDark, accent),
        ],
      ),
    );
  }

  // --- NOVÁ FUNKCE PRO VYSVĚTLUJÍCÍ DIALOG K DOMÉNĚ ---
  void _showDomainInfoDialog(BuildContext context, String title, String domainKey, Color accent, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('profile_info_hdr_desc'.tr(), 'profile_info_${domainKey}_desc'.tr(), Icons.psychology_rounded, accent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('profile_info_hdr_prac'.tr(), 'profile_info_${domainKey}_prac'.tr(), Icons.lightbulb_outline_rounded, Colors.orangeAccent, isDark),
              const SizedBox(height: 16),
              _buildDialogSection('profile_info_hdr_calc'.tr(), 'profile_info_${domainKey}_calc'.tr(), Icons.calculate_outlined, const Color(0xFF00E676), isDark),
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

  Widget _buildValidityBadge(BuildContext context, int validity, bool isDark) {
    Color color;
    if (validity == 0) {
      color = isDark ? Colors.white38 : Colors.black38;
    } else if (validity < 4) {
      color = Colors.redAccent;
    } else if (validity < 8) {
      color = Colors.amber;
    } else {
      color = const Color(0xFF00E676);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'profile_val_title'.tr(), 
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold)
                    )
                  ),
                ],
              ),
              content: Text(
                'profile_val_desc'.tr(), 
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.5)
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(validity >= 8 ? Icons.verified_rounded : Icons.info_outline_rounded, size: 10, color: color),
              const SizedBox(width: 4),
              Text(
                'VAL: $validity/10',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPRAVENÁ ŘÁDKA METRIKY (PŘIDÁNO KLIKNUTÍ A IKONKA) ---
    // --- UPRAVENÁ ŘÁDKA METRIKY (OPRAVA OVERFLOW PRO DLOUHÉ TEXTY) ---
  Widget _statRow(BuildContext context, String label, String domainKey, double score, int validity, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. ZDE JE EXPANDED: Zabrání tomu, aby text vytlačil skóre z obrazovky
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showDomainInfoDialog(context, label, domainKey, accent, isDark),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 2. ZDE JE FLEXIBLE: Zalomení textu, pokud je moc dlouhý (např. v němčině)
                          Flexible(
                            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.help_outline_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildValidityBadge(context, validity, isDark),
              ],
            ),
          ),
          const SizedBox(width: 12), // Mezera mezi dlouhým textem a boxem se skóre
          Container(
            width: 50, padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5), borderRadius: BorderRadius.circular(8)),
            child: Text('${score.round()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent)),
          ),
        ],
      ),
    );
  }

}
