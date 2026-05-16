enum DualNBackPhase { menu, preTraining, playing, paused, result, history, settings }

class DualNBackHistoryItem {
  final DateTime date;
  final int nLevel;
  final int score;
  final bool isAdaptive;
  final int speedMs;
  final bool isVariableSpeed;

  DualNBackHistoryItem(this.date, this.nLevel, this.score, this.isAdaptive, this.speedMs, this.isVariableSpeed);

  String toRawString() {
    return '${date.toIso8601String()}|$nLevel|$score|$isAdaptive|$speedMs|$isVariableSpeed';
  }

  static DualNBackHistoryItem fromRawString(String raw) {
    final parts = raw.split('|');
    return DualNBackHistoryItem(
      DateTime.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      parts[3] == 'true',
      parts.length > 4 ? int.parse(parts[4]) : 2500, 
      parts.length > 5 ? parts[5] == 'true' : false, 
    );
  }
}

class DualNBackState {
  final DualNBackPhase phase;
  final bool isAdaptive;

  // Nastavení
  final int manualN;
  final int manualSpeedMs;
  final int adaptationSpeed;
  final int dailyGoal;

  // Aktuální hra
  final int currentN;
  final int currentSpeedMs;
  final bool isVariableSpeed;
  final int currentRound;
  final int totalRounds;
  final int score;
  final int dailyCount;
  
  // NOVÉ: Indikátor zvýšení obtížnosti
  final bool hasLeveledUp; 

  // UI Stavy
  final int activeSquareIndex;
  final bool positionMatchClicked;
  final bool audioMatchClicked;
  final bool isPositionError;
  final bool isAudioError;

  final List<DualNBackHistoryItem> history;

  const DualNBackState({
    this.phase = DualNBackPhase.menu,
    this.isAdaptive = false,
    this.manualN = 2,
    this.manualSpeedMs = 2500,
    this.adaptationSpeed = 1,
    this.dailyGoal = 20,
    this.currentN = 2,
    this.currentSpeedMs = 2500,
    this.isVariableSpeed = false,
    this.currentRound = 0,
    this.totalRounds = 20, 
    this.score = 0,
    this.dailyCount = 0,
    this.hasLeveledUp = false, // Výchozí stav
    this.activeSquareIndex = -1,
    this.positionMatchClicked = false,
    this.audioMatchClicked = false,
    this.isPositionError = false,
    this.isAudioError = false,
    this.history = const [],
  });

  DualNBackState copyWith({
    DualNBackPhase? phase,
    bool? isAdaptive,
    int? manualN,
    int? manualSpeedMs,
    int? adaptationSpeed,
    int? dailyGoal,
    int? currentN,
    int? currentSpeedMs,
    bool? isVariableSpeed,
    int? currentRound,
    int? totalRounds,
    int? score,
    int? dailyCount,
    bool? hasLeveledUp,
    int? activeSquareIndex,
    bool? positionMatchClicked,
    bool? audioMatchClicked,
    bool? isPositionError,
    bool? isAudioError,
    List<DualNBackHistoryItem>? history,
  }) {
    return DualNBackState(
      phase: phase ?? this.phase,
      isAdaptive: isAdaptive ?? this.isAdaptive,
      manualN: manualN ?? this.manualN,
      manualSpeedMs: manualSpeedMs ?? this.manualSpeedMs,
      adaptationSpeed: adaptationSpeed ?? this.adaptationSpeed,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      currentN: currentN ?? this.currentN,
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      isVariableSpeed: isVariableSpeed ?? this.isVariableSpeed,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      score: score ?? this.score,
      dailyCount: dailyCount ?? this.dailyCount,
      hasLeveledUp: hasLeveledUp ?? this.hasLeveledUp,
      activeSquareIndex: activeSquareIndex ?? this.activeSquareIndex,
      positionMatchClicked: positionMatchClicked ?? this.positionMatchClicked,
      audioMatchClicked: audioMatchClicked ?? this.audioMatchClicked,
      isPositionError: isPositionError ?? this.isPositionError,
      isAudioError: isAudioError ?? this.isAudioError,
      history: history ?? this.history,
    );
  }
}
