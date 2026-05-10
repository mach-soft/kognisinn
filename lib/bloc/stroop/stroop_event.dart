import 'package:equatable/equatable.dart';
import 'stroop_state.dart';

abstract class StroopEvent extends Equatable {
  const StroopEvent();
  @override
  List<Object?> get props => [];
}

class StartStroopGame extends StroopEvent {
  final StroopGameType gameType;
  const StartStroopGame({required this.gameType});
}

class AnswerSelected extends StroopEvent {
  final String answer; 
  const AnswerSelected(this.answer);
}

class ResetStroop extends StroopEvent {}
class ShowStroopHistory extends StroopEvent {}
