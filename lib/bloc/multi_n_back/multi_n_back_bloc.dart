import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'multi_n_back_event.dart';
import 'multi_n_back_state.dart';

class MultiNBackBloc extends Bloc<MultiNBackEvent, MultiNBackState> {
  final Random _rnd = Random();
  final FlutterTts _flutterTts = FlutterTts(); 
  SharedPreferences? _prefs;

  final List<int> _positions = [];
  final List<int> _sounds = [];
  final List<int> _colors = [];
  final List<int> _shapes = [];
  final List<String> _spokenLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
  
  Timer? _gameTimer;
  int _actualTargets = 0; 

  MultiNBackBloc() : super(const MultiNBackState()) {
    on<InitMultiNBack>(_onInit);
    on<SetLanguageEvent>((event, emit) async {
      String ttsLang = event.langCode == 'en' ? "en-US" : (event.langCode == 'de' ? "de-DE" : "cs-CZ");
      try {
        await _flutterTts.setLanguage(ttsLang);
        await _flutterTts.setSpeechRate(0.5); 
      } catch (e) { 
        debugPrint("Chyba TTS: $e"); 
      }
    });

    on<ShowPreTraining>((event, emit) {
      if (event.adaptive) {
        int adaptN = _prefs?.getInt('dnb_adapt_n') ?? 2;
        int adaptSubLevel = _prefs?.getInt('dnb_adapt_sublevel') ?? 0;
        bool leveledUp = _prefs?.getBool('dnb_has_leveled_up') ?? false;

        // Pojistka, kdyby se v nastavení změnil počet kroků a my zůstali "mimo mapu"
        if (adaptSubLevel >= state.adaptiveStepCount) {
          adaptSubLevel = state.adaptiveStepCount - 1;
        } else if (adaptSubLevel < 0) {
          adaptSubLevel = 0;
        }

        bool isVar = state.adaptiveUseVar && (adaptSubLevel == state.adaptiveStepCount - 1);
        int currentSpeed = state.adaptiveSpeedMinMs + ((state.adaptiveStepCount - 1) - adaptSubLevel) * state.adaptiveSpeedStepMs;

        emit(state.copyWith(
          phase: MultiNBackPhase.preTraining, 
          isAdaptive: true,
          currentN: adaptN,
          currentSubLevel: adaptSubLevel,
          currentSpeedMs: currentSpeed,
          isVariableSpeed: isVar,
          currentModalities: state.activeModalities,
          hasLeveledUp: leveledUp, 
        ));
      } else {
        emit(state.copyWith(
          phase: MultiNBackPhase.preTraining, 
          isAdaptive: false,
          currentN: state.manualN,
          currentSpeedMs: state.manualSpeedMs,
          isVariableSpeed: false,
          currentModalities: state.activeModalities,
          hasLeveledUp: false, 
        ));
      }
    });
    
    on<PauseGame>((event, emit) {
      _cancelTimer();
      emit(state.copyWith(phase: MultiNBackPhase.paused));
    });

    on<ResumeGame>((event, emit) {
      emit(state.copyWith(phase: MultiNBackPhase.playing));
      if (state.currentRound > 0 && _positions.isNotEmpty) {
        add(ShowStimulus(_positions.last, _sounds.last, _colors.isEmpty ? 0 : _colors.last, _shapes.isEmpty ? 0 : _shapes.last));
      } else {
        add(NextRound()); 
      }
    });

    on<StartGame>(_onStartGame);
    on<NextRound>(_onNextRound);
    on<ShowStimulus>(_onShowStimulus);
    
    on<PositionMatchClicked>((event, emit) => _handleMatchClick('pos', emit));
    on<AudioMatchClicked>((event, emit) => _handleMatchClick('snd', emit));
    on<ColorMatchClicked>((event, emit) => _handleMatchClick('col', emit));
    on<ShapeMatchClicked>((event, emit) => _handleMatchClick('shp', emit));
    
    on<ClearPositionError>((event, emit) => emit(state.copyWith(isPositionError: false)));
    on<ClearAudioError>((event, emit) => emit(state.copyWith(isAudioError: false)));
    on<ClearColorError>((event, emit) => emit(state.copyWith(isColorError: false)));
    on<ClearShapeError>((event, emit) => emit(state.copyWith(isShapeError: false)));
    
    on<ShowSettings>((event, emit) { _cancelTimer(); emit(state.copyWith(phase: MultiNBackPhase.settings)); });
    on<UpdateSettings>(_onUpdateSettings);
    
    on<ShowHistory>((event, emit) { _cancelTimer(); emit(state.copyWith(phase: MultiNBackPhase.history)); });
    
    on<ResetMultiNBack>((event, emit) { 
      _cancelTimer(); 
      emit(state.copyWith(phase: MultiNBackPhase.menu, score: 0)); 
    });

    on<LoadDailyProgressEvent>(_onLoadDailyProgress);
    on<UpdateDailyGoalEvent>(_onUpdateDailyGoal);

    add(InitMultiNBack()); 
  }

