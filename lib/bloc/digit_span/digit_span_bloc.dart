import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'package:kognisinn/env.dart';

import 'digit_span_event.dart';
import 'digit_span_state.dart';

class DigitSpanBloc extends Bloc<DigitSpanEvent, DigitSpanState> {
  final Random _rnd = Random();
  final FlutterTts _flutterTts = FlutterTts();
  SharedPreferences? _prefs;
  
  // Zamezení běhu smyček po opuštění modulu
  int _roundId = 0;

  DigitSpanBloc() : super(const DigitSpanState()) {
    on<InitializeHardwareEvent>(_onInit);
    on<SplashFinishedEvent>((event, emit) => emit(state.copyWith(phase: GamePhase.menu)));
    on<ReturnToMenuEvent>(_onReturnToMenu);
    on<ShowSettingsEvent>((event, emit) {
      _cancelRound();
      emit(state.copyWith(phase: GamePhase.settings));
    });
    on<ShowResultsEvent>((event, emit) {
      _cancelRound();
      emit(state.copyWith(phase: GamePhase.showingResults));
    });
    
    on<SetLanguageEvent>(_onSetLanguage);
    
    on<SelectGameTypeEvent>((event, emit) {
      int startN = event.type == GameType.fastTest ? state.fastTestStartingLevel : 3;
      emit(state.copyWith(gameType: event.type, phase: GamePhase.choosingMode, sequenceLength: startN));
    });
    
    on<ModeSelectedEvent>((event, emit) {
      emit(state.copyWith(
        gameMode: event.mode, 
        failsInCurrentSpan: 0, 
        consecutiveSuccesses: 0, 
        consecutiveFailures: 0
      ));

      if (state.gameType == GameType.training) {
        emit(state.copyWith(phase: GamePhase.choosingLevel));
      } else {
        add(PlayNextRoundEvent());
      }
    });
    
    on<ChangeTrainingLevelEvent>((event, emit) {
      int newLevel = max(2, state.sequenceLength + event.change);
      emit(state.copyWith(sequenceLength: newLevel));
    });

    on<ToggleGamificationEvent>((event, emit) {
      _prefs?.setBool('ds_gamification', event.isEnabled);
      emit(state.copyWith(isGamificationEnabled: event.isEnabled));
    });

    on<ChangeSettingsEvent>(_onChangeSettings);
    
    on<PlayNextRoundEvent>(_onPlayNextRound);
    on<NumberPressedEvent>(_onNumberPressed);
    on<BackspacePressedEvent>(_onBackspacePressed);
    on<SaveGameAndExitEvent>(_onSaveGameAndExit);
  }

  static int calculateKci(double span, GameMode mode) {
    double multiplier = 1.0;
    if (mode == GameMode.reverse) multiplier = 1.25;
    if (mode == GameMode.ascending) multiplier = 1.4;
    return (span * multiplier * 10).round();
  }

  Future<void> _safeTtsStop() async {
    try {
      if (kIsWeb || (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)) {
        await _flutterTts.stop();
      }
    } catch (e) {
      debugPrint("TTS Stop Error: $e");
    }
  }

