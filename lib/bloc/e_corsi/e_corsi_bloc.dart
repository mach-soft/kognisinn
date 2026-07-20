import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:kognisinn/env.dart';


// --- STAVY (STATE) ---
enum ECorsiPhase { menu, showing, input, success, failure, result, history }
enum ECorsiMode { forward, reverse }

class ECorsiHistoryItem {
  final DateTime date;
  final ECorsiMode mode;
  final int maxSpan; 
  final int score; 

  ECorsiHistoryItem(this.date, this.mode, this.maxSpan, this.score);

  String toRawString() => '${date.millisecondsSinceEpoch}|${mode.index}|$maxSpan|$score';
  
  static ECorsiHistoryItem fromRawString(String raw) {
    final parts = raw.split('|');
    return ECorsiHistoryItem(
      DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      ECorsiMode.values[int.parse(parts[1])],
      int.parse(parts[2]),
      int.parse(parts[3]),
    );
  }
}

class ECorsiState {
  final ECorsiPhase phase;
  final ECorsiMode mode;
  final int currentSpan;
  final List<int> sequence;
  final List<int> userInputs;
  final int activeBlockIndex; 
  final int score;
  final int lives;
  final List<ECorsiHistoryItem> history;

  const ECorsiState({
    this.phase = ECorsiPhase.menu,
    this.mode = ECorsiMode.forward,
    this.currentSpan = 3,
    this.sequence = const [],
    this.userInputs = const [],
    this.activeBlockIndex = -1,
    this.score = 0,
    this.lives = 3,
    this.history = const [],
  });

  ECorsiState copyWith({
    ECorsiPhase? phase, ECorsiMode? mode, int? currentSpan,
    List<int>? sequence, List<int>? userInputs, int? activeBlockIndex,
    int? score, int? lives, List<ECorsiHistoryItem>? history,
  }) {
    return ECorsiState(
      phase: phase ?? this.phase, mode: mode ?? this.mode, currentSpan: currentSpan ?? this.currentSpan,
      sequence: sequence ?? this.sequence, userInputs: userInputs ?? this.userInputs,
      activeBlockIndex: activeBlockIndex ?? this.activeBlockIndex, score: score ?? this.score,
      lives: lives ?? this.lives, history: history ?? this.history,
    );
  }
}

// --- UDÁLOSTI (EVENTS) ---
abstract class ECorsiEvent {}
class StartECorsi extends ECorsiEvent { final ECorsiMode mode; StartECorsi(this.mode); }
class BlockTapped extends ECorsiEvent { final int blockIndex; BlockTapped(this.blockIndex); }
class NextRound extends ECorsiEvent {}
class ResetECorsi extends ECorsiEvent {}
class ShowECorsiHistory extends ECorsiEvent {}

// --- MOZEK (BLOC) ---
class ECorsiBloc extends Bloc<ECorsiEvent, ECorsiState> {
  final Random _random = Random();
  SharedPreferences? _prefs;
  int _roundId = 0; // Ochrana proti překrývání asynchronních smyček
    // --- JEDINÝ ZDROJ PRAVDY PRO KCI (s modifikátory) ---
  static int calculateKci(double span, ECorsiMode mode) {
    if (span <= 0 || span.isNaN || span.isInfinite) return 0;
    
    // Zpětný chod (reverse) je kognitivně náročnější
    double modifier = (mode == ECorsiMode.reverse) ? 1.35 : 1.0;
    double val = span * modifier;

    double worst = 2.0;     // Bez tréninku
    double baseline = 4.5;  // Průměrná kapacita (100 KCI)
    double trained = 8.0;   // Mistr (200 KCI)

    double score = 0;
    if (val <= baseline) {
      score = (((val - worst) / (baseline - worst)) * 100.0);
    } else {
      score = 100.0 + (((val - baseline) / (trained - baseline)) * 100.0);
    }
    
    return score.round().clamp(0, 250);
  }

  ECorsiBloc() : super(const ECorsiState()) {
    _initPrefs();
    on<StartECorsi>(_onStart);
    on<BlockTapped>(_onBlockTapped);
    on<NextRound>(_onNextRound);
    on<ResetECorsi>(_onReset);
    on<ShowECorsiHistory>((event, emit) => emit(state.copyWith(phase: ECorsiPhase.history)));
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    add(ResetECorsi());
  }

  void _onReset(ResetECorsi event, Emitter<ECorsiState> emit) {
    _roundId++; // Zruší probíhající vykreslování sekvence
    final rawHistory = _prefs?.getStringList('ecorsi_history') ?? [];
    final history = rawHistory.map((s) => ECorsiHistoryItem.fromRawString(s)).toList();
    emit(state.copyWith(phase: ECorsiPhase.menu, history: history, score: 0, currentSpan: 3, lives: 3));
  }

  void _onStart(StartECorsi event, Emitter<ECorsiState> emit) {
    emit(state.copyWith(mode: event.mode, score: 0, currentSpan: 3, lives: 3));
    add(NextRound());
  }

