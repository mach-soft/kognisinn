import 'dart:math';

enum CognitiveArea {
  workingMemory,
  visuospatial,
  executiveControl,
  associative,
  speedAttention
}

abstract class CognitiveScorer {
  Map<CognitiveArea, double> get weights;
  double get minThreshold;
  double get maxThreshold;
  bool get isMoreBetter => true;

  double normalizeScore(double rawScore) {
    if (rawScore.isNaN || rawScore.isInfinite) return 0.0;

    double normalized;
    if (isMoreBetter) {
      normalized = ((rawScore - minThreshold) / (maxThreshold - minThreshold)) * 100;
    } else {
      normalized = ((maxThreshold - rawScore) / (maxThreshold - minThreshold)) * 100;
    }
    return max(0.0, min(100.0, normalized));
  }

  Map<CognitiveArea, double> calculateContribution(double rawScore) {
    final double normalized = normalizeScore(rawScore);
    final Map<CognitiveArea, double> contribution = {};
    
    weights.forEach((area, weight) {
      contribution[area] = normalized * weight;
    });
    
    return contribution;
  }
}

// --- DEFINICE JEDNOTLIVÝCH MODULŮ ---

class DualNBackScorer extends CognitiveScorer {
  @override
  Map<CognitiveArea, double> get weights => {
    CognitiveArea.workingMemory: 1.0,
    CognitiveArea.speedAttention: 0.8,
    CognitiveArea.visuospatial: 0.5,
  };
  @override
  double get minThreshold => 1.0; // N=1
  @override
  double get maxThreshold => 9.0; // Fyziologický limit
}

class DigitSpanScorer extends CognitiveScorer {
  @override
  Map<CognitiveArea, double> get weights => {
    CognitiveArea.workingMemory: 1.0,
    CognitiveArea.speedAttention: 0.4,
  };
  @override
  double get minThreshold => 4.0; // Základní paměť
  @override
  double get maxThreshold => 14.0; // Mnemotechnický limit
}

class StroopScorer extends CognitiveScorer {
  @override
  Map<CognitiveArea, double> get weights => {
    CognitiveArea.executiveControl: 1.0,
    CognitiveArea.speedAttention: 1.0,
  };
  @override
  double get minThreshold => 400.0; // ms (Limit reakce)
  @override
  double get maxThreshold => 1200.0; // ms (Pomalá reakce)
  @override
  bool get isMoreBetter => false; // Méně milisekund = více bodů
}

class ECorsiScorer extends CognitiveScorer {
  @override
  Map<CognitiveArea, double> get weights => {
    CognitiveArea.visuospatial: 1.0,
    CognitiveArea.workingMemory: 0.6,
  };
  @override
  double get minThreshold => 3.0; // Základní rozpětí
  @override
  double get maxThreshold => 9.0; // Prostorový limit
}

class MemoryPalaceScorer extends CognitiveScorer {
  @override
  Map<CognitiveArea, double> get weights => {
    CognitiveArea.associative: 1.0,
    CognitiveArea.visuospatial: 0.7,
  };
  @override
  double get minThreshold => 5.0; // Položky
  @override
  double get maxThreshold => 30.0; // Položky v daném časovém limitu
}