  Future<void> _onInit(InitMultiNBack event, Emitter<MultiNBackState> emit) async {
    _prefs = await SharedPreferences.getInstance();
    
    // Klasické nastavení
    final manualN = _prefs?.getInt('dnb_manual_n') ?? 2;
    final manualSpeedMs = _prefs?.getInt('dnb_manual_speed_ms') ?? 2500;
    final adaptationSpeed = _prefs?.getInt('dnb_adaptation_speed') ?? 1; 
    final activeModalities = _prefs?.getInt('dnb_active_modalities') ?? 2; 

    // NOVÉ: Načtení dynamických adaptivních limitů
    final adaptiveSpeedStepMs = _prefs?.getInt('dnb_adaptive_speed_step_ms') ?? 200;
    final adaptiveSpeedMinMs = _prefs?.getInt('dnb_adaptive_speed_min_ms') ?? 1500;
    final adaptiveStepCount = _prefs?.getInt('dnb_adaptive_step_count') ?? 3;
    final adaptiveUseVar = _prefs?.getBool('dnb_adaptive_use_var') ?? true;
    
    final rawHistory = _prefs?.getStringList('dnb_history') ?? [];
    
    List<MultiNBackHistoryItem> safeHistory = [];
    for (var s in rawHistory) {
      try {
        safeHistory.add(MultiNBackHistoryItem.fromRawString(s));
      } catch (e) {
        debugPrint("Ignoruji nekompatibilní historický záznam: $s");
      }
    }
    
    emit(state.copyWith(
      manualN: manualN, 
      manualSpeedMs: manualSpeedMs, 
      adaptationSpeed: adaptationSpeed, 
      adaptiveSpeedStepMs: adaptiveSpeedStepMs,
      adaptiveSpeedMinMs: adaptiveSpeedMinMs,
      adaptiveStepCount: adaptiveStepCount,
      adaptiveUseVar: adaptiveUseVar,
      activeModalities: activeModalities, 
      history: safeHistory
    ));
    
    add(LoadDailyProgressEvent());
  }

  Future<void> _onLoadDailyProgress(LoadDailyProgressEvent event, Emitter<MultiNBackState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String lastDate = prefs.getString('dnb_last_date') ?? '';
    
    final int goal = prefs.getInt('dnb_daily_goal') ?? 20;
    int count = 0;
    if (lastDate == today) count = prefs.getInt('dnb_daily_count') ?? 0;
    final bool leveledUp = prefs.getBool('dnb_has_leveled_up') ?? false;

    emit(state.copyWith(dailyGoal: goal, dailyCount: count, hasLeveledUp: leveledUp));
  }

  Future<void> _onUpdateDailyGoal(UpdateDailyGoalEvent event, Emitter<MultiNBackState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dnb_daily_goal', event.newGoal);
    emit(state.copyWith(dailyGoal: event.newGoal));
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<MultiNBackState> emit) {
    final n = event.manualN ?? state.manualN;
    final s = event.manualSpeedMs ?? state.manualSpeedMs;
    final aSpeed = event.adaptationSpeed ?? state.adaptationSpeed;
    final aStepMs = event.adaptiveSpeedStepMs ?? state.adaptiveSpeedStepMs;
    final aMinMs = event.adaptiveSpeedMinMs ?? state.adaptiveSpeedMinMs;
    final aCount = event.adaptiveStepCount ?? state.adaptiveStepCount;
    final aVar = event.adaptiveUseVar ?? state.adaptiveUseVar;
    final mods = event.activeModalities ?? state.activeModalities;
    
    _prefs?.setInt('dnb_manual_n', n);
    _prefs?.setInt('dnb_manual_speed_ms', s);
    _prefs?.setInt('dnb_adaptation_speed', aSpeed);
    _prefs?.setInt('dnb_adaptive_speed_step_ms', aStepMs);
    _prefs?.setInt('dnb_adaptive_speed_min_ms', aMinMs);
    _prefs?.setInt('dnb_adaptive_step_count', aCount);
    _prefs?.setBool('dnb_adaptive_use_var', aVar);
    _prefs?.setInt('dnb_active_modalities', mods);
    
    emit(state.copyWith(
      manualN: n, 
      manualSpeedMs: s, 
      adaptationSpeed: aSpeed, 
      adaptiveSpeedStepMs: aStepMs,
      adaptiveSpeedMinMs: aMinMs,
      adaptiveStepCount: aCount,
      adaptiveUseVar: aVar,
      activeModalities: mods,
      currentSubLevel: 0 // Bezpečnostní reset po změně hranic
    ));
  }

