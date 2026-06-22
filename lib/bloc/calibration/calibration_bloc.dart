// lib/bloc/calibration/calibration_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calibration_event.dart';
import 'calibration_state.dart';

class CalibrationBloc extends Bloc<CalibrationEvent, CalibrationState> {
  CalibrationBloc() : super(const CalibrationState()) {
    
    on<StartCalibration>((event, emit) {
      emit(state.copyWith(phase: CalibrationPhase.stroop));
    });

    on<SubmitStroopResult>((event, emit) {
      emit(state.copyWith(
        phase: CalibrationPhase.digitSpan,
        stroopAvgTimeMs: event.avgTimeMs,
      ));
    });

    on<SubmitDigitSpanResult>((event, emit) {
      emit(state.copyWith(
        phase: CalibrationPhase.eCorsi,
        digitSpanScore: event.score,
      ));
    });

    on<SubmitECorsiResult>((event, emit) {
      emit(state.copyWith(
        phase: CalibrationPhase.memoryPalace,
        eCorsiScore: event.score,
      ));
    });

    on<SubmitMemoryPalaceResult>((event, emit) {
      emit(state.copyWith(
        phase: CalibrationPhase.dnb,
        memoryPalaceScore: event.score,
      ));
    });

    on<SubmitDnbResult>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      
      // Zde uložíme nasbíraná hrubá data do paměti zařízení, 
      // aby si je později mohl načíst vykreslovač pavučinového grafu.
      await prefs.setDouble('calib_stroop', state.stroopAvgTimeMs);
      await prefs.setInt('calib_digit_span', state.digitSpanScore);
      await prefs.setInt('calib_ecorsi', state.eCorsiScore);
      await prefs.setInt('calib_palace', state.memoryPalaceScore);
      await prefs.setDouble('calib_dnb', event.successRate);

      // Fyzicky odemkneme aplikaci
      await prefs.setBool('global_is_calibrated', true);

      emit(state.copyWith(
        phase: CalibrationPhase.result,
        dnbSuccessRate: event.successRate,
      ));
    });

    on<FinishCalibration>((event, emit) {
      // Tento event se zavolá po odkliknutí finální obrazovky,
      // UI následně přesměruje uživatele zpět do plně odemčeného hlavního menu.
    });
  }
}
