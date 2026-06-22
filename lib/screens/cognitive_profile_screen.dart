import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'main_menu_screen.dart'; 

class CognitiveProfileScreen extends StatefulWidget {
  const CognitiveProfileScreen({super.key});

  @override
  State<CognitiveProfileScreen> createState() => _CognitiveProfileScreenState();
}

class _CognitiveProfileScreenState extends State<CognitiveProfileScreen> {
  bool _isLoading = true;

  // Hodnoty pro pavučinový graf
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

  // Globální nastavení
  int _medianWindowSize = 10; 
  double _chartScale = 100.0;
  
  // Psychometrická normalizace na škálu 0 - 300 (100 = baseline)
  double _calcKci(double val, double worst, double baseline, double trained, {bool reverse = false}) {
    if (reverse) { // Pro časové úlohy (méně je lépe)
      if (val >= baseline) {
        // Horší nebo rovno průměru (čas je vyšší) -> škála 0 až 100
        return 100.0 - (((val - baseline) / (worst - baseline)) * 100.0).clamp(0.0, 100.0);
      } else {
        // Lepší než průměr (čas je nižší) -> škála 100 až 300 (prostor 200 bodů)
        return 100.0 + (((baseline - val) / (baseline - trained)) * 200.0).clamp(0.0, 200.0);
      }
    } else { // Pro kapacitní úlohy (více je lépe)
      if (val <= baseline) {
        // Horší nebo rovno průměru -> škála 0 až 100
        return (((val - worst) / (baseline - worst)) * 100.0).clamp(0.0, 100.0);
      } else {
        // Lepší než průměr -> škála 100 až 300 (prostor 200 bodů)
        return 100.0 + (((val - baseline) / (trained - baseline)) * 200.0).clamp(0.0, 200.0);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _loadAndNormalizeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAndNormalizeData();
  }

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
    return values.length % 2 == 1 ? values[middle] : (values[middle - 1] + values[middle]) / 2.0;
  }

  Future<void> _loadAndNormalizeData() async {
    final prefs = await SharedPreferences.getInstance();
    _medianWindowSize = 10; 

    // Lokální helper pro DNB
    double getDnbMedian() {
      List<String>? dnbHistoryStr = prefs.getStringList('dnb_history');
      double fallback = (prefs.getDouble('calib_dnb') ?? 0.5) * 2.0;
      
      if (dnbHistoryStr == null || dnbHistoryStr.isEmpty) return fallback;
      
      Iterable<String> recent = dnbHistoryStr.length > _medianWindowSize ? dnbHistoryStr.skip(dnbHistoryStr.length - _medianWindowSize) : dnbHistoryStr;
      List<double> scores = [];
      
      for (String s in recent) {
        final parts = s.split('|');
        if (parts.length >= 6) {
           int nLevel = int.tryParse(parts[1]) ?? 2;
           int score = int.tryParse(parts[2]) ?? 0;
           int speed = int.tryParse(parts[4]) ?? 2500;
           bool isVar = parts[5] == 'true';
           
           double speedMultiplier = isVar ? 2.0 : 2500 / speed;
           scores.add((score / 40.0) * nLevel * speedMultiplier);
        }
      }
      
      if (scores.isEmpty) return fallback;
      scores.sort();
      int mid = scores.length ~/ 2;
      return scores.length % 2 == 1 ? scores[mid] : (scores[mid - 1] + scores[mid]) / 2.0;
    }

    // Lokální helper pro Digit Span
    double getDigitSpanMedian() {
      List<String>? dsHistoryStr = prefs.getStringList('history_digit_span');
      double fallback = (prefs.getInt('calib_digit_span') ?? 4).toDouble();
      
      if (dsHistoryStr == null || dsHistoryStr.isEmpty) return fallback;
      
      Iterable<String> recent = dsHistoryStr.length > _medianWindowSize ? dsHistoryStr.skip(dsHistoryStr.length - _medianWindowSize) : dsHistoryStr;
      List<double> scores = [];
      
      for (String s in recent) {
        if (s.contains('|')) {
           final parts = s.split('|');
           scores.add((int.tryParse(parts[1]) ?? 4).toDouble());
        } else {
           scores.add((double.tryParse(s) ?? 4.0)); 
        }
      }
      
      if (scores.isEmpty) return fallback;
      scores.sort();
      int mid = scores.length ~/ 2;
      return scores.length % 2 == 1 ? scores[mid] : (scores[mid - 1] + scores[mid]) / 2.0;
    }

    // Načtení dat
    final double stroopTime = _getRollingMedian(prefs, 'history_stroop', 'calib_stroop', 1200.0);
    final double digitSpan = getDigitSpanMedian(); 
    final double eCorsiSpan = _getRollingMedian(prefs, 'history_ecorsi', 'calib_ecorsi', 3.0, isInt: true);
    final double palaceScore = _getRollingMedian(prefs, 'history_palace', 'calib_palace', 2.0, isInt: true);
    final double dnbRawScore = getDnbMedian(); 

    // --- 1. DETEKCE ZDROJE DAT (Kalibrace vs. Trénink) ---
    bool isStroopCalib = (prefs.getStringList('history_stroop') ?? []).isEmpty;
    bool isDigitCalib = (prefs.getStringList('history_digit_span') ?? []).isEmpty;
    bool isCorsiCalib = (prefs.getStringList('history_ecorsi') ?? []).isEmpty;
    bool isPalaceCalib = (prefs.getStringList('history_palace') ?? []).isEmpty;
    bool isDnbCalib = (prefs.getStringList('dnb_history') ?? []).isEmpty;

    // --- 2. ODDĚLENÁ NORMALIZACE (Škála 0 - 300) ---
    // Parametry _calcKci: (Aktuální_Hodnota, Absolutní_Minimum, Výchozí_Průměr_Populace, Strop_Trénovaného_Jedince)
    
    // Stroop: Průměr = 1000 ms, Minimum = 2000 ms, Strop = 600 ms
    double baseStroop = _calcKci(stroopTime, 2000.0, 1000.0, 600.0, reverse: true);
    if (isStroopCalib) baseStroop = baseStroop.clamp(0.0, 120.0);

    // Digit Span: Průměr = 5.5, Minimum = 3.0, Strop = 9.0
    double baseDigit = _calcKci(digitSpan, 3.0, 5.5, 9.0);
    if (isDigitCalib) baseDigit = baseDigit.clamp(0.0, 120.0);

    // eCorsi: Průměr = 4.5, Minimum = 2.0, Strop = 8.0
    double baseCorsi = _calcKci(eCorsiSpan, 2.0, 4.5, 8.0);
    if (isCorsiCalib) baseCorsi = baseCorsi.clamp(0.0, 120.0);

    // Memory Palace: Průměr = 2.5, Minimum = 0.0, Strop = 10.0
    double basePalace = _calcKci(palaceScore, 0.0, 2.5, 10.0);
    if (isPalaceCalib) basePalace = basePalace.clamp(0.0, 120.0);

    // Dual N-Back: Průměr = úroveň 2.0, Minimum = 1.0, Strop = 4.0
    double baseDnb = _calcKci(dnbRawScore, 1.0, 2.0, 4.0);
    if (isDnbCalib) baseDnb = baseDnb.clamp(0.0, 120.0);

    // Načtení validity (počty odehraných dní pro danou doménu)
    int vDnb = prefs.getInt('validity_working_memory') ?? (prefs.getStringList('dnb_daily_history')?.length ?? 0);
    int vStroop = prefs.getInt('validity_inhibition') ?? (prefs.getStringList('stroop_daily_history')?.length ?? 0);
    int vDigit = prefs.getInt('validity_digit_span') ?? (prefs.getStringList('ds_daily_history')?.length ?? 0);
    int vCorsi = prefs.getInt('validity_visuospatial') ?? (prefs.getStringList('ecorsi_daily_history')?.length ?? 0);
    int vPalace = prefs.getInt('validity_associative') ?? (prefs.getStringList('palace_daily_history')?.length ?? 0);

    if (!mounted) return;

    setState(() {
      // Skórování KCI profilu (sloučení subtestů s váhami)
      _scoreWorkingMemory = (baseDnb * 0.60) + (baseDigit * 0.40);
      _scoreVisuospatial = (baseCorsi * 0.80) + (baseDnb * 0.20);
      _scoreExecutive = (baseStroop * 0.70) + (baseDnb * 0.30);
      _scoreAssociative = basePalace;
      _scoreAttention = (baseStroop * 0.50) + (baseDnb * 0.50);

      // Dynamické měřítko pavučinového grafu
      double maxScore = [_scoreWorkingMemory, _scoreVisuospatial, _scoreExecutive, _scoreAssociative, _scoreAttention].reduce(math.max);
      _chartScale = math.max(100.0, ((maxScore / 10).ceil() * 10).toDouble());

      // Zápis validity pro zelené štítky
      _valWorkingMemory = math.min(vDnb, vDigit).clamp(0, 10);
      _valVisuospatial = math.min(vCorsi, vDnb).clamp(0, 10);
      _valExecutive = math.min(vStroop, vDnb).clamp(0, 10);
      _valAssociative = vPalace.clamp(0, 10);
      _valAttention = math.min(vStroop, vDnb).clamp(0, 10);

      _isLoading = false;
    });
  }

  Future<void> _resetCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('history_') || 
          key.endsWith('_daily_history') || 
          key.startsWith('validity_') || 
          key.startsWith('calib_') || 
          key == 'dnb_history') {
        await prefs.remove(key);
      }
    }

    await prefs.setBool('global_is_calibrated', false);
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainMenuScreen()), 
        (Route<dynamic> route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final Color bgBottom = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
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
                            _buildCustomRadarChart(isDark, accent),
                            const SizedBox(height: 40),
                            _buildStatRows(context, isDark, accent),
                            const SizedBox(height: 30),
                            
                            // Samostatné tlačítko pro reset profilu uprostřed
                            Center(
                              child: OutlinedButton.icon(
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
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                (Route<dynamic> route) => false,
              );
            },
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

  Widget _buildCustomRadarChart(bool isDark, Color accent) {
    return Container(
      height: 380,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E).withAlpha(150) : Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white12 : accent.withAlpha(20), width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(color: accent.withAlpha(15), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return CustomPaint(
            painter: RadarChartPainter(
              values: [
                _scoreWorkingMemory * progress,
                _scoreVisuospatial * progress,
                _scoreExecutive * progress,
                _scoreAssociative * progress,
                _scoreAttention * progress,
              ],
              maxScale: _chartScale, 
              labels: [
                'profile_wm'.tr().replaceAll('\\n', '\n'),
                'profile_vs'.tr().replaceAll('\\n', '\n'),
                'profile_exe'.tr().replaceAll('\\n', '\n'),
                'profile_asc'.tr().replaceAll('\\n', '\n'),
                'profile_att'.tr().replaceAll('\\n', '\n'),
              ],
              accent: accent,
              isDark: isDark,
            ),
          );
        },
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
          _statRow(context, 'profile_stat_wm'.tr(), 'wm', _scoreWorkingMemory, _valWorkingMemory, isDark, accent),
          _statRow(context, 'profile_stat_vs'.tr(), 'vs', _scoreVisuospatial, _valVisuospatial, isDark, accent),
          _statRow(context, 'profile_stat_exe'.tr(), 'exe', _scoreExecutive, _valExecutive, isDark, accent),
          _statRow(context, 'profile_stat_asc'.tr(), 'asc', _scoreAssociative, _valAssociative, isDark, accent),
          _statRow(context, 'profile_stat_att'.tr(), 'att', _scoreAttention, _valAttention, isDark, accent),
        ],
      ),
    );
  }

  void _showDomainInfoDialog(BuildContext context, String title, String domainKey, Color accent, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.psychology_rounded, color: accent),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection('profile_info_hdr_desc'.tr(), 'profile_info_${domainKey}_desc'.tr(), Icons.info_outline_rounded, accent, isDark),
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
                  child: Text('global_btn_close'.tr(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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

  Widget _statRow(BuildContext context, String label, String domainKey, double score, int validity, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          const SizedBox(width: 12),
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

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxScale;
  final List<String> labels;
  final Color accent;
  final bool isDark;

  RadarChartPainter({
    required this.values,
    required this.maxScale,
    required this.labels,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 40; 
    
    final Paint gridPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint refPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final double radius100 = radius * (100 / maxScale);
    canvas.drawCircle(center, radius100, refPaint);
    
    if (maxScale > 100.0) {
      canvas.drawCircle(center, radius, gridPaint);
    }

    final double angleStep = (2 * math.pi) / values.length;
    const double startAngle = -math.pi / 2; 

    for (int i = 0; i < values.length; i++) {
      final double angle = startAngle + i * angleStep;
      final Offset edgePoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      canvas.drawLine(center, edgePoint, gridPaint);

      final Offset textOffset = Offset(
        center.dx + (radius + 20) * math.cos(angle),
        center.dy + (radius + 20) * math.sin(angle),
      );

      final TextSpan span = TextSpan(
        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
        text: labels[i],
      );
      
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr, 
      );
      
      tp.layout();
      tp.paint(canvas, Offset(textOffset.dx - tp.width / 2, textOffset.dy - tp.height / 2));
    }

    final Path dataPath = Path();
    final Paint dataFillPaint = Paint()
      ..color = accent.withAlpha(60)
      ..style = PaintingStyle.fill;
    
    final Paint dataStrokePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Paint dotPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    List<Offset> points = [];

    for (int i = 0; i < values.length; i++) {
      final double angle = startAngle + i * angleStep;
      final double safeValue = values[i].clamp(0.0, maxScale); 
      final double pointRadius = radius * (safeValue / maxScale);
      
      final Offset point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );
      
      points.add(point);

      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataFillPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    for (var point in points) {
      canvas.drawCircle(point, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return oldDelegate.maxScale != maxScale || oldDelegate.values != values;
  }
}
