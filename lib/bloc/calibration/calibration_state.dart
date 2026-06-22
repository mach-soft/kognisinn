// lib/bloc/calibration/calibration_state.dart

enum CalibrationPhase {
  intro,        // Úvodní obrazovka s vysvětlením
  stroop,       // Fáze 1: Stroopův test (Rychlost)
  digitSpan,    // Fáze 2: Digit Span (Kapacita PP)
  eCorsi,       // Fáze 3: eCorsi (Vizuoprostorová)
  memoryPalace, // Fáze 4: Paměťový palác (Asociativní)
  dnb,          // Fáze 5: Dual N-Back (Aktualizace)
  result        // Závěrečné vyhodnocení a odemčení KCI
}

class CalibrationState {
  final CalibrationPhase phase;
  
  // Hrubá data z testů
  final double stroopAvgTimeMs;
  final int digitSpanScore;
  final int eCorsiScore;
  final int memoryPalaceScore;
  final double dnbSuccessRate; // 0.0 až 1.0

  const CalibrationState({
    this.phase = CalibrationPhase.intro,
    this.stroopAvgTimeMs = 0.0,
    this.digitSpanScore = 0,
    this.eCorsiScore = 0,
    this.memoryPalaceScore = 0,
    this.dnbSuccessRate = 0.0,
  });

  CalibrationState copyWith({
    CalibrationPhase? phase,
    double? stroopAvgTimeMs,
    int? digitSpanScore,
    int? eCorsiScore,
    int? memoryPalaceScore,
    double? dnbSuccessRate,
  }) {
    return CalibrationState(
      phase: phase ?? this.phase,
      stroopAvgTimeMs: stroopAvgTimeMs ?? this.stroopAvgTimeMs,
      digitSpanScore: digitSpanScore ?? this.digitSpanScore,
      eCorsiScore: eCorsiScore ?? this.eCorsiScore,
      memoryPalaceScore: memoryPalaceScore ?? this.memoryPalaceScore,
      dnbSuccessRate: dnbSuccessRate ?? this.dnbSuccessRate,
    );
  }
}