    Future<void> _onNextRound(NextRound event, Emitter<ECorsiState> emit) async {
    _roundId++;
    final currentRoundId = _roundId;

    List<int> newSeq = [];
    int lastBlock = -1;
    for (int i = 0; i < state.currentSpan; i++) {
      int nextBlock;
      do { nextBlock = _random.nextInt(9); } while (nextBlock == lastBlock);
      newSeq.add(nextBlock);
      lastBlock = nextBlock;
    }

    emit(state.copyWith(phase: ECorsiPhase.showing, sequence: newSeq, userInputs: [], activeBlockIndex: -1));

    await Future.delayed(const Duration(seconds: 1));
    if (currentRoundId != _roundId) return; 

    for (int i = 0; i < newSeq.length; i++) {
      SystemSound.play(SystemSoundType.click);
      emit(state.copyWith(activeBlockIndex: newSeq[i]));

      await Future.delayed(const Duration(milliseconds: 500));
      if (currentRoundId != _roundId) return;

      emit(state.copyWith(activeBlockIndex: -1));

      await Future.delayed(const Duration(milliseconds: 500));
      if (currentRoundId != _roundId) return;
    }

    // --- OPRAVA HAPTIKY PRO WINDOWS ---
    if (Env.useHaptics) HapticFeedback.lightImpact();
    emit(state.copyWith(phase: ECorsiPhase.input, activeBlockIndex: -1));
  }

  Future<void> _onBlockTapped(BlockTapped event, Emitter<ECorsiState> emit) async {
    if (state.phase != ECorsiPhase.input) return;

    SystemSound.play(SystemSoundType.click);
    final newInputs = List<int>.from(state.userInputs)..add(event.blockIndex);
    
    int currentIndex = newInputs.length - 1;
    int expectedBlock = state.mode == ECorsiMode.forward 
        ? state.sequence[currentIndex] 
        : state.sequence[state.sequence.length - 1 - currentIndex];

    if (event.blockIndex != expectedBlock) {
      // --- OPRAVA HAPTIKY PRO WINDOWS ---
      if (Env.useHaptics) {
        final prefs = await SharedPreferences.getInstance();
        bool isHaptic = prefs.getBool('global_is_haptic') ?? true;
        if (isHaptic) {
          int hDuration = prefs.getInt('global_haptic_duration') ?? 500;
          Vibration.vibrate(duration: hDuration);
        }
      }
      
      emit(state.copyWith(activeBlockIndex: event.blockIndex));

      await Future.delayed(const Duration(milliseconds: 500));
      if (state.phase != ECorsiPhase.input) return;

      int newLives = state.lives - 1;
      
      if (newLives <= 0) {
        final newItem = ECorsiHistoryItem(DateTime.now(), state.mode, state.currentSpan, state.score);
        final newHistory = List<ECorsiHistoryItem>.from(state.history)..add(newItem);
        _prefs?.setStringList('ecorsi_history', newHistory.map((e) => e.toRawString()).toList());
        
        if (_prefs != null) {
          final nowStr = DateTime.now().toIso8601String();
          final exportKci = calculateKci(state.currentSpan.toDouble(), state.mode).toDouble();
          
          List<String> historyKCI = _prefs!.getStringList('history_ecorsi') ?? [];
          historyKCI.add(exportKci.toString());
          if (historyKCI.length > 50) historyKCI.removeAt(0);
          _prefs!.setStringList('history_ecorsi', historyKCI);
          
          final today = nowStr.substring(0, 10);
          List<String> dailyRaw = _prefs!.getStringList('ecorsi_daily_history') ?? [];
          Map<String, double> dailyMap = {};
          
          for (String entry in dailyRaw) {
            final parts = entry.split('|');
            if (parts.length == 2) dailyMap[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
          }
          
          if (dailyMap.containsKey(today)) {
            if (exportKci > dailyMap[today]!) dailyMap[today] = exportKci;
          } else {
            dailyMap[today] = exportKci;
          }
          
          var sortedKeys = dailyMap.keys.toList()..sort();
          if (sortedKeys.length > 10) sortedKeys = sortedKeys.sublist(sortedKeys.length - 10);
          
          _prefs!.setStringList('ecorsi_daily_history', sortedKeys.map((k) => '$k|${dailyMap[k]}').toList());
          _prefs!.setInt('validity_visuospatial', sortedKeys.length);
        }

        emit(state.copyWith(phase: ECorsiPhase.result, history: newHistory, activeBlockIndex: -1));
      } else {
        emit(state.copyWith(phase: ECorsiPhase.failure, lives: newLives, activeBlockIndex: -1));
      }
    } else {
      emit(state.copyWith(userInputs: newInputs, score: state.score + 1));
      if (newInputs.length == state.sequence.length) {
        emit(state.copyWith(phase: ECorsiPhase.success, currentSpan: state.currentSpan + 1));
      }
    }
  }

}

