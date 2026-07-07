abstract class MultiNBackEvent {
  const MultiNBackEvent();
}

class InitMultiNBack extends MultiNBackEvent {}

class SetLanguageEvent extends MultiNBackEvent {
  final String langCode;
  const SetLanguageEvent(this.langCode);
}

class ShowPreTraining extends MultiNBackEvent {
  final bool adaptive;
  const ShowPreTraining({required this.adaptive});
}

class PauseGame extends MultiNBackEvent {}
class ResumeGame extends MultiNBackEvent {}

class StartGame extends MultiNBackEvent {
  final bool adaptive;
  const StartGame({required this.adaptive});
}

class NextRound extends MultiNBackEvent {}

class ShowStimulus extends MultiNBackEvent {
  final int pos;
  final int sound;
  final int color;
  final int shape;
  const ShowStimulus(this.pos, this.sound, this.color, this.shape);
}

class PositionMatchClicked extends MultiNBackEvent {}
class AudioMatchClicked extends MultiNBackEvent {}
class ColorMatchClicked extends MultiNBackEvent {}
class ShapeMatchClicked extends MultiNBackEvent {}

class ClearPositionError extends MultiNBackEvent {}
class ClearAudioError extends MultiNBackEvent {}
class ClearColorError extends MultiNBackEvent {}
class ClearShapeError extends MultiNBackEvent {}

class ShowSettings extends MultiNBackEvent {}

class UpdateSettings extends MultiNBackEvent {
  final int? manualN;
  final int? manualSpeedMs;
  final int? adaptationSpeed;
  final int? adaptiveSpeedStepMs; 
  final int? adaptiveSpeedMinMs; // PŘIDÁNO: Minimální čas
  final int? adaptiveStepCount;  // PŘIDÁNO: Počet kroků
  final bool? adaptiveUseVar;    // PŘIDÁNO: Použití VAR na konci
  final int? activeModalities;
  
  const UpdateSettings({
    this.manualN, 
    this.manualSpeedMs, 
    this.adaptationSpeed, 
    this.adaptiveSpeedStepMs,
    this.adaptiveSpeedMinMs,     // PŘIDÁNO
    this.adaptiveStepCount,      // PŘIDÁNO
    this.adaptiveUseVar,         // PŘIDÁNO
    this.activeModalities
  });
}

class ShowHistory extends MultiNBackEvent {}
class ResetMultiNBack extends MultiNBackEvent {}

class LoadDailyProgressEvent extends MultiNBackEvent {}

class UpdateDailyGoalEvent extends MultiNBackEvent {
  final int newGoal;
  const UpdateDailyGoalEvent(this.newGoal);
}
