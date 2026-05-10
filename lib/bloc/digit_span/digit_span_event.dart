import 'package:equatable/equatable.dart';
import 'digit_span_state.dart';

abstract class DigitSpanEvent extends Equatable {
  const DigitSpanEvent();

  @override
  List<Object?> get props => [];
}

class InitializeHardwareEvent extends DigitSpanEvent {}
class SplashFinishedEvent extends DigitSpanEvent {}
class ReturnToMenuEvent extends DigitSpanEvent {}
class ShowSettingsEvent extends DigitSpanEvent {}
class ShowResultsEvent extends DigitSpanEvent {}

class SelectGameTypeEvent extends DigitSpanEvent {
  final GameType type;
  const SelectGameTypeEvent(this.type);
  @override
  List<Object?> get props => [type];
}

class ModeSelectedEvent extends DigitSpanEvent {
  final GameMode mode;
  const ModeSelectedEvent(this.mode);
  @override
  List<Object?> get props => [mode];
}

class StartGameEvent extends DigitSpanEvent {
  final GameMode mode;
  final bool loadSave;
  const StartGameEvent(this.mode, this.loadSave);
  @override
  List<Object?> get props => [mode, loadSave];
}

class SaveGameAndExitEvent extends DigitSpanEvent {}

class NumberPressedEvent extends DigitSpanEvent {
  final int digit;
  const NumberPressedEvent(this.digit);
  @override
  List<Object?> get props => [digit];
}

class BackspacePressedEvent extends DigitSpanEvent {}

class ChangeSettingsEvent extends DigitSpanEvent {
  final SoundSetting? sound;
  final double? speed;
  const ChangeSettingsEvent({this.sound, this.speed});
  @override
  List<Object?> get props => [sound, speed];
}

class ChangeTrainingLevelEvent extends DigitSpanEvent {
  final int change;
  const ChangeTrainingLevelEvent(this.change);
  @override
  List<Object?> get props => [change];
}

class PlayNextRoundEvent extends DigitSpanEvent {}
class SetLanguageEvent extends DigitSpanEvent {
  final String langCode;
  const SetLanguageEvent(this.langCode);
}
