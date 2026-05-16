import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/calibration/calibration_bloc.dart';
import '../../bloc/calibration/calibration_event.dart';
import '../../bloc/calibration/calibration_state.dart';
import '../main_menu_screen.dart'; 

// OPRAVA 1: Přidán bgColor pro výrazné podbarvení tlačítek (DNB)
Widget _buildSharedBtn(String label, VoidCallback onTap, bool isDark, Color accent, {double width = 320, bool isPrimary = false, IconData? icon, Color? bgColor}) {
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
            color: bgColor, // Celoplošné podbarvení, pokud je nastaveno
            gradient: bgColor == null ? LinearGradient(colors: isDark ? [const Color(0xFF23253A), const Color(0xFF161828)] : [Colors.white, const Color(0xFFF1F5F9)]) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? accent.withAlpha(40) : accent.withAlpha(30), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: isDark ? Colors.white : const Color(0xFF1E293B)), const SizedBox(width: 12)],
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: 1.5)))),
            ],
          ),
        ),
      ),
    ),
  );
}

class CalibrationScreen extends StatelessWidget {
  const CalibrationScreen({super.key});

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
      create: (context) => CalibrationBloc(),
      child: BlocBuilder<CalibrationBloc, CalibrationState>(
        builder: (context, state) {
          // ignore: deprecated_member_use
          return WillPopScope(
            onWillPop: () async {
              if (state.phase == CalibrationPhase.result) return false;
              return await _showInterruptDialog(context, isDark);
            },
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [bgTop, bgBottom])),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(isDark),
                      Expanded(child: _buildPhase(context, state, isDark)),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_rounded, color: Colors.white, size: 36),
              SizedBox(width: 12),
              Text('KOGNIX', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhase(BuildContext context, CalibrationState state, bool isDark) {
    switch (state.phase) {
      case CalibrationPhase.intro: return _IntroPhase(isDark: isDark);
      case CalibrationPhase.stroop: return _StroopMicroTest(isDark: isDark);
      case CalibrationPhase.digitSpan: return _DigitSpanMicroTest(isDark: isDark);
      case CalibrationPhase.eCorsi: return _ECorsiMicroTest(isDark: isDark);
      case CalibrationPhase.memoryPalace: return _PalaceMicroTest(isDark: isDark);
      case CalibrationPhase.dnb: return _DNBMicroTest(isDark: isDark);
      case CalibrationPhase.result: return _ResultPhase(isDark: isDark);
    }
  }
}

// ============================================================================
// STROOP
// ============================================================================
class _StroopMicroTest extends StatefulWidget {
  final bool isDark;
  const _StroopMicroTest({required this.isDark});
  @override
  State<_StroopMicroTest> createState() => _StroopMicroTestState();
}

class _StroopMicroTestState extends State<_StroopMicroTest> {
  final Random _rnd = Random();
  int _rounds = 0;
  final int _maxRounds = 15;
  DateTime? _shownTime;
  final List<int> _reactionTimes = [];
  bool _isLocked = false; 
  
  final List<String> _wordKeys = ['ČERVENÁ', 'MODRÁ', 'ZELENÁ', 'ŽLUTÁ'];
  final List<Color> _colors = [const Color(0xFFFF5252), const Color(0xFF448AFF), const Color(0xFF69F0AE), const Color(0xFFFFD740)];
  
  late String _currentKey;
  late Color _currentColor;

  @override
  void initState() { super.initState(); _nextRound(); }

  void _nextRound() {
    _currentKey = _wordKeys[_rnd.nextInt(_wordKeys.length)];
    _currentColor = _colors[_rnd.nextInt(_colors.length)];
    _shownTime = DateTime.now();
    if (mounted) setState(() {});
  }