  void _onStartGame(StartGame event, Emitter<MultiNBackState> emit) {
    _cancelTimer();
    _positions.clear(); _sounds.clear(); _colors.clear(); _shapes.clear();
    _actualTargets = 0; 
    _prefs?.setBool('dnb_has_leveled_up', false);

    emit(state.copyWith(
      phase: MultiNBackPhase.playing, 
      currentRound: 0, 
      score: 0, 
      activeSquareIndex: -1,
      positionMatchClicked: false, audioMatchClicked: false, colorMatchClicked: false, shapeMatchClicked: false,
      isPositionError: false, isAudioError: false, isColorError: false, isShapeError: false,
      hasLeveledUp: false,
    ));
    add(NextRound());
  }

  int _generateTarget(List<int> sequence, int nLevel, int currentRound) {
    if (currentRound >= nLevel && _rnd.nextDouble() < 0.3) {
      _actualTargets++;
      return sequence[currentRound - nLevel];
    } else {
      int nextVal = _rnd.nextInt(9);
      if (currentRound >= nLevel && nextVal == sequence[currentRound - nLevel]) {
        nextVal = (nextVal + 1) % 9;
      }
      return nextVal;
    }
  }

  void _onNextRound(NextRound event, Emitter<MultiNBackState> emit) {
    _cancelTimer();
    
    if (state.currentRound > 0) _evaluateRound(emit);
    if (state.currentRound >= state.totalRounds) { _finishGame(emit); return; }

    int nextPos = _generateTarget(_positions, state.currentN, state.currentRound);
    int nextSnd = _generateTarget(_sounds, state.currentN, state.currentRound);
    int nextCol = state.currentModalities >= 3 ? _generateTarget(_colors, state.currentN, state.currentRound) : 0;
    int nextShp = state.currentModalities >= 4 ? _generateTarget(_shapes, state.currentN, state.currentRound) : 0;

    _positions.add(nextPos); _sounds.add(nextSnd); 
    if (state.currentModalities >= 3) _colors.add(nextCol);
    if (state.currentModalities >= 4) _shapes.add(nextShp);
    
    emit(state.copyWith(
      currentRound: state.currentRound + 1, 
      activeSquareIndex: -1, 
      positionMatchClicked: false, audioMatchClicked: false, colorMatchClicked: false, shapeMatchClicked: false
    ));

    _gameTimer = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) add(ShowStimulus(nextPos, nextSnd, nextCol, nextShp));
    });
  }

  void _onShowStimulus(ShowStimulus event, Emitter<MultiNBackState> emit) {
    _cancelTimer();
    emit(state.copyWith(activeSquareIndex: event.pos, activeColorIndex: event.color, activeShapeIndex: event.shape));
    _flutterTts.speak(_spokenLetters[event.sound]);

    int roundTime;
    if (state.isVariableSpeed) {
      // VAR je uzamčený POUZE pro časy vygenerované tvým dynamickým nastavením
      List<int> possibleTimes = List.generate(
        state.adaptiveStepCount, 
        (i) => state.adaptiveSpeedMinMs + i * state.adaptiveSpeedStepMs
      );
      roundTime = possibleTimes[_rnd.nextInt(possibleTimes.length)];
    } else {
      roundTime = state.currentSpeedMs;
    }

    int remainingTime = max(500, roundTime - 400);
    
    _gameTimer = Timer(Duration(milliseconds: remainingTime), () {
      if (!isClosed) add(NextRound());
    });
  }

    void _handleMatchClick(String type, Emitter<MultiNBackState> emit) {
    if (state.currentRound == 0) {
      return;
    }
    
    bool alreadyClicked = false;
    List<int> sequence = [];
    
    if (type == 'pos') { 
      alreadyClicked = state.positionMatchClicked; 
      sequence = _positions; 
    } else if (type == 'snd') { 
      alreadyClicked = state.audioMatchClicked; 
      sequence = _sounds; 
    } else if (type == 'col') { 
      alreadyClicked = state.colorMatchClicked; 
      sequence = _colors; 
    } else if (type == 'shp') { 
      alreadyClicked = state.shapeMatchClicked; 
      sequence = _shapes; 
    }

    if (alreadyClicked) {
      return;
    }

    bool isMistake = false;
    int scoreChange = 0;

    if (state.currentRound <= state.currentN) {
      isMistake = true; 
      scoreChange = -1;
    } else {
      int nBackIndex = state.currentRound - 1 - state.currentN;
      if (sequence.last == sequence[nBackIndex]) {
        scoreChange = 1;
      } else {
        isMistake = true; 
        scoreChange = -1;
      }
    }

    int newScore = max(0, state.score + scoreChange);

    if (isMistake) {
      if (_prefs?.getBool('global_is_haptic') ?? true) {
        Vibration.vibrate(duration: _prefs?.getInt('global_haptic_duration') ?? 500);
      }
      
      if (type == 'pos') { 
        emit(state.copyWith(positionMatchClicked: true, score: newScore, isPositionError: true)); 
        Future.delayed(const Duration(milliseconds: 300), () { if (!isClosed) add(ClearPositionError()); }); 
      } else if (type == 'snd') { 
        emit(state.copyWith(audioMatchClicked: true, score: newScore, isAudioError: true)); 
        Future.delayed(const Duration(milliseconds: 300), () { if (!isClosed) add(ClearAudioError()); }); 
      } else if (type == 'col') { 
        emit(state.copyWith(colorMatchClicked: true, score: newScore, isColorError: true)); 
        Future.delayed(const Duration(milliseconds: 300), () { if (!isClosed) add(ClearColorError()); }); 
      } else if (type == 'shp') { 
        emit(state.copyWith(shapeMatchClicked: true, score: newScore, isShapeError: true)); 
        Future.delayed(const Duration(milliseconds: 300), () { if (!isClosed) add(ClearShapeError()); }); 
      }
    } else {
      // ZDE BYL TVŮJ ZDROJ CHYB Z FOTKY - Nyní je vše ve složených závorkách
      if (type == 'pos') {
        emit(state.copyWith(positionMatchClicked: true, score: newScore));
      } else if (type == 'snd') {
        emit(state.copyWith(audioMatchClicked: true, score: newScore));
      } else if (type == 'col') {
        emit(state.copyWith(colorMatchClicked: true, score: newScore));
      } else if (type == 'shp') {
        emit(state.copyWith(shapeMatchClicked: true, score: newScore));
      }
    }
  }


  void _evaluateRound(Emitter<MultiNBackState> emit) {
    if (state.currentRound <= state.currentN) return;
    
    int nIndex = state.currentRound - 1 - state.currentN;
    
    bool pMissed = (_positions.last == _positions[nIndex]) && !state.positionMatchClicked;
    bool sMissed = (_sounds.last == _sounds[nIndex]) && !state.audioMatchClicked;
    bool cMissed = state.currentModalities >= 3 && (_colors.last == _colors[nIndex]) && !state.colorMatchClicked;
    bool shMissed = state.currentModalities >= 4 && (_shapes.last == _shapes[nIndex]) && !state.shapeMatchClicked;

    if (pMissed || sMissed || cMissed || shMissed) {
      if (_prefs?.getBool('global_is_haptic') ?? true) Vibration.vibrate(duration: _prefs?.getInt('global_haptic_duration') ?? 500); 
      
      emit(state.copyWith(
        isPositionError: state.isPositionError || pMissed, 
        isAudioError: state.isAudioError || sMissed,
        isColorError: state.isColorError || cMissed,
        isShapeError: state.isShapeError || shMissed,
      ));
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isClosed) { 
          if (pMissed) add(ClearPositionError()); 
          if (sMissed) add(ClearAudioError()); 
          if (cMissed) add(ClearColorError()); 
          if (shMissed) add(ClearShapeError()); 
        }
      });
    }
  }

  void _finishGame(Emitter<MultiNBackState> emit) async {
    double currentSuccessRate = _actualTargets > 0 ? (state.score / _actualTargets).clamp(0.0, 1.0) : 1.0;
    
    int nextN = state.currentN;
    int nextSubLevel = state.currentSubLevel;
    bool leveledUp = false;

    if (state.isAdaptive) {
      List<double> recentRates = [currentSuccessRate];
      
      if (state.adaptationSpeed > 1) {
        var identicalHistory = state.history.where((e) => 
          e.isAdaptive && e.nLevel == state.currentN && e.modalities == state.currentModalities && e.speedMs == state.currentSpeedMs && e.isVariableSpeed == state.isVariableSpeed
        ).toList().reversed.toList();
        
        for (int i = 0; i < state.adaptationSpeed - 1 && i < identicalHistory.length; i++) {
          recentRates.add(identicalHistory[i].score / (state.totalRounds * state.currentModalities));
        }
      }

      if (recentRates.length >= state.adaptationSpeed) {
        recentRates.sort();
        double medianRate = recentRates.length % 2 == 1 ? recentRates[recentRates.length ~/ 2] : (recentRates[recentRates.length ~/ 2 - 1] + recentRates[recentRates.length ~/ 2]) / 2.0;

        // NOVÁ A ČISTÁ MATEMATIKA: Postup pouze přes sub-levely
        if (medianRate >= 0.8) {
          leveledUp = true;
          nextSubLevel++;
          if (nextSubLevel >= state.adaptiveStepCount) {
            nextN++;         // Zdolány všechny kroky, zvedáme N
            nextSubLevel = 0; // Začínáme znovu na novém N (nejdelší čas)
          }
        } else if (medianRate < 0.5) {
          nextSubLevel--;
          if (nextSubLevel < 0) {
            if (nextN > 1) {
              nextN--; // Pád o N dolů
              nextSubLevel = state.adaptiveStepCount - 1; // Spadne na nejtěžší bod předešlého N
            } else {
              nextSubLevel = 0; // Dno - nelze klesnout (N=1, nejpomalejší čas)
            }
          }
        }
      }
      
      _prefs?.setInt('dnb_adapt_n', nextN);
      _prefs?.setInt('dnb_adapt_sublevel', nextSubLevel);
      _prefs?.setBool('dnb_has_leveled_up', leveledUp); 
    }

    // Výpočet vlastností pro příští hru
    bool nextVar = state.adaptiveUseVar && (nextSubLevel == state.adaptiveStepCount - 1);
    int nextSpeed = state.adaptiveSpeedMinMs + ((state.adaptiveStepCount - 1) - nextSubLevel) * state.adaptiveSpeedStepMs;

    int scaledScoreForUI = (currentSuccessRate * (state.totalRounds * state.currentModalities)).round();
    final newItem = MultiNBackHistoryItem(DateTime.now(), state.currentN, scaledScoreForUI, state.isAdaptive, state.currentSpeedMs, state.isVariableSpeed, state.currentModalities);
    final newHistory = List<MultiNBackHistoryItem>.from(state.history)..add(newItem);
    _prefs?.setStringList('dnb_history', newHistory.map((e) => e.toRawString()).toList());

    final String today = DateTime.now().toIso8601String().substring(0, 10);
    final String lastDate = _prefs?.getString('dnb_last_date') ?? '';
    
    int newCount = (lastDate == today) ? (_prefs?.getInt('dnb_daily_count') ?? 0) + 1 : 1;
    _prefs?.setString('dnb_last_date', today);
    _prefs?.setInt('dnb_daily_count', newCount);

    emit(state.copyWith(
      phase: MultiNBackPhase.result, 
      currentN: nextN, 
      currentSubLevel: nextSubLevel,
      currentSpeedMs: nextSpeed, 
      isVariableSpeed: nextVar, 
      score: scaledScoreForUI, 
      history: newHistory, 
      activeSquareIndex: -1,
      dailyCount: newCount,
      hasLeveledUp: leveledUp 
    ));
  }

  void _cancelTimer() {
    if (_gameTimer != null && _gameTimer!.isActive) _gameTimer!.cancel();
    _flutterTts.stop();
  }

  @override
  Future<void> close() { 
    _cancelTimer(); 
    return super.close(); 
  }
}
