import 'package:equatable/equatable.dart';

enum GameType { fastTest, gameMode, training }
enum GameMode { forward, reverse, ascending, nback }
enum SoundSetting { numbersOnly, numbersAndFeedback, off }
enum GamePhase { splash, menu, choosingMode, choosingLevel, showingSequence, waitingForInput, showingSuccess, showingFailure, gameOver, showingResults, settings }

class GameResult extends Equatable {
  final DateTime timestamp;
  final bool isCorrect;
  final GameMode mode;
  final int level;

  const GameResult(this.timestamp, this.isCorrect, this.mode, this.level);

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
  final bool isEmphaticMode;
  final SoundSetting soundSetting;
  final double speedFactor;
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
    this.isEmphaticMode = false,
    this.soundSetting = SoundSetting.numbersAndFeedback,
    this.speedFactor = 1.0,
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
    bool? isEmphaticMode,
    SoundSetting? soundSetting,
    double? speedFactor,
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
      isEmphaticMode: isEmphaticMode ?? this.isEmphaticMode,
      soundSetting: soundSetting ?? this.soundSetting,
      speedFactor: speedFactor ?? this.speedFactor,
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
        phase, gameType, gameMode, sequenceLength, consecutiveSuccesses,
        consecutiveFailures, isEmphaticMode, soundSetting, speedFactor,
        resultsHistory, currentSequence, expectedSequence, userInput,
        currentlyDisplayedDigit, highScores
      ];
}