  void _handleTap(Color tappedColor) async {
    if (_isLocked) return;
    if (_shownTime != null) {
      _reactionTimes.add(DateTime.now().difference(_shownTime!).inMilliseconds);
    }
    _rounds++;
    if (_rounds >= _maxRounds) {
      setState(() => _isLocked = true);
      double avg = _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('calib_stroop', avg);
      
      if (mounted) context.read<CalibrationBloc>().add(SubmitStroopResult(avg));
    } else {
      _nextRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('calib_phase_1'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('calib_stroop_desc'.tr(), style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black54)),
        const Spacer(),
        Text(_currentKey.tr(), style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: _currentColor)),
        const Spacer(),
        SizedBox(
          width: 280,
          child: Wrap(
            spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
            children: List.generate(_colors.length, (i) => GestureDetector(
              onTap: () => _handleTap(_colors[i]),
              child: Container(
                width: 120, height: 100, 
                decoration: BoxDecoration(color: _colors[i].withAlpha(200), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _colors[i].withAlpha(100), blurRadius: 15)]),
                alignment: Alignment.center,
                child: Text(_wordKeys[i].tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

// ============================================================================
// DIGIT SPAN (Oprava klávesnice a vizualizace posledního vstupu)
// ============================================================================
class _DigitSpanMicroTest extends StatefulWidget {
  final bool isDark;
  const _DigitSpanMicroTest({required this.isDark});
  @override
  State<_DigitSpanMicroTest> createState() => _DigitSpanMicroTestState();
}

class _DigitSpanMicroTestState extends State<_DigitSpanMicroTest> {
  final FlutterTts _tts = FlutterTts();
  int _span = 4;
  List<int> _seq = [];
  List<int> _input = [];
  bool _isInputPhase = false;
  String _displayChar = '';
  Timer? _timer;
  bool _isTtsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { _initTts(); });
  }

  Future<void> _initTts() async {
    try {
      String lang = context.locale.languageCode;
      await _tts.setLanguage(lang == 'en' ? "en-US" : (lang == 'de' ? "de-DE" : "cs-CZ"));
      await _tts.setSpeechRate(0.5);
    } catch (e) { debugPrint("TTS Error: $e"); }
    if (mounted) { setState(() => _isTtsReady = true); _startSequence(); }
  }

  void _startSequence() {
    if (!mounted) return;
    _seq = List.generate(_span, (_) => Random().nextInt(9) + 1);
    _input = [];
    _isInputPhase = false;
    int tick = 0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (t) {
      if (!mounted) { t.cancel(); return; }
      if (tick >= _seq.length) {
        t.cancel();
        setState(() { _isInputPhase = true; _displayChar = ''; });
      } else {
        String digit = _seq[tick].toString();
        setState(() => _displayChar = digit);
        _tts.speak(digit); 
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _displayChar = '');
        });
        tick++;
      }
    });
  }

  void _handleInput(int num) async {
    if (!_isInputPhase) return;
    setState(() => _input.add(num));
    
    // Vyhodnocujeme AŽ když hráč zadá celou požadovanou délku
    if (_input.length == _seq.length) {
      setState(() => _isInputPhase = false); // Zámek proti dalším klikům
      
      // PAUZA: Necháme hráče prohlédnout si celou zadanou řadu (včetně posledního čísla)
      await Future.delayed(const Duration(milliseconds: 600));

      bool isCorrect = true;
      for (int i = 0; i < _seq.length; i++) {
        if (_input[i] != _seq[i]) isCorrect = false;
      }

      if (isCorrect) {
        _span++;
        _startSequence();
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('calib_digit_span', _span - 1);
        if (mounted) context.read<CalibrationBloc>().add(SubmitDigitSpanResult(_span - 1));
      }
    }
  }

  void _handleBackspace() {
    if (!_isInputPhase || _input.isEmpty) return;
    setState(() => _input.removeLast());
  }

