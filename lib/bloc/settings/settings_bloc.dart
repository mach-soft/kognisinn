import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isDarkMode;
  final double volume; 
  final bool isMuted;
  final bool isHapticEnabled;
  final int hapticDuration; 
  final bool is24HourFormat;

  const SettingsState({
    this.isDarkMode = false, 
    this.volume = 1.0,
    this.isMuted = false,
    this.isHapticEnabled = true,
    this.hapticDuration = 500, 
    this.is24HourFormat = true, 
  });

  SettingsState copyWith({
    bool? isDarkMode, 
    double? volume, 
    bool? isMuted, 
    bool? isHapticEnabled,
    int? hapticDuration,
    bool? is24HourFormat,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isHapticEnabled: isHapticEnabled ?? this.isHapticEnabled,
      hapticDuration: hapticDuration ?? this.hapticDuration,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
    );
  }
}

abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}
class UpdateTheme extends SettingsEvent { final bool isDark; UpdateTheme(this.isDark); }
class UpdateVolume extends SettingsEvent { final double volume; UpdateVolume(this.volume); }
class ToggleMute extends SettingsEvent { final bool isMuted; ToggleMute(this.isMuted); }
class ToggleHaptic extends SettingsEvent { final bool isHapticEnabled; ToggleHaptic(this.isHapticEnabled); }
class UpdateHapticDuration extends SettingsEvent { final int duration; UpdateHapticDuration(this.duration); } 
class UpdateTimeFormat extends SettingsEvent { final bool is24h; UpdateTimeFormat(this.is24h); }

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  
  // ZMĚNA 1: Přidán pojmenovaný parametr a vložen do inicializace stavu
  SettingsBloc({bool isDarkModeInitial = false}) : super(SettingsState(isDarkMode: isDarkModeInitial)) {
    on<LoadSettings>(_onLoad);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateVolume>(_onUpdateVolume);
    on<ToggleMute>(_onToggleMute);
    on<ToggleHaptic>(_onToggleHaptic);
    on<UpdateHapticDuration>(_onUpdateHapticDuration);
    on<UpdateTimeFormat>(_onUpdateTimeFormat); 

    add(LoadSettings());
  }

  Future<void> _onLoad(LoadSettings event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    emit(state.copyWith(
      // ZMĚNA 2: Jako fallback použijeme aktuální state.isDarkMode, aby se počáteční hodnota zachovala
      isDarkMode: prefs.getBool('global_is_dark') ?? state.isDarkMode, 
      volume: prefs.getDouble('global_volume') ?? 1.0,
      isMuted: prefs.getBool('global_is_muted') ?? false,
      isHapticEnabled: prefs.getBool('global_is_haptic') ?? true,
      hapticDuration: prefs.getInt('global_haptic_duration') ?? 500, 
      is24HourFormat: prefs.getBool('global_is_24h') ?? true,
    ));
  }

  Future<void> _onUpdateTheme(UpdateTheme event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_is_dark', event.isDark);
    emit(state.copyWith(isDarkMode: event.isDark));
  }

  Future<void> _onUpdateVolume(UpdateVolume event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('global_volume', event.volume);
    emit(state.copyWith(volume: event.volume));
  }

  Future<void> _onToggleMute(ToggleMute event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_is_muted', event.isMuted);
    emit(state.copyWith(isMuted: event.isMuted));
  }

  Future<void> _onToggleHaptic(ToggleHaptic event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_is_haptic', event.isHapticEnabled);
    emit(state.copyWith(isHapticEnabled: event.isHapticEnabled));
  }

  Future<void> _onUpdateHapticDuration(UpdateHapticDuration event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('global_haptic_duration', event.duration);
    emit(state.copyWith(hapticDuration: event.duration));
  }

  Future<void> _onUpdateTimeFormat(UpdateTimeFormat event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('global_is_24h', event.is24h);
    emit(state.copyWith(is24HourFormat: event.is24h));
  }
}
