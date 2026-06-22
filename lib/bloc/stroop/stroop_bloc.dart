import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'stroop_event.dart';
import 'stroop_state.dart';

class StroopBloc extends Bloc<StroopEvent, StroopState> {
  final Random _random = Random();
  final Stopwatch _stopwatch = Stopwatch();
  SharedPreferences? _prefs;

  final Map<String, Color> _colorMap = {
    'ČERVENÁ': Colors.red, 'MODRÁ': Colors.blue, 'ZELENÁ': Colors.green,
    'ŽLUTÁ': Colors.yellow, 'ORANŽOVÁ': Colors.orange, 'FIALOVÁ': Colors.purple,
  };

  StroopBloc() : super(const StroopState()) {
    _initPrefs();
    on<StartStroopGame>(_onStart);
    on<AnswerSelected>(_onSelect);
    on<ResetStroop>((event, emit) {
      final rawHistory = _prefs?.getStringList('stroop_history') ?? [];
      final history = rawHistory.map((s) => StroopHistoryItem.fromRawString(s)).toList();
      emit(state.copyWith(phase: StroopPhase.menu, history: history));
    });
    on<ShowStroopHistory>((event, emit) => emit(state.copyWith(phase: StroopPhase.history)));
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    add(ResetStroop());
  }

  void _onStart(StartStroopGame event, Emitter<StroopState> emit) {
    emit(state.copyWith(
      phase: StroopPhase.playing, activeGameType: event.gameType,
      score: 0, currentRound: 1, currentReactionTimesMs: [], totalRounds: 20,
    ));
    _generateTask(emit);
  }

  void _onSelect(AnswerSelected event, Emitter<StroopState> emit) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    
    bool isCorrect = event.answer == state.correctAnswer;

    // --- HAPTICKÁ ODEZVA PŘI CHYBĚ ---
    if (!isCorrect) {
      bool isHaptic = _prefs?.getBool('global_is_haptic') ?? true;
      if (isHaptic) {
        int hDuration = _prefs?.getInt('global_haptic_duration') ?? 500;
        Vibration.vibrate(duration: hDuration);
      }
    }
    // ---------------------------------

    int newScore = isCorrect ? state.score + 1 : state.score;
    List<int> newTimes = List.from(state.currentReactionTimesMs)..add(elapsed);

    if (state.currentRound >= state.totalRounds) {
      
      // === VĚDECKÁ FILTRACE OUTLIERŮ (2 SD) ===
      
      // 1. Výpočet průměru (Mean)
      double mean = newTimes.reduce((a, b) => a + b) / newTimes.length;

      // 2. Výpočet směrodatné odchylky (Standard Deviation)
      double variance = newTimes.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b) / newTimes.length;
      double sd = sqrt(variance);

      // 3. Filtrace - odstranění hodnot ležících mimo hranici 2 SD
      List<int> validTimes = newTimes.where((t) => (t - mean).abs() <= 2 * sd).toList();
      
      // Záchranná síť pro případ extrémně malého/anomálního vzorku
      if (validTimes.isEmpty) validTimes = newTimes;

      // 4. Výpočet robustního mediánu z očištěných dat
      validTimes.sort();
      int mid = validTimes.length ~/ 2;
      double robustMedianMs = validTimes.length % 2 != 0 
          ? validTimes[mid].toDouble() 
          : (validTimes[mid - 1] + validTimes[mid]) / 2.0;
      
      double sessionRobustMedian = robustMedianMs / 1000.0;
      
      // ==========================================

      final newItem = StroopHistoryItem(DateTime.now(), newScore, state.totalRounds, sessionRobustMedian, state.activeGameType);
      final newHistory = List<StroopHistoryItem>.from(state.history)..add(newItem);
      
      _prefs?.setStringList('stroop_history', newHistory.map((e) => e.toRawString()).toList());
            // 2. Odeslání do KCI profilu a analytiky
      if (_prefs != null) {
        final nowStr = DateTime.now().toIso8601String();
        // Zde ukládáme sessionRobustMedian (čím menší čas v sekundách, tím lépe)
        final scoreVal = sessionRobustMedian * 1000.0; // Převod zpět na ms pro uložení
        
        // A: Surová historie pro KCI (držíme 50 záznamů)
        List<String> historyKCI = _prefs!.getStringList('history_stroop') ?? [];
        historyKCI.add(scoreVal.toString());
        if (historyKCI.length > 50) historyKCI.removeAt(0);
        _prefs!.setStringList('history_stroop', historyKCI);
        
        // B: Denní agregát pro graf (bere minimum = nejrychlejší čas z daného dne)
        final today = nowStr.substring(0, 10);
        List<String> dailyRaw = _prefs!.getStringList('stroop_daily_history') ?? [];
        Map<String, double> dailyMap = {};
        
        for (String entry in dailyRaw) {
          final parts = entry.split('|');
          if (parts.length == 2) dailyMap[parts[0]] = double.tryParse(parts[1]) ?? 3000.0;
        }
        
        if (dailyMap.containsKey(today)) {
          if (scoreVal < dailyMap[today]!) dailyMap[today] = scoreVal; // Tady chceme MINIMUM!
        } else {
          dailyMap[today] = scoreVal;
        }
        
        var sortedKeys = dailyMap.keys.toList()..sort();
        if (sortedKeys.length > 10) sortedKeys = sortedKeys.sublist(sortedKeys.length - 10);
        
        _prefs!.setStringList('stroop_daily_history', sortedKeys.map((k) => '$k|${dailyMap[k]}').toList());
        
        // C: Validita
        _prefs!.setInt('validity_inhibition', sortedKeys.length);
      }

      emit(state.copyWith(phase: StroopPhase.result, score: newScore, history: newHistory));
    } else {
      emit(state.copyWith(score: newScore, currentRound: state.currentRound + 1, currentReactionTimesMs: newTimes));
      _generateTask(emit);
    }
  }

  void _generateTask(Emitter<StroopState> emit) {
    List<String> names = _colorMap.keys.toList();
    
    String word = names[_random.nextInt(names.length)];
    String inkName = names[_random.nextInt(names.length)];
    
    if (state.activeGameType == StroopGameType.trueFalse && _random.nextBool()) inkName = word;
    
    Color inkColor = _colorMap[inkName]!;
    List<String> options = [];
    String correct = '';

    if (state.activeGameType == StroopGameType.standard) {
      options = List.from(names); // ODSTRANĚNO .shuffle() - Fixní rozložení kláves
      correct = inkName;
    } else if (state.activeGameType == StroopGameType.reverse) {
      options = List.from(names); // ODSTRANĚNO .shuffle() - Fixní rozložení kláves
      correct = word;
    } else {
      options = ['PRAVDA', 'NEPRAVDA'];
      correct = (word == inkName) ? 'PRAVDA' : 'NEPRAVDA';
    }

    emit(state.copyWith(currentWord: word, currentInkColor: inkColor, options: options, correctAnswer: correct));
    _stopwatch.reset();
    _stopwatch.start();
  }
}