  Widget _buildKeypadBtn(String label, VoidCallback onTap, Color accent, {bool isAccent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 60, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF23253A) : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: accent.withAlpha(isAccent ? 100 : 40))
        ),
        child: Text(label, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isAccent ? accent : (widget.isDark ? Colors.white : Colors.black))),
      ),
    );
  }

  @override
  void dispose() { _timer?.cancel(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    if (!_isTtsReady) return Center(child: CircularProgressIndicator(color: accent));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('calib_phase_2'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('calib_digit_desc'.tr(), style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black54)),
        const Spacer(),
        
        if (!_isInputPhase) Text(_displayChar, style: TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: widget.isDark ? Colors.white : Colors.black)),
        if (_isInputPhase) Text(_input.join(' '), style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: accent, letterSpacing: 10)),
        
        const Spacer(),
        if (_isInputPhase)
          SizedBox(
            width: 300,
            child: Wrap(
              spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: [
                ...List.generate(9, (i) => _buildKeypadBtn('${i + 1}', () => _handleInput(i + 1), accent)),
                // 10. Tlačítko - Krok zpět
                _buildKeypadBtn('⌫', _handleBackspace, accent, isAccent: true),
              ],
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ============================================================================
// MEMORY PALACE
// ============================================================================
// ============================================================================
// MEMORY PALACE (Skutečný test asociativní paměti - Paired Associates Learning)
// ============================================================================
class _PalaceMicroTest extends StatefulWidget {
  final bool isDark;
  const _PalaceMicroTest({required this.isDark});
  @override
  State<_PalaceMicroTest> createState() => _PalaceMicroTestState();
}

class _PalaceMicroTestState extends State<_PalaceMicroTest> {
  // Vědecké PAL (Paired Associates Learning) paradigma
  // Používáme emotikony jako univerzální vizuální podněty bez jazykové bariéry
  final List<Map<String, String>> _pairs = [
    {'cue': '🐶', 'target': '🍕'}, // Pes - Pizza
    {'cue': '🚗', 'target': '🍎'}, // Auto - Jablko
    {'cue': '🎸', 'target': '🌲'}, // Kytara - Strom
    {'cue': '🏠', 'target': '☀️'}, // Dům - Slunce
    {'cue': '📚', 'target': '☕'}, // Kniha - Káva
  ];
  
  late List<Map<String, String>> _encodingOrder;
  late List<Map<String, String>> _recallOrder;
  final List<String> _allTargets = ['🍕', '🍎', '🌲', '☀️', '☕'];
  
  int _idx = -1;
  bool _isRecall = false;
  int _score = 0;
  Timer? _timer;
  bool _isLocked = false;

  @override
  void initState() { 
    super.initState(); 
    // Nezávislé zamíchání pro fázi učení a testování zabrání spoléhání na sekvenční paměť
    _encodingOrder = List.from(_pairs)..shuffle();
    _recallOrder = List.from(_pairs)..shuffle();
    _startEncoding(); 
  }

  void _startEncoding() {
    _idx = 0;
    // Kratší čas zobrazení (2.5 sekundy) pro vyšší kognitivní zátěž
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (t) {
      if (!mounted) return;
      setState(() { _idx++; });
      if (_idx >= _encodingOrder.length) {
        t.cancel();
        setState(() { _isRecall = true; _idx = 0; });
      }
    });
  }

  void _handleAnswer(String target) async {
    if (_isLocked) return;
    
    // Zkontolujeme, zda vybraný cíl odpovídá správnému cíli pro aktuální cue
    if (target == _recallOrder[_idx]['target']) {
      _score++;
    }
    
    setState(() { _idx++; });
    
    if (_idx >= _recallOrder.length) {
      setState(() => _isLocked = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calib_palace', _score);
      
      if (mounted) context.read<CalibrationBloc>().add(SubmitMemoryPalaceResult(_score));
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('calib_phase_4'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('calib_palace_desc'.tr(), style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black54)),
        const Spacer(),
        
        // FÁZE 1: UČENÍ ASOCIACÍ (Párování)
        if (!_isRecall && _idx >= 0 && _idx < _encodingOrder.length) ...[
          Text('calib_palace_learn'.tr(), style: TextStyle(fontSize: 18, color: widget.isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_encodingOrder[_idx]['cue']!, style: const TextStyle(fontSize: 80)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.link_rounded, color: accent, size: 40),
              ),
              Text(_encodingOrder[_idx]['target']!, style: const TextStyle(fontSize: 80)),
            ],
          ),
        ] 
        // FÁZE 2: VYBAVOVÁNÍ (Testování vazeb)
        else if (_isRecall && _idx < _recallOrder.length) ...[
          Text('calib_palace_test'.tr(), style: TextStyle(fontSize: 18, color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Text(_recallOrder[_idx]['cue']!, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 50),
          Wrap(
            spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
            // Zamícháme možnosti odpovědí, aby svalová paměť nehrála roli
            children: (_allTargets.toList()..shuffle()).map((t) => GestureDetector(
              onTap: () => _handleAnswer(t),
              child: Container(
                width: 80, height: 80, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF23253A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withAlpha(40), width: 2),
                ),
                child: Text(t, style: const TextStyle(fontSize: 40)),
              ),
            )).toList(),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}


// ============================================================================
// DUAL N-BACK (Oprava na Dual 2-Back + Výrazné UI)
// ============================================================================
class _DNBMicroTest extends StatefulWidget {
  final bool isDark;
  const _DNBMicroTest({required this.isDark});
  @override
  State<_DNBMicroTest> createState() => _DNBMicroTestState();
}

class _DNBMicroTestState extends State<_DNBMicroTest> {
  final FlutterTts _tts = FlutterTts();
  final List<String> _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
  
  final List<int> _posHist = [];
  final List<int> _audHist = [];
  
  int _round = 0;
  final int _maxRounds = 15; // Prodlouženo pro N=2

  int _totalScore = 100;
  int _activePos = -1;
  Timer? _timer;
  bool _isReady = false;

  int _posBtnState = 0; 
  int _audBtnState = 0;

  bool _hasClickedPosThisRound = false;
  bool _hasClickedAudThisRound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { _initAndStart(); });
  }

  Future<void> _initAndStart() async {
    try {
      String lang = context.locale.languageCode;
      await _tts.setLanguage(lang == 'en' ? "en-US" : (lang == 'de' ? "de-DE" : "cs-CZ"));
      await _tts.setSpeechRate(0.5);
    } catch (e) { debugPrint("TTS Error: $e"); }
    if (mounted) { setState(() => _isReady = true); _nextRound(); }
  }

  void _nextRound() {
    if (!mounted) return;

    // 1. Zkontrolujeme zmeškanou shodu pro N=2 (porovnání předchozího s tím o 2 dříve)
    if (_round >= 3) {
      bool wasPosMatch = _posHist[_round - 1] == _posHist[_round - 3];
      bool wasAudMatch = _audHist[_round - 1] == _audHist[_round - 3];

      if (wasPosMatch && !_hasClickedPosThisRound) _totalScore -= 10;
      if (wasAudMatch && !_hasClickedAudThisRound) _totalScore -= 10;
    }

    if (_round >= _maxRounds) {
      _finishTest();
      return;
    }

    // 2. Příprava nového kola
    _hasClickedPosThisRound = false;
    _hasClickedAudThisRound = false;
    _posBtnState = 0;
    _audBtnState = 0;

    int p; 
    int a;

    if (_round >= 2) {
      // 30% šance vygenerovat cílovou shodu s před-předchozím tahům (N=2)
      if (Random().nextDouble() < 0.3) { 
        p = _posHist[_posHist.length - 2]; 
      } else { 
        p = Random().nextInt(9); 
        while (p == _posHist[_posHist.length - 2]) { p = Random().nextInt(9); } 
      }
      
      if (Random().nextDouble() < 0.3) { 
        a = _audHist[_audHist.length - 2]; 
      } else { 
        a = Random().nextInt(9); 
        while (a == _audHist[_audHist.length - 2]) { a = Random().nextInt(9); } 
      }
    } else {
      p = Random().nextInt(9); 
      a = Random().nextInt(9);
    }

    _posHist.add(p); 
    _audHist.add(a);
    
    if (mounted) setState(() => _activePos = p);
    _tts.speak(_letters[a]);

    _round++;
    _timer = Timer(const Duration(milliseconds: 2500), _nextRound);
  }

  void _handlePosClick() {
    // Pro N=2 musí být kolo aspoň 3. v pořadí (indexy 0, 1 jsou bez shody)
    if (_round <= 2 || _hasClickedPosThisRound) return;
    
    _hasClickedPosThisRound = true;

    // Shoda = porovnání aktuálního (.last) s prvkem o 2 kroky zpět (.length - 3)
    bool isMatch = _posHist.last == _posHist[_posHist.length - 3];
    
    setState(() {
      if (isMatch) {
        _posBtnState = 1; 
      } else {
        _posBtnState = 2; 
        _totalScore -= 10; 
      }
    });
  }

  void _handleAudClick() {
    if (_round <= 2 || _hasClickedAudThisRound) return;
    
    _hasClickedAudThisRound = true;

    bool isMatch = _audHist.last == _audHist[_audHist.length - 3];
    
    setState(() {
      if (isMatch) {
        _audBtnState = 1; 
      } else {
        _audBtnState = 2; 
        _totalScore -= 10; 
      }
    });
  }

  void _finishTest() async {
    double finalRate = (_totalScore / 100.0).clamp(0.0, 1.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('calib_dnb', finalRate);
    
    if (mounted) context.read<CalibrationBloc>().add(SubmitDnbResult(finalRate));
  }

  @override
  void dispose() { _timer?.cancel(); _tts.stop(); super.dispose(); }

  // Pomocník pro BARVU OBRAZU TLAČÍTKA
  Color _getBtnColor(int state, Color accent) {
    if (state == 1) return Colors.greenAccent;
    if (state == 2) return Colors.redAccent;
    return Colors.grey.withAlpha(100);
  }

  // Pomocník pro CELOPLOŠNÉ PODBARVENÍ
  Color? _getBtnBgColor(int state) {
    if (state == 1) return Colors.greenAccent.withAlpha(120);
    if (state == 2) return Colors.redAccent.withAlpha(120);
    return null; // Zůstane výchozí gradient
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    if (!_isReady) return Center(child: CircularProgressIndicator(color: accent));
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('calib_phase_5'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('calib_dnb_desc'.tr(), style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black54)),
        const Spacer(),
        
        Container(
          width: 280, height: 280, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: widget.isDark ? Colors.white.withAlpha(5) : accent.withAlpha(10), borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.isDark ? Colors.white12 : accent.withAlpha(20))),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: 9,
            itemBuilder: (context, index) {
              bool isActive = _activePos == index;
              return AnimatedContainer(duration: const Duration(milliseconds: 150), decoration: BoxDecoration(color: isActive ? accent : (widget.isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)), borderRadius: BorderRadius.circular(12)));
            },
          ),
        ),
        const Spacer(),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSharedBtn('dnb_btn_position'.tr(), _handlePosClick, widget.isDark, _getBtnColor(_posBtnState, accent), bgColor: _getBtnBgColor(_posBtnState), width: 140),
            _buildSharedBtn('dnb_btn_audio'.tr(), _handleAudClick, widget.isDark, _getBtnColor(_audBtnState, accent), bgColor: _getBtnBgColor(_audBtnState), width: 140),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ============================================================================
// INTRO & RESULT PHASE
// ============================================================================
class _IntroPhase extends StatelessWidget {
  final bool isDark;
  const _IntroPhase({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_rounded, size: 80, color: accent),
          const SizedBox(height: 30),
          Text('calib_intro_title'.tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: 2)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('calib_intro_desc'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
          ),
          const SizedBox(height: 50),
          _buildSharedBtn('calib_btn_next'.tr(), () => context.read<CalibrationBloc>().add(StartCalibration()), isDark, accent, isPrimary: true, icon: Icons.play_arrow_rounded),
        ],
      ),
    );
  }
}

