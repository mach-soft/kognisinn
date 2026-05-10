import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';

import 'digit_span_event.dart';
import 'digit_span_state.dart';

class DigitSpanBloc extends Bloc<DigitSpanEvent, DigitSpanState> {
  final FlutterTts _flutterTts = FlutterTts();
  final Random _random = Random();
  SharedPreferences? _prefs;

  DigitSpanBloc() : super(const DigitSpanState()) {
    on<InitializeHardwareEvent>(_onInitializeHardware);
    
    on<SetLanguageEvent>((event, emit) async {
      String ttsLang = "cs-CZ";
      if (event.langCode == 'en') ttsLang = "en-US";
      if (event.langCode == 'de') ttsLang = "de-DE";
      
      try {
        await _flutterTts.setLanguage(ttsLang);
        await _flutterTts.setSpeechRate(0.5); 
      } catch (e) {
        debugPrint("Chyba změny TTS jazyka: $e");
      }
    });

    on<SplashFinishedEvent>((event, emit) => emit(state.copyWith(phase: GamePhase.menu)));
    on<ReturnToMenuEvent>(_onReturnToMenu);
    on<ShowSettingsEvent>((event, emit) => emit(state.copyWith(phase: GamePhase.settings)));
    
    on<ShowResultsEvent>((event, emit) {
      if (_prefs != null) {
        Map<GameMode, int> freshHighScores = {};
        for (var mode in GameMode.values) {
          freshHighScores[mode] = _prefs!.getInt('highScore_$mode') ?? 0;
        }
        emit(state.copyWith(phase: GamePhase.showingResults, highScores: freshHighScores));
      } else {
        emit(state.copyWith(phase: GamePhase.showingResults));
      }
    });

    on<SelectGameTypeEvent>((event, emit) => emit(state.copyWith(gameType: event.type, phase: GamePhase.choosingMode)));
    on<ModeSelectedEvent>(_onModeSelected);
    on<StartGameEvent>(_onStartGame);
    on<SaveGameAndExitEvent>(_onSaveGameAndExit);
    on<NumberPressedEvent>(_onNumberPressed);
    on<BackspacePressedEvent>(_onBackspacePressed);
    on<ChangeSettingsEvent>(_onChangeSettings);
    on<ChangeTrainingLevelEvent>(_onChangeTrainingLevel);
    on<PlayNextRoundEvent>(_onPlayNextRound);
  }