  void _tryVibrate() {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (Env.useHaptics && (_prefs?.getBool('global_is_haptic') ?? true)) {
          Vibration.vibrate(duration: _prefs?.getInt('global_haptic_duration') ?? 300);
        }
      }
    } catch (e) {
      debugPrint("Vibrace selhala: $e");
    }
  }

  void _cancelRound() {
    _roundId++;
    _safeTtsStop();
  }

  Future<void> _onInit(InitializeHardwareEvent event, Emitter<DigitSpanState> emit) async {
    _prefs = await SharedPreferences.getInstance();
    
    final isGami = _prefs?.getBool('ds_gamification') ?? true;
    final startLvl = _prefs?.getInt('ds_fast_start') ?? 3;
    final speedFact = _prefs?.getDouble('ds_speed') ?? 1.0;
    
    int sSettingIndex = _prefs?.getInt('ds_sound') ?? SoundSetting.numbersAndFeedback.index;
    SoundSetting sound = SoundSetting.values[sSettingIndex];

    final rawHistory = _prefs?.getStringList('ds_raw_history') ?? [];
    List<GameResult> history = [];
    Map<GameMode, int> bests = { GameMode.forward: 0, GameMode.reverse: 0, GameMode.ascending: 0 };

    for (var str in rawHistory) {
      try {
        final res = GameResult.fromPrefsString(str);
        history.add(res);
        if (res.isCorrect && res.level > bests[res.mode]!) {
          bests[res.mode] = res.level;
        }
      } catch (e) {
        debugPrint("Chyba čtení historie DS: $e");
      }
    }

    emit(state.copyWith(
      isGamificationEnabled: isGami,
      fastTestStartingLevel: startLvl,
      speedFactor: speedFact,
      soundSetting: sound,
      resultsHistory: history,
      highScores: bests,
    ));
  }

  Future<void> _onSetLanguage(SetLanguageEvent event, Emitter<DigitSpanState> emit) async {
    String ttsLang = "en-US";
    if (event.langCode == 'cs') ttsLang = "cs-CZ";
    else if (event.langCode == 'de') ttsLang = "de-DE";

    try {
      await _flutterTts.setLanguage(ttsLang);
      
      // Zásadní oprava: Záměrně ZAKÁZÁNO pro Windows. Způsobovalo to zpětný callback
      // na špatném vlákně a pád celé aplikace.
      if (kIsWeb || (!Platform.isWindows)) {
        await _flutterTts.awaitSpeakCompletion(true);
      }
    } catch (e) {
      debugPrint("Chyba TTS: $e");
    }
  }

  void _onChangeSettings(ChangeSettingsEvent event, Emitter<DigitSpanState> emit) {
    double newSpeed = event.speed ?? state.speedFactor;
    int newStart = event.fastStartLevel ?? state.fastTestStartingLevel;
    SoundSetting newSound = event.sound ?? state.soundSetting;

    _prefs?.setDouble('ds_speed', newSpeed);
    _prefs?.setInt('ds_fast_start', newStart);
    _prefs?.setInt('ds_sound', newSound.index);

    emit(state.copyWith(speedFactor: newSpeed, fastTestStartingLevel: newStart, soundSetting: newSound));
  }

  void _onReturnToMenu(ReturnToMenuEvent event, Emitter<DigitSpanState> emit) {
    _cancelRound();
    emit(state.copyWith(phase: GamePhase.menu, failsInCurrentSpan: 0, consecutiveSuccesses: 0, consecutiveFailures: 0));
  }

  Future<void> _onPlayNextRound(PlayNextRoundEvent event, Emitter<DigitSpanState> emit) async {
    _roundId++;
    final currentRoundId = _roundId;

    List<int> seq = [];
    for (int i = 0; i < state.sequenceLength; i++) {
      seq.add(_rnd.nextInt(10)); 
    }

    List<int> exp = List.from(seq);
    if (state.gameMode == GameMode.reverse) {
      exp = exp.reversed.toList();
    } else if (state.gameMode == GameMode.ascending) {
      exp.sort();
    }

    emit(state.copyWith(
      phase: GamePhase.showingSequence, 
      currentSequence: seq, 
      expectedSequence: exp, 
      userInput: "", 
      currentlyDisplayedDigit: ""
    ));

    await Future.delayed(const Duration(milliseconds: 800));

    double baseRate = (!kIsWeb && Platform.isWindows) ? 1.0 : 0.5;
    double finalRate = baseRate * state.speedFactor;

    for (int i = 0; i < seq.length; i++) {
      if (_roundId != currentRoundId || isClosed) return;

      String digitStr = seq[i].toString();
      emit(state.copyWith(currentlyDisplayedDigit: digitStr));

      int delayMs = (1000 / state.speedFactor).round();
      int elapsedMs = 0;

      if (state.soundSetting != SoundSetting.off) {
        try {
          await _flutterTts.setSpeechRate(finalRate);
          
          final watch = Stopwatch()..start();
          
          // KLÍČOVÁ OPRAVA: Na Windows voláme asynchronně bez 'await'.
          // Windows nesmí čekat na TTS plugin, ten si hraje zvuk bezpečně na pozadí,
          // zatímco my si řídíme časování čistě přes náš Future.delayed.
          if (!kIsWeb && Platform.isWindows) {
            _flutterTts.speak(digitStr).catchError((e) { debugPrint("TTS Error: $e"); });
            elapsedMs = 0; // Okamžitě pokračujeme k čekání vizuálního časovače
          } else {
            await _flutterTts.speak(digitStr); 
            elapsedMs = watch.elapsedMilliseconds;
          }
          
        } catch (e) {
          debugPrint("TTS Error: $e");
        }
      }

      int remainingDelay = delayMs - elapsedMs;
      if (remainingDelay > 0) {
        await Future.delayed(Duration(milliseconds: remainingDelay));
      }

      if (_roundId != currentRoundId || isClosed) return;
      emit(state.copyWith(currentlyDisplayedDigit: ""));
      
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (_roundId != currentRoundId || isClosed) return;
    emit(state.copyWith(phase: GamePhase.waitingForInput));
  }

  void _onNumberPressed(NumberPressedEvent event, Emitter<DigitSpanState> emit) async {
    if (state.phase != GamePhase.waitingForInput) return;

    String newInput = state.userInput + event.digit.toString();
    emit(state.copyWith(userInput: newInput));

    if (newInput.length == state.expectedSequence.length) {
      bool isCorrect = true;
      for (int i = 0; i < newInput.length; i++) {
        if (int.parse(newInput[i]) != state.expectedSequence[i]) {
          isCorrect = false;
          break;
        }
      }

      _evaluateInput(isCorrect, emit);
    }
  }

  void _onBackspacePressed(BackspacePressedEvent event, Emitter<DigitSpanState> emit) {
    if (state.phase != GamePhase.waitingForInput || state.userInput.isEmpty) return;
    emit(state.copyWith(userInput: state.userInput.substring(0, state.userInput.length - 1)));
  }

  void _evaluateInput(bool isCorrect, Emitter<DigitSpanState> emit) async {
    _roundId++; 
    final int currentLvl = state.sequenceLength;

    if (!isCorrect) {
      _tryVibrate(); 
    }

    if (state.gameType != GameType.training) {
      final res = GameResult(DateTime.now(), isCorrect, state.gameMode, currentLvl);
      final newHistory = List<GameResult>.from(state.resultsHistory)..add(res);
      _prefs?.setStringList('ds_raw_history', newHistory.map((e) => e.toPrefsString()).toList());
      
      Map<GameMode, int> newHighScores = Map.from(state.highScores);
      if (isCorrect && currentLvl > (newHighScores[state.gameMode] ?? 0)) {
        newHighScores[state.gameMode] = currentLvl;
      }
      emit(state.copyWith(resultsHistory: newHistory, highScores: newHighScores));
    }

    if (state.gameType == GameType.fastTest) {
      if (isCorrect) {
        emit(state.copyWith(phase: GamePhase.showingSuccess, failsInCurrentSpan: 0));
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!isClosed) {
          emit(state.copyWith(sequenceLength: currentLvl + 1));
          add(PlayNextRoundEvent());
        }
      } else {
        int newFails = state.failsInCurrentSpan + 1;
        if (newFails >= 3) {
          emit(state.copyWith(phase: GamePhase.gameOver, failsInCurrentSpan: newFails));
        } else {
          emit(state.copyWith(phase: GamePhase.showingFailure, failsInCurrentSpan: newFails));
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!isClosed) add(PlayNextRoundEvent());
        }
      }
    } 
    else if (state.gameType == GameType.gameMode) {
      if (isCorrect) {
        int newConsecutive = state.consecutiveSuccesses + 1;
        emit(state.copyWith(phase: GamePhase.showingSuccess, consecutiveSuccesses: newConsecutive, consecutiveFailures: 0));
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!isClosed) {
          if (newConsecutive >= 2) { 
            emit(state.copyWith(sequenceLength: currentLvl + 1, consecutiveSuccesses: 0));
          }
          add(PlayNextRoundEvent());
        }
      } else {
        int newConsecutiveFails = state.consecutiveFailures + 1;
        if (newConsecutiveFails >= 2) { 
          emit(state.copyWith(phase: GamePhase.gameOver, consecutiveFailures: newConsecutiveFails));
        } else {
          emit(state.copyWith(phase: GamePhase.showingFailure, consecutiveSuccesses: 0, consecutiveFailures: newConsecutiveFails));
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!isClosed) add(PlayNextRoundEvent());
        }
      }
    } 
    else {
      emit(state.copyWith(phase: isCorrect ? GamePhase.showingSuccess : GamePhase.showingFailure));
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!isClosed) add(PlayNextRoundEvent());
    }
  }

  void _onSaveGameAndExit(SaveGameAndExitEvent event, Emitter<DigitSpanState> emit) {
    _cancelRound();
    emit(state.copyWith(phase: GamePhase.showingResults, failsInCurrentSpan: 0, consecutiveSuccesses: 0, consecutiveFailures: 0));
  }

  @override
  Future<void> close() {
    _cancelRound();
    return super.close();
  }
}