class _ResultPhase extends StatelessWidget {
  final bool isDark;
  const _ResultPhase({required this.isDark});
  
  @override
  Widget build(BuildContext context) {
    final Color accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_rounded, size: 80, color: accent),
          const SizedBox(height: 30),
          Text('calib_done_title'.tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E293B), letterSpacing: 2)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('calib_done_desc'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.5)),
          ),
          const SizedBox(height: 50),
          
          _buildSharedBtn('calib_btn_finish'.tr(), () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(child: CircularProgressIndicator(color: accent)),
            );
            
            final navigator = Navigator.of(context);
            context.read<CalibrationBloc>().add(FinishCalibration());
            await Future.delayed(const Duration(milliseconds: 250));
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('global_is_calibrated', true);
            
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainMenuScreen()),
              (route) => false
            );
          }, isDark, accent, isPrimary: true),
        ],
      ),
    );
  }
}

// ============================================================================
// FÁZE 3: eCORSI
// ============================================================================
class _ECorsiMicroTest extends StatefulWidget {
  final bool isDark;
  const _ECorsiMicroTest({required this.isDark});
  @override
  State<_ECorsiMicroTest> createState() => _ECorsiMicroTestState();
}

class _ECorsiMicroTestState extends State<_ECorsiMicroTest> {
  final List<Alignment> _pos = const [
    Alignment(-0.8, -0.8), Alignment(0.2, -0.9), Alignment(0.8, -0.6), 
    Alignment(-0.6, -0.2), Alignment(0.3, -0.1), Alignment(-0.9, 0.4), 
    Alignment(-0.1, 0.7), Alignment(0.6, 0.8), Alignment(0.9, 0.2)
  ];
  int _span = 3;
  List<int> _seq = [];
  List<int> _input = [];
  bool _isInputPhase = false;
  int _activeBlock = -1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  void _startSequence() {
    _seq = List.generate(_span, (_) => Random().nextInt(9));
    _input = [];
    _isInputPhase = false;
    int tick = 0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
      if (!mounted) { t.cancel(); return; }
      if (tick >= _seq.length) {
        t.cancel();
        setState(() { _isInputPhase = true; _activeBlock = -1; });
      } else {
        setState(() => _activeBlock = _seq[tick]);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _activeBlock = -1);
        });
        tick++;
      }
    });
  }

  void _handleTap(int index) async {
    if (!_isInputPhase) return;
    setState(() { _activeBlock = index; _input.add(index); });
    
    Future.delayed(const Duration(milliseconds: 200), () { 
      if (mounted) setState(() => _activeBlock = -1); 
    });

    if (_input.last != _seq[_input.length - 1]) {
      setState(() => _isInputPhase = false); 
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('calib_ecorsi', _span - 1);
      
      if (mounted) context.read<CalibrationBloc>().add(SubmitECorsiResult(_span - 1));
    } else if (_input.length == _seq.length) {
      setState(() => _isInputPhase = false); 
      _span++;
      Future.delayed(const Duration(milliseconds: 500), _startSequence);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isDark ? const Color(0xFF00E5FF) : const Color(0xFF7000FF);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('calib_phase_3'.tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accent, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('calib_corsi_desc'.tr(), style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black54)),
        const Spacer(),
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: widget.isDark ? Colors.white.withAlpha(5) : accent.withAlpha(10), borderRadius: BorderRadius.circular(24)),
            child: Stack(
              children: List.generate(9, (index) {
                bool isActive = _activeBlock == index;
                return Align(
                  alignment: _pos[index],
                  child: GestureDetector(
                    onTap: () => _handleTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: isActive ? accent : (widget.isDark ? Colors.white12 : Colors.black12), borderRadius: BorderRadius.circular(16)),
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
}
