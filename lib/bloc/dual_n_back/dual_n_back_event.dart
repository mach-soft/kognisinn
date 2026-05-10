abstract class DualNBackEvent {
  const DualNBackEvent();
}

class InitDualNBack extends DualNBackEvent {}

class SetLanguageEvent extends DualNBackEvent {
  final String langCode;
  const SetLanguageEvent(this.langCode);
}

class ShowPreTraining extends DualNBackEvent {
  final bool adaptive;
  const ShowPreTraining({required this.adaptive});
}

class PauseGame extends DualNBackEvent {}
class ResumeGame extends DualNBackEvent {}

class StartGame extends DualNBackEvent {
  final bool adaptive;
  const StartGame({required this.adaptive});
}

class NextRound extends DualNBackEvent {}

class ShowStimulus extends DualNBackEvent {
  final int pos;
  final int sound;
  const ShowStimulus(this.pos, this.sound);
}

class PositionMatchClicked extends DualNBackEvent {}
class AudioMatchClicked extends DualNBackEvent {}

class ClearPositionError extends DualNBackEvent {}
class ClearAudioError extends DualNBackEvent {}

class ShowSettings extends DualNBackEvent {}

class UpdateSettings extends DualNBackEvent {
  final int? manualN;
  final int? manualSpeedMs;
  final int? adaptationSpeed;
  const UpdateSettings({this.manualN, this.manualSpeedMs, this.adaptationSpeed});
}

class ShowHistory extends DualNBackEvent {}
class ResetDualNBack extends DualNBackEvent {}
