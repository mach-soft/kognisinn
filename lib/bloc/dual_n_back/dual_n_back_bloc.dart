import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'dual_n_back_event.dart';
import 'dual_n_back_state.dart';

class DualNBackBloc extends Bloc<DualNBackEvent, DualNBackState> {
  final Random _rnd = Random();
  final FlutterTts _flutterTts = FlutterTts(); 
  SharedPreferences? _prefs;

  final List<int> _positions = [];
  final List<int> _sounds = [];
  final List<String> _spokenLetters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
  
  Timer? _gameTimer;
  int _actualTargets = 0; 

  DualNBackBloc() : super(const DualNBackState()) {
    on<InitDualNBack>(_onInit);
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
      emit(state.copyWith(phase: DualNBackPhase.preTraining, isAdaptive: event.adaptive));
    });
    
    on<PauseGame>((event, emit) {
      _cancelTimer();
      emit(state.copyWith(phase: DualNBackPhase.paused));
    });

    on<ResumeGame>((event, emit) {
      emit(state.copyWith(phase: DualNBackPhase.playing));
      if (state.currentRound > 0 && _positions.isNotEmpty && _sounds.isNotEmpty) {
        int lastPos = _positions.last;
        int lastSound = _sounds.last;
        add(ShowStimulus(lastPos, lastSound));
      } else {
        add(NextRound()); 
      }
    });

    on<StartGame>(_onStartGame);
    on<NextRound>(_onNextRound);
    on<ShowStimulus>(_onShowStimulus);
    
    on<PositionMatchClicked>((event, emit) {
      emit(state.copyWith(positionMatchClicked: true));
    });
    on<AudioMatchClicked>((event, emit) {
      emit(state.copyWith(audioMatchClicked: true));
    });
    on<ClearPositionError>((event, emit) {
      emit(state.copyWith(isPositionError: false));
    });
    on<ClearAudioError>((event, emit) {
      emit(state.copyWith(isAudioError: false));
    });
    
    on<ShowSettings>((event, emit) { 
      _cancelTimer(); 
      emit(state.copyWith(phase: DualNBackPhase.settings)); 
    });
    on<UpdateSettings>(_onUpdateSettings);
    
    on<ShowHistory>((event, emit) { 
      _cancelTimer(); 
      emit(state.copyWith(phase: DualNBackPhase.history)); 
    });
    on<ResetDualNBack>((event, emit) { 
      _cancelTimer(); 
      emit(state.copyWith(phase: DualNBackPhase.menu, score: 0)); 
    });

    add(InitDualNBack()); 
  }

  Future<void> _onInit(InitDualNBack event, Emitter<DualNBackState> emit) async {
    _prefs = await SharedPreferences.getInstance();
    final manualN = _prefs?.getInt('dnb_manual_n') ?? 2;
    final manualSpeedMs = _prefs?.getInt('dnb_manual_speed_ms') ?? 2500;
    final adaptationSpeed = _prefs?.getInt('dnb_adaptation_speed') ?? 1; 
    
    final rawHistory = _prefs?.getStringList('dnb_history') ?? [];
    final history = rawHistory.map((s) => DualNBackHistoryItem.fromRawString(s)).toList();
    
    emit(state.copyWith(manualN: manualN, manualSpeedMs: manualSpeedMs, adaptationSpeed: adaptationSpeed, history: history));
  }

  void _onUpdateSettings(UpdateSettings event, Emitter<DualNBackState> emit) {
    final n = event.manualN ?? state.manualN;
    final s = event.manualSpeedMs ?? state.manualSpeedMs;
    final aSpeed = event.adaptationSpeed ?? state.adaptationSpeed;
    _prefs?.setInt('dnb_manual_n', n);
    _prefs?.setInt('dnb_manual_speed_ms', s);
    _prefs?.setInt('dnb_adaptation_speed', aSpeed);
    emit(state.copyWith(manualN: n, manualSpeedMs: s, adaptationSpeed: aSpeed));
  }

  void _onStartGame(StartGame event, Emitter<DualNBackState> emit) {
    _cancelTimer();
    _positions.clear(); 
    _sounds.clear();
    _actualTargets = 0; 
    
    int startN = event.adaptive ? (_prefs?.getInt('dnb_adapt_n') ?? 2) : state.manualN;
    int startSpeed = event.adaptive ? (_prefs?.getInt('dnb_adapt_speed') ?? 2500) : state.manualSpeedMs;
    bool startVar = event.adaptive ? (_prefs?.getBool('dnb_adapt_var') ?? false) : false;
    
    emit(state.copyWith(
      phase: DualNBackPhase.playing, 
      isAdaptive: event.adaptive,
      currentN: startN, 
      currentSpeedMs: startSpeed, 
      isVariableSpeed: startVar,
      currentRound: 0, 
      score: 0, 
      activeSquareIndex: -1,
      positionMatchClicked: false, 
      audioMatchClicked: false,
      isPositionError: false, 
      isAudioError: false,
    ));
    add(NextRound());
  }

  void _onNextRound(NextRound event, Emitter<DualNBackState> emit) {
    _cancelTimer();
    
    if (state.currentRound > 0) {
      _evaluateRound(emit);
    }
    if (state.currentRound >= state.totalRounds) { 
      _finishGame(emit); 
      return; 
    }

    int nextPos;
    int nextSound;
    
    if (state.currentRound >= state.currentN && _rnd.nextDouble() < 0.3) {
      nextPos = _positions[state.currentRound - state.currentN];
      _actualTargets++; 
    } else {
      nextPos = _rnd.nextInt(9);
      if (state.currentRound >= state.currentN && nextPos == _positions[state.currentRound - state.currentN]) {
        nextPos = (nextPos + 1) % 9;
      }
    }

    if (state.currentRound >= state.currentN && _rnd.nextDouble() < 0.3) {
      nextSound = _sounds[state.currentRound - state.currentN];
      _actualTargets++; 
    } else {
      nextSound = _rnd.nextInt(9);
      if (state.currentRound >= state.currentN && nextSound == _sounds[state.currentRound - state.currentN]) {
        nextSound = (nextSound + 1) % 9;
      }
    }

    _positions.add(nextPos); 
    _sounds.add(nextSound);
    
    emit(state.copyWith(currentRound: state.currentRound + 1, activeSquareIndex: -1, positionMatchClicked: false, audioMatchClicked: false));

    _gameTimer = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) {
        add(ShowStimulus(nextPos, nextSound));
      }
    });
  }

  void _onShowStimulus(ShowStimulus event, Emitter<DualNBackState> emit) {
    _cancelTimer();
    emit(state.copyWith(activeSquareIndex: event.pos));
    _flutterTts.speak(_spokenLetters[event.sound]);

    int roundTime;
    if (state.isVariableSpeed) {
      roundTime = 1500 + _rnd.nextInt(1001);
    } else {
      roundTime = state.currentSpeedMs;
    }
    
    int remainingTime = roundTime - 400;
    if (remainingTime < 500) {
      remainingTime = 500;
    } 
    
    _gameTimer = Timer(Duration(milliseconds: remainingTime), () {
      if (!isClosed) {
        add(NextRound());
      }
    });
  }

  void _evaluateRound(Emitter<DualNBackState> emit) {
    if (state.currentRound <= state.currentN) {
      return;
    }
    
    int nBackIndex = state.currentRound - 1 - state.currentN;
    bool pMatch = _positions.last == _positions[nBackIndex];
    bool sMatch = _sounds.last == _sounds[nBackIndex];
    int rScore = 0;
    bool pMistake = false;
    bool sMistake = false;

    if (pMatch) { 
      if (state.positionMatchClicked) {
        rScore++; 
      } else {
        pMistake = true; 
      }
    } else { 
      if (state.positionMatchClicked) { 
        pMistake = true; 
        rScore--; 
      } 
    }

    if (sMatch) { 
      if (state.audioMatchClicked) {
        rScore++; 
      } else {
        sMistake = true; 
      }
    } else { 
      if (state.audioMatchClicked) { 
        sMistake = true; 
        rScore--; 
      } 
    }

    int newScore = max(0, state.score + rScore);

    if (pMistake || sMistake) {
      if (_prefs?.getBool('global_is_haptic') ?? true) {
        Vibration.vibrate(duration: _prefs?.getInt('global_haptic_duration') ?? 500); 
      }
      
      emit(state.copyWith(score: newScore, isPositionError: pMistake, isAudioError: sMistake));
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!isClosed) { 
          if (pMistake) {
            add(ClearPositionError()); 
          }
          if (sMistake) {
            add(ClearAudioError()); 
          }
        }
      });
    } else {
      emit(state.copyWith(score: newScore));
    }
  }

  void _finishGame(Emitter<DualNBackState> emit) {
    double currentSuccessRate;
    if (_actualTargets > 0) {
      currentSuccessRate = (state.score / _actualTargets).clamp(0.0, 1.0);
    } else {
      currentSuccessRate = 1.0;
    }
    
    int nextN = state.currentN;
    int nextSpeed = state.currentSpeedMs;
    bool nextVar = state.isVariableSpeed;

    if (state.isAdaptive) {
      List<double> recentRates = [currentSuccessRate];
      
      if (state.adaptationSpeed > 1) {
        var identicalHistory = state.history.where((e) => 
          e.isAdaptive && e.nLevel == state.currentN && e.speedMs == state.currentSpeedMs && e.isVariableSpeed == state.isVariableSpeed
        ).toList().reversed.toList();
        
        for (int i = 0; i < state.adaptationSpeed - 1 && i < identicalHistory.length; i++) {
          recentRates.add(identicalHistory[i].score / (state.totalRounds * 2));
        }
      }

      recentRates.sort();
      double medianRate;
      
      if (recentRates.length % 2 == 1) {
        medianRate = recentRates[recentRates.length ~/ 2];
      } else {
        medianRate = (recentRates[recentRates.length ~/ 2 - 1] + recentRates[recentRates.length ~/ 2]) / 2.0;
      }

      if (medianRate >= 0.8) {
        if (!nextVar) {
          if (nextSpeed > 1500) {
            nextSpeed -= 500; 
          } else {
            nextVar = true;
          }
        } else {
          nextN++; 
          nextVar = false; 
          nextSpeed = 2500;
        }
      } else if (medianRate < 0.5) {
        if (nextVar) { 
          nextVar = false; 
          nextSpeed = 1500;
        } else {
          if (nextSpeed < 2500) {
            nextSpeed += 500;
          } else if (nextN > 1) { 
            nextN--; 
            nextVar = true; 
          }
        }
      }
      
      _prefs?.setInt('dnb_adapt_n', nextN);
      _prefs?.setInt('dnb_adapt_speed', nextSpeed);
      _prefs?.setBool('dnb_adapt_var', nextVar);
    }

    int scaledScoreForUI = (currentSuccessRate * (state.totalRounds * 2)).round();
    final newItem = DualNBackHistoryItem(DateTime.now(), state.currentN, scaledScoreForUI, state.isAdaptive, state.currentSpeedMs, state.isVariableSpeed);
    final newHistory = List<DualNBackHistoryItem>.from(state.history)..add(newItem);
    _prefs?.setStringList('dnb_history', newHistory.map((e) => e.toRawString()).toList());

    emit(state.copyWith(phase: DualNBackPhase.result, currentN: nextN, score: scaledScoreForUI, history: newHistory, activeSquareIndex: -1));
  }

  void _cancelTimer() {
    if (_gameTimer != null && _gameTimer!.isActive) {
      _gameTimer!.cancel();
    }
    _flutterTts.stop();
  }

  @override
  Future<void> close() { 
    _cancelTimer(); 
    return super.close(); 
  }
}
