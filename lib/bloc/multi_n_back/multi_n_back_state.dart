enum MultiNBackPhase { menu, preTraining, playing, paused, result, history, settings }

class MultiNBackHistoryItem {
  final DateTime date;
  final int nLevel;
  final int score;
  final bool isAdaptive;
  final int speedMs;
  final bool isVariableSpeed;
  final int modalities;

  MultiNBackHistoryItem(this.date, this.nLevel, this.score, this.isAdaptive, this.speedMs, this.isVariableSpeed, this.modalities);

  String toRawString() {
    return '${date.toIso8601String()}|$nLevel|$score|$isAdaptive|$speedMs|$isVariableSpeed|$modalities';
  }

  static MultiNBackHistoryItem fromRawString(String raw) {
    final parts = raw.split('|');
    return MultiNBackHistoryItem(
      DateTime.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      parts[3] == 'true',
      parts.length > 4 ? int.parse(parts[4]) : 2500, 
      parts.length > 5 ? parts[5] == 'true' : false, 
      parts.length > 6 ? int.parse(parts[6]) : 2,
    );
  }
}

class MultiNBackState {
  final MultiNBackPhase phase;
  final bool isAdaptive;

  // Nastavení
  final int manualN;
  final int manualSpeedMs;
  final int adaptationSpeed;
  final int adaptiveSpeedStepMs;
  final int adaptiveSpeedMinMs;
  final int adaptiveStepCount; // NOVÉ: Celkový počet kroků (včetně VAR)
  final bool adaptiveUseVar;   // NOVÉ: Zapnutí/Vypnutí VAR na konci
  final int dailyGoal;
  final int activeModalities; 

  // Aktuální hra
  final int currentN;
  final int currentSpeedMs;
  final bool isVariableSpeed;
  final int currentModalities; 
  final int currentRound;
  final int totalRounds;
  final int currentSubLevel; // NOVÉ: Sledování pozice v aktuální sekvenci (0 až adaptiveStepCount - 1)
  final int score;
  final int dailyCount;
  final bool hasLeveledUp; 

  // UI Stavy 
  final int activeSquareIndex;
  final int activeColorIndex;
  final int activeShapeIndex;

  // Tlačítka - Kliknutí
  final bool positionMatchClicked;
  final bool audioMatchClicked;
  final bool colorMatchClicked;
  final bool shapeMatchClicked;

  // Tlačítka - Chyby
  final bool isPositionError;
  final bool isAudioError;
  final bool isColorError;
  final bool isShapeError;

  final List<MultiNBackHistoryItem> history;

  const MultiNBackState({
    this.phase = MultiNBackPhase.menu,
    this.isAdaptive = false,
    this.manualN = 2,
    this.manualSpeedMs = 2500,
    this.adaptationSpeed = 1,
    this.adaptiveSpeedStepMs = 400,
    this.adaptiveSpeedMinMs = 1500,
    this.adaptiveStepCount = 3, // Výchozí počet kroků
    this.adaptiveUseVar = true, // Výchozí použití VAR
    this.dailyGoal = 20,
    this.activeModalities = 2, 
    this.currentN = 2,
    this.currentSpeedMs = 2500,
    this.isVariableSpeed = false,
    this.currentModalities = 2,
    this.currentRound = 0,
    this.totalRounds = 20, 
    this.currentSubLevel = 0, // Výchozí sub-level
    this.score = 0,
    this.dailyCount = 0,
    this.hasLeveledUp = false, 
    this.activeSquareIndex = -1,
    this.activeColorIndex = 0,
    this.activeShapeIndex = 0,
    this.positionMatchClicked = false,
    this.audioMatchClicked = false,
    this.colorMatchClicked = false,
    this.shapeMatchClicked = false,
    this.isPositionError = false,
    this.isAudioError = false,
    this.isColorError = false,
    this.isShapeError = false,
    this.history = const [],
  });

  MultiNBackState copyWith({
    MultiNBackPhase? phase,
    bool? isAdaptive,
    int? manualN,
    int? manualSpeedMs,
    int? adaptationSpeed,
    int? adaptiveSpeedStepMs,
    int? adaptiveSpeedMinMs,
    int? adaptiveStepCount, // NOVÉ
    bool? adaptiveUseVar,   // NOVÉ
    int? dailyGoal,
    int? activeModalities,
    int? currentN,
    int? currentSpeedMs,
    bool? isVariableSpeed,
    int? currentModalities,
    int? currentRound,
    int? totalRounds,
    int? currentSubLevel, // NOVÉ
    int? score,
    int? dailyCount,
    bool? hasLeveledUp,
    int? activeSquareIndex,
    int? activeColorIndex,
    int? activeShapeIndex,
    bool? positionMatchClicked,
    bool? audioMatchClicked,
    bool? colorMatchClicked,
    bool? shapeMatchClicked,
    bool? isPositionError,
    bool? isAudioError,
    bool? isColorError,
    bool? isShapeError,
    List<MultiNBackHistoryItem>? history,
  }) {
    return MultiNBackState(
      phase: phase ?? this.phase,
      isAdaptive: isAdaptive ?? this.isAdaptive,
      manualN: manualN ?? this.manualN,
      manualSpeedMs: manualSpeedMs ?? this.manualSpeedMs,
      adaptationSpeed: adaptationSpeed ?? this.adaptationSpeed,
      adaptiveSpeedStepMs: adaptiveSpeedStepMs ?? this.adaptiveSpeedStepMs,
      adaptiveSpeedMinMs: adaptiveSpeedMinMs ?? this.adaptiveSpeedMinMs,
      adaptiveStepCount: adaptiveStepCount ?? this.adaptiveStepCount, // NOVÉ
      adaptiveUseVar: adaptiveUseVar ?? this.adaptiveUseVar,           // NOVÉ
      dailyGoal: dailyGoal ?? this.dailyGoal,
      activeModalities: activeModalities ?? this.activeModalities,
      currentN: currentN ?? this.currentN,
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      isVariableSpeed: isVariableSpeed ?? this.isVariableSpeed,
      currentModalities: currentModalities ?? this.currentModalities,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      currentSubLevel: currentSubLevel ?? this.currentSubLevel,       // NOVÉ
      score: score ?? this.score,
      dailyCount: dailyCount ?? this.dailyCount,
      hasLeveledUp: hasLeveledUp ?? this.hasLeveledUp,
      activeSquareIndex: activeSquareIndex ?? this.activeSquareIndex,
      activeColorIndex: activeColorIndex ?? this.activeColorIndex,
      activeShapeIndex: activeShapeIndex ?? this.activeShapeIndex,
      positionMatchClicked: positionMatchClicked ?? this.positionMatchClicked,
      audioMatchClicked: audioMatchClicked ?? this.audioMatchClicked,
      colorMatchClicked: colorMatchClicked ?? this.colorMatchClicked,
      shapeMatchClicked: shapeMatchClicked ?? this.shapeMatchClicked,
      isPositionError: isPositionError ?? this.isPositionError,
      isAudioError: isAudioError ?? this.isAudioError,
      isColorError: isColorError ?? this.isColorError,
      isShapeError: isShapeError ?? this.isShapeError,
      history: history ?? this.history,
    );
  }
}