  Future<void> _onInitializeHardware(InitializeHardwareEvent event, Emitter<DigitSpanState> emit) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Map<GameMode, int> loadedHighScores = {};
      for (var mode in GameMode.values) {
        loadedHighScores[mode] = _prefs?.getInt('highScore_$mode') ?? 0;
      }
      emit(state.copyWith(highScores: loadedHighScores));
    } catch (e) {
      debugPrint("Chyba paměti: $e");
    }
  }

  void _onReturnToMenu(ReturnToMenuEvent event, Emitter<DigitSpanState> emit) {
    _flutterTts.stop();
    if (_prefs != null) {
        Map<GameMode, int> freshHighScores = {};
        for (var mode in GameMode.values) {
          freshHighScores[mode] = _prefs!.getInt('highScore_$mode') ?? 0;
        }
        emit(state.copyWith(phase: GamePhase.menu, highScores: freshHighScores));
    } else {
        emit(state.copyWith(phase: GamePhase.menu));
    }
  }

  void _onChangeSettings(ChangeSettingsEvent event, Emitter<DigitSpanState> emit) {
    emit(state.copyWith(
      soundSetting: event.sound ?? state.soundSetting,
      speedFactor: event.speed ?? state.speedFactor,
    ));
  }

  void _onChangeTrainingLevel(ChangeTrainingLevelEvent event, Emitter<DigitSpanState> emit) {
    int newLen = state.sequenceLength + event.change;
    if (newLen < 1) newLen = 1;
    emit(state.copyWith(sequenceLength: newLen));
  }

  Future<void> _updateHighScore(GameMode mode, int reachedLevel, Emitter<DigitSpanState> emit) async {
    if (_prefs == null) return;
    String key = 'highScore_$mode';
    int currentHigh = _prefs!.getInt(key) ?? 0;
    if (reachedLevel > currentHigh) {
      await _prefs!.setInt(key, reachedLevel);
      final newScores = Map<GameMode, int>.from(state.highScores);
      newScores[mode] = reachedLevel;
      emit(state.copyWith(highScores: newScores));
    }
  }

  void _onModeSelected(ModeSelectedEvent event, Emitter<DigitSpanState> emit) {
    add(StartGameEvent(event.mode, false));
  }

  // OPRAVA: Metoda je nyní async a volání _updateHighScore čeká na dokončení pomocí await
  Future<void> _onStartGame(StartGameEvent event, Emitter<DigitSpanState> emit) async {
    int seqLen = event.mode == GameMode.nback ? 1 : 3;
    int succ = 0;
    int fail = 0;
    bool emp = false;

    if (state.gameType == GameType.training) {
      emit(state.copyWith(gameMode: event.mode, phase: GamePhase.choosingLevel, sequenceLength: seqLen));
      return;
    }

    if (event.loadSave && _prefs != null) {
      String modeStr = event.mode.toString();
      seqLen = _prefs!.getInt('${modeStr}_level') ?? seqLen;
      succ = _prefs!.getInt('${modeStr}_successes') ?? 0;
      fail = _prefs!.getInt('${modeStr}_failures') ?? 0;
      emp = _prefs!.getBool('${modeStr}_emphatic') ?? false;
    }

    if (state.gameType == GameType.fastTest) {
      await _updateHighScore(event.mode, seqLen, emit);
    }

    emit(state.copyWith(
      gameMode: event.mode,
      sequenceLength: seqLen,
      consecutiveSuccesses: succ,
      consecutiveFailures: fail,
      isEmphaticMode: emp,
    ));
    add(PlayNextRoundEvent());
  }

  Future<void> _onSaveGameAndExit(SaveGameAndExitEvent event, Emitter<DigitSpanState> emit) async {
    if (_prefs != null) {
      String modeStr = state.gameMode.toString();
      await _prefs!.setInt('${modeStr}_level', state.sequenceLength);
      await _prefs!.setInt('${modeStr}_successes', state.consecutiveSuccesses);
      await _prefs!.setInt('${modeStr}_failures', state.consecutiveFailures);
      await _prefs!.setBool('${modeStr}_emphatic', state.isEmphaticMode);
    }
    _flutterTts.stop();
    emit(state.copyWith(phase: GamePhase.menu));
  }

  Future<void> _onPlayNextRound(PlayNextRoundEvent event, Emitter<DigitSpanState> emit) async {
    _generateSequences(emit);
    
    emit(state.copyWith(userInput: '', currentlyDisplayedDigit: '', phase: GamePhase.showingSequence));

    double finalRate = 0.5 * state.speedFactor;
    double finalPitch = state.isEmphaticMode ? 1.05 : 1.0;
    if (state.isEmphaticMode) finalRate *= 0.98;

    await _flutterTts.setPitch(finalPitch);
    await _flutterTts.setSpeechRate(finalRate);

    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < state.currentSequence.length; i++) {
      if (state.phase != GamePhase.showingSequence) break; 
      
      String digitStr = state.currentSequence[i].toString();
      emit(state.copyWith(currentlyDisplayedDigit: digitStr));
      
      if (state.soundSetting != SoundSetting.off) await _flutterTts.speak(digitStr);
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (state.phase != GamePhase.showingSequence) break;
      
      emit(state.copyWith(currentlyDisplayedDigit: ''));
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (state.phase == GamePhase.showingSequence) {
      emit(state.copyWith(phase: GamePhase.waitingForInput));
    }
  }

  void _generateSequences(Emitter<DigitSpanState> emit) {
    List<int> currentSeq = [];
    List<int> expectedSeq = [];

    if (state.gameMode == GameMode.nback) {
      int n = state.sequenceLength;
      int len = n + 4 + _random.nextInt(3);
      
      for (int i = 0; i < len; i++) {
        if (i >= n && _random.nextDouble() < 0.4) {
          currentSeq.add(currentSeq[i - n]);
          expectedSeq.add(currentSeq[i - n]);
        } else {
          int val;
          do {
            val = _random.nextInt(10);
          } while (i >= n && val == currentSeq[i - n]);
          currentSeq.add(val);
        }
      }
      if (expectedSeq.isEmpty) {
        int forceIndex = n + _random.nextInt(len - n);
        currentSeq[forceIndex] = currentSeq[forceIndex - n];
        expectedSeq.add(currentSeq[forceIndex]);
      }
    } else {
      currentSeq = List.generate(state.sequenceLength, (_) => _random.nextInt(10));
      switch (state.gameMode) {
        case GameMode.forward: expectedSeq = List.from(currentSeq); break;
        case GameMode.reverse: expectedSeq = List.from(currentSeq.reversed); break;
        case GameMode.ascending: expectedSeq = List.from(currentSeq)..sort(); break;
        default: break;
      }
    }
    emit(state.copyWith(currentSequence: currentSeq, expectedSequence: expectedSeq));
  }

  void _onBackspacePressed(BackspacePressedEvent event, Emitter<DigitSpanState> emit) {
    if (state.userInput.isNotEmpty) {
      emit(state.copyWith(userInput: state.userInput.substring(0, state.userInput.length - 1)));
    }
  }

  Future<void> _onNumberPressed(NumberPressedEvent event, Emitter<DigitSpanState> emit) async {
    if (state.phase != GamePhase.waitingForInput) return;
    
    String newInput = state.userInput + event.digit.toString();
    emit(state.copyWith(userInput: newInput));

    if (newInput.length == state.expectedSequence.length) {
      await _checkAnswer(emit);
    }
  }

  Future<void> _checkAnswer(Emitter<DigitSpanState> emit) async {
    String expectedString = state.expectedSequence.join('');
    bool isCorrect = state.userInput == expectedString;

    List<GameResult> history = List.from(state.resultsHistory);
    if (state.gameType != GameType.fastTest) {
      history.add(GameResult(DateTime.now(), isCorrect, state.gameMode, state.sequenceLength));
    }
    emit(state.copyWith(resultsHistory: history));

    if (isCorrect) {
      emit(state.copyWith(phase: GamePhase.showingSuccess));
      if (state.soundSetting == SoundSetting.numbersAndFeedback) _flutterTts.speak("ds_tts_correct".tr());
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (state.phase != GamePhase.showingSuccess) return;

      if (state.gameType == GameType.training) {
        emit(state.copyWith(phase: GamePhase.choosingLevel));
      } else if (state.gameType == GameType.fastTest) {
        emit(state.copyWith(sequenceLength: state.sequenceLength + 1));
        // OPRAVA: Přidán await pro updateHighScore
        await _updateHighScore(state.gameMode, state.sequenceLength, emit);
        add(PlayNextRoundEvent());
      } else {
        int newSucc = state.consecutiveSuccesses + 1;
        int newLen = state.sequenceLength;
        bool newEmp = state.isEmphaticMode;
        
        if (newSucc >= 5) newEmp = true;
        if (newSucc % 3 == 0) newLen++;
        
        emit(state.copyWith(consecutiveSuccesses: newSucc, consecutiveFailures: 0, sequenceLength: newLen, isEmphaticMode: newEmp));
        add(PlayNextRoundEvent());
      }
                   } else {
                      bool isHaptic = _prefs?.getBool('global_is_haptic') ?? true;
                    if (isHaptic) {
                          // Načtení délky, fallback na 500 ms
                    int hDuration = _prefs?.getInt('global_haptic_duration') ?? 500;
                    Vibration.vibrate(duration: hDuration); 
      

      emit(state.copyWith(phase: GamePhase.showingFailure));
      // ... (zbytek zůstává stejný)



      }


      emit(state.copyWith(phase: GamePhase.showingFailure));
      if (state.soundSetting == SoundSetting.numbersAndFeedback) _flutterTts.speak("ds_tts_wrong".tr());
      
      await Future.delayed(const Duration(milliseconds: 1500));
      if (state.phase != GamePhase.showingFailure) return;

      if (state.gameType == GameType.gameMode) {
        int newFail = state.consecutiveFailures + 1;
        int newLen = state.sequenceLength;
        
        if (newFail % 2 == 0 && newLen > 3) {
           if (state.gameMode == GameMode.nback && newLen > 1) {
             newLen--;
           } else if (state.gameMode != GameMode.nback) {
             newLen--;
           }
        }
        emit(state.copyWith(consecutiveFailures: newFail, consecutiveSuccesses: 0, isEmphaticMode: false, sequenceLength: newLen));
      }
      emit(state.copyWith(phase: GamePhase.gameOver));
    }
  }
}
