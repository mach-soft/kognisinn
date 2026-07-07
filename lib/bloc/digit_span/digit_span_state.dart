import 'package:equatable/equatable.dart';

enum GameType { fastTest, gameMode, training }

enum GameMode { forward, reverse, ascending }

enum SoundSetting { numbersOnly, numbersAndFeedback, off }

enum GamePhase { splash, menu, choosingMode, choosingLevel, showingSequence, waitingForInput, showingSuccess, showingFailure, gameOver, showingResults, settings }

class GameResult extends Equatable {
  final DateTime timestamp;
  final bool isCorrect;
  final GameMode mode;
  final int level;

  const GameResult(this.timestamp, this.isCorrect, this.mode, this.level);

  // Převod výsledku na text (pro uložení do paměti)
  String toPrefsString() {
    return '${timestamp.toIso8601String()}|$isCorrect|${mode.name}|$level';
  }

  // Převod z textu zpět na objekt (při startu aplikace)
  static GameResult fromPrefsString(String str) {
    try {
      final parts = str.split('|');
      return GameResult(
        DateTime.parse(parts[0]),
        parts[1] == 'true',
        GameMode.values.firstWhere((e) => e.name == parts[2], orElse: () => GameMode.forward),
        int.parse(parts[3]),
      );
    } catch(e) {
      return GameResult(DateTime.now(), false, GameMode.forward, 1); // Záchranná brzda při chybě čtení
    }
  }

  @override
  List<Object?> get props => [timestamp, isCorrect, mode, level];
}

class DigitSpanState extends Equatable {
  final GamePhase phase;
  final GameType gameType;
  final GameMode gameMode;
  final int sequenceLength;
  
  final int consecutiveSuccesses;
  final int consecutiveFailures;
  final int failsInCurrentSpan; 
  
  // Sledování maxima pro aktuální relaci (pro uložení KCI a historie na konci)
  final int maxSpanInCurrentSession;
  
  final bool isEmphaticMode;
  final bool isGamificationEnabled;
  
  final SoundSetting soundSetting;
  final double speedFactor;
  final int fastTestStartingLevel;
  
  final List<GameResult> resultsHistory;
  final List<int> currentSequence;
  final List<int> expectedSequence;
  final String userInput;
  final String currentlyDisplayedDigit;
  final Map<GameMode, int> highScores;

  const DigitSpanState({
    this.phase = GamePhase.splash,
    this.gameType = GameType.fastTest,
    this.gameMode = GameMode.forward,
    this.sequenceLength = 3,
    this.consecutiveSuccesses = 0,
    this.consecutiveFailures = 0,
    this.failsInCurrentSpan = 0,
    this.maxSpanInCurrentSession = 0,
    this.isEmphaticMode = false,
    this.isGamificationEnabled = true,
    this.soundSetting = SoundSetting.numbersAndFeedback,
    this.speedFactor = 1.0,
    this.fastTestStartingLevel = 3,
    this.resultsHistory = const [],
    this.currentSequence = const [],
    this.expectedSequence = const [],
    this.userInput = '',
    this.currentlyDisplayedDigit = '',
    this.highScores = const {},
  });

  DigitSpanState copyWith({
    GamePhase? phase,
    GameType? gameType,
    GameMode? gameMode,
    int? sequenceLength,
    int? consecutiveSuccesses,
    int? consecutiveFailures,
    int? failsInCurrentSpan,
    int? maxSpanInCurrentSession,
    bool? isEmphaticMode,
    bool? isGamificationEnabled,
    SoundSetting? soundSetting,
    double? speedFactor,
    int? fastTestStartingLevel,
    List<GameResult>? resultsHistory,
    List<int>? currentSequence,
    List<int>? expectedSequence,
    String? userInput,
    String? currentlyDisplayedDigit,
    Map<GameMode, int>? highScores,
  }) {
    return DigitSpanState(
      phase: phase ?? this.phase,
      gameType: gameType ?? this.gameType,
      gameMode: gameMode ?? this.gameMode,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      consecutiveSuccesses: consecutiveSuccesses ?? this.consecutiveSuccesses,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      failsInCurrentSpan: failsInCurrentSpan ?? this.failsInCurrentSpan,
      maxSpanInCurrentSession: maxSpanInCurrentSession ?? this.maxSpanInCurrentSession,
      isEmphaticMode: isEmphaticMode ?? this.isEmphaticMode,
      isGamificationEnabled: isGamificationEnabled ?? this.isGamificationEnabled,
      soundSetting: soundSetting ?? this.soundSetting,
      speedFactor: speedFactor ?? this.speedFactor,
      fastTestStartingLevel: fastTestStartingLevel ?? this.fastTestStartingLevel,
      resultsHistory: resultsHistory ?? this.resultsHistory,
      currentSequence: currentSequence ?? this.currentSequence,
      expectedSequence: expectedSequence ?? this.expectedSequence,
      userInput: userInput ?? this.userInput,
      currentlyDisplayedDigit: currentlyDisplayedDigit ?? this.currentlyDisplayedDigit,
      highScores: highScores ?? this.highScores,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        gameType,
        gameMode,
        sequenceLength,
        consecutiveSuccesses,
        consecutiveFailures,
        failsInCurrentSpan,
        maxSpanInCurrentSession,
        isEmphaticMode,
        isGamificationEnabled,
        soundSetting,
        speedFactor,
        fastTestStartingLevel,
        resultsHistory,
        currentSequence,
        expectedSequence,
        userInput,
        currentlyDisplayedDigit,
        highScores,
      ];
}
