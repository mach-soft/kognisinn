// lib/bloc/calibration/calibration_event.dart

abstract class CalibrationEvent {
  const CalibrationEvent();
}

class StartCalibration extends CalibrationEvent {}

class SubmitStroopResult extends CalibrationEvent {
  final double avgTimeMs;
  const SubmitStroopResult(this.avgTimeMs);
}

class SubmitDigitSpanResult extends CalibrationEvent {
  final int score;
  const SubmitDigitSpanResult(this.score);
}

class SubmitECorsiResult extends CalibrationEvent {
  final int score;
  const SubmitECorsiResult(this.score);
}

class SubmitMemoryPalaceResult extends CalibrationEvent {
  final int score;
  const SubmitMemoryPalaceResult(this.score);
}

class SubmitDnbResult extends CalibrationEvent {
  final double successRate;
  const SubmitDnbResult(this.successRate);
}

class FinishCalibration extends CalibrationEvent {}
