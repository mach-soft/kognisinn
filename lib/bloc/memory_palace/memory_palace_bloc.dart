import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart'; // PŘIDÁNO: Nativní vibrace

enum PalacePhase { menu, settings, setup, encoding, recall, success, failure, result, history }

class PalaceHistoryItem {
  final DateTime date;
  final int maxSpan;
  final int score;
  final bool isAdaptive;
  PalaceHistoryItem(this.date, this.maxSpan, this.score, this.isAdaptive);

  String toRawString() => '${date.millisecondsSinceEpoch}|$maxSpan|$score|${isAdaptive ? 1 : 0}';
  static PalaceHistoryItem fromRawString(String raw) {
    final parts = raw.split('|');
    return PalaceHistoryItem(
      DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      int.parse(parts[1]),
      int.parse(parts[2]),
      parts.length > 3 ? parts[3] == '1' : true,
    );
  }
}

class MemoryPalaceState {
  final PalacePhase phase;
  final bool isAdaptive;
  final int defaultAdaptiveSpan;
  final int defaultSpeedMs;
  final int currentSpan;
  final int currentSpeedMs;
  final int lives;
  final int score;
  final List<String> activeLocations;
  final List<String> activeItems;
  final int currentIndex;
  final List<String> currentOptions;
  final List<PalaceHistoryItem> history;

  const MemoryPalaceState({
    this.phase = PalacePhase.menu,
    this.isAdaptive = true,
    this.defaultAdaptiveSpan = 3,
    this.defaultSpeedMs = 3000,
    this.currentSpan = 3,
    this.currentSpeedMs = 3000,
    this.lives = 3,
    this.score = 0,
    this.activeLocations = const [],
    this.activeItems = const [],
    this.currentIndex = -1,
    this.currentOptions = const [],
    this.history = const [],
  });

  MemoryPalaceState copyWith({
    PalacePhase? phase, bool? isAdaptive, int? defaultAdaptiveSpan, int? defaultSpeedMs,
    int? currentSpan, int? currentSpeedMs, int? lives, int? score,
    List<String>? activeLocations, List<String>? activeItems,
    int? currentIndex, List<String>? currentOptions, List<PalaceHistoryItem>? history,
  }) {
    return MemoryPalaceState(
      phase: phase ?? this.phase, isAdaptive: isAdaptive ?? this.isAdaptive,
      defaultAdaptiveSpan: defaultAdaptiveSpan ?? this.defaultAdaptiveSpan,
      defaultSpeedMs: defaultSpeedMs ?? this.defaultSpeedMs,
      currentSpan: currentSpan ?? this.currentSpan,
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      lives: lives ?? this.lives, score: score ?? this.score,
      activeLocations: activeLocations ?? this.activeLocations,
      activeItems: activeItems ?? this.activeItems,
      currentIndex: currentIndex ?? this.currentIndex,
      currentOptions: currentOptions ?? this.currentOptions,
      history: history ?? this.history,
    );
  }
}

abstract class PalaceEvent {}
class InitPalace extends PalaceEvent {}
class StartAdaptive extends PalaceEvent {}
class StartFreeTraining extends PalaceEvent {}
class ShowSetup extends PalaceEvent {}
class ShowSettings extends PalaceEvent {}
class UpdateSettings extends PalaceEvent { final int? span; final int? speedMs; UpdateSettings({this.span, this.speedMs}); }
class UpdateSetup extends PalaceEvent { final int? span; final int? speedMs; UpdateSetup({this.span, this.speedMs}); }
class NextEncodingStep extends PalaceEvent {}
class StartRecall extends PalaceEvent {}
class AnswerSelected extends PalaceEvent { final String selectedItem; AnswerSelected(this.selectedItem); }
class NextRound extends PalaceEvent {}
class ResetPalace extends PalaceEvent {}
class ShowPalaceHistory extends PalaceEvent {}

class MemoryPalaceBloc extends Bloc<PalaceEvent, MemoryPalaceState> {
  final Random _rnd = Random();
  int _processId = 0;
  SharedPreferences? _prefs;

  // NOVÉ: Jediný zdroj pravdy pro výpočet KCI
  static int calculateKci(int rawAssociations) {
    if (rawAssociations <= 0) return 0;
    double score = 0;
    if (rawAssociations <= 10) {
      score = (rawAssociations / 10.0) * 100.0;
    } else {
      score = 100.0 + ((rawAssociations - 10) / 40.0) * 100.0;
    }
    return score.round().clamp(0, 250);
  }


  

    final List<String> _allLocations = [
    'palace_loc_door', 'palace_loc_shoerack', 'palace_loc_mirror', 'palace_loc_couch', 
    'palace_loc_tv', 'palace_loc_coffeetable', 'palace_loc_bookcase', 'palace_loc_diningtable', 
    'palace_loc_fridge', 'palace_loc_stove', 'palace_loc_sink', 'palace_loc_bed', 
    'palace_loc_nightstand', 'palace_loc_wardrobe', 'palace_loc_washbasin', 'palace_loc_bathtub', 
    'palace_loc_desk', 'palace_loc_armchair'
  ];

  final List<String> _allItems = [
    'palace_item_apple', 'palace_item_key', 'palace_item_book', 'palace_item_clock', 
    'palace_item_phone', 'palace_item_lamp', 'palace_item_umbrella', 'palace_item_wallet', 
    'palace_item_glasses', 'palace_item_scissors', 'palace_item_mug', 'palace_item_hammer', 
    'palace_item_ball', 'palace_item_candle', 'palace_item_notebook', 'palace_item_flower', 
    'palace_item_hat', 'palace_item_backpack', 'palace_item_handmirror', 'palace_item_comb', 
    'palace_item_coin', 'palace_item_ring', 'palace_item_cup', 'palace_item_spoon'
  ];

  

  MemoryPalaceBloc() : super(const MemoryPalaceState()) {
    on<InitPalace>(_onInitPalace);
    on<StartAdaptive>((event, emit) {
      emit(state.copyWith(isAdaptive: true, currentSpan: state.defaultAdaptiveSpan, currentSpeedMs: state.defaultSpeedMs, score: 0, lives: 3));
      add(NextRound());
    });
    on<StartFreeTraining>((event, emit) => emit(state.copyWith(phase: PalacePhase.setup, isAdaptive: false, currentSpan: state.defaultAdaptiveSpan, currentSpeedMs: state.defaultSpeedMs, score: 0)));
    on<ShowSetup>((event, emit) => emit(state.copyWith(phase: PalacePhase.setup)));
    on<ShowSettings>((event, emit) => emit(state.copyWith(phase: PalacePhase.settings)));
    
    on<UpdateSettings>((event, emit) {
      final newSpan = event.span ?? state.defaultAdaptiveSpan;
      final newSpeed = event.speedMs ?? state.defaultSpeedMs;
      _prefs?.setInt('palace_def_span', newSpan);
      _prefs?.setInt('palace_def_speed', newSpeed);
      emit(state.copyWith(defaultAdaptiveSpan: newSpan, defaultSpeedMs: newSpeed));
    });

    on<UpdateSetup>((event, emit) {
      emit(state.copyWith(currentSpan: event.span ?? state.currentSpan, currentSpeedMs: event.speedMs ?? state.currentSpeedMs));
    });

    on<NextEncodingStep>((event, emit) => emit(state.copyWith(currentIndex: state.currentIndex + 1)));
    on<StartRecall>(_onStartRecall);
    on<AnswerSelected>(_onAnswerSelected);
    on<NextRound>(_onNextRound);
    on<ResetPalace>((event, emit) {
      _processId++;
      emit(state.copyWith(phase: PalacePhase.menu, score: 0));
    });
    on<ShowPalaceHistory>((event, emit) => emit(state.copyWith(phase: PalacePhase.history)));

    add(InitPalace());
  }

  Future<void> _onInitPalace(InitPalace event, Emitter<MemoryPalaceState> emit) async {
    _prefs = await SharedPreferences.getInstance();
    final span = _prefs?.getInt('palace_def_span') ?? 3;
    final speed = _prefs?.getInt('palace_def_speed') ?? 3000;
    
    final rawHistory = _prefs?.getStringList('palace_history') ?? [];
    final history = rawHistory.map((s) => PalaceHistoryItem.fromRawString(s)).toList();
    
    emit(state.copyWith(defaultAdaptiveSpan: span, defaultSpeedMs: speed, history: history));
  }

  void _onNextRound(NextRound event, Emitter<MemoryPalaceState> emit) {
    _processId++;
    
    List<String> locs = List.from(_allLocations)..shuffle(_rnd);
    List<String> items = List.from(_allItems)..shuffle(_rnd);
    
    final activeLocs = locs.take(state.currentSpan).toList();
    final activeItms = items.take(state.currentSpan).toList();

    emit(state.copyWith(phase: PalacePhase.encoding, activeLocations: activeLocs, activeItems: activeItms, currentIndex: -1));
    _runEncodingSequence();
  }

  Future<void> _runEncodingSequence() async {
    final currentId = _processId;
    await Future.delayed(const Duration(milliseconds: 1500)); 
    if (currentId != _processId) return;

    for (int i = 0; i < state.currentSpan; i++) {
      add(NextEncodingStep()); 
      SystemSound.play(SystemSoundType.click);
      
      await Future.delayed(Duration(milliseconds: state.currentSpeedMs)); 
      if (currentId != _processId) return;
    }
    
    add(StartRecall());
  }

  void _onStartRecall(StartRecall event, Emitter<MemoryPalaceState> emit) {
    HapticFeedback.lightImpact();
    emit(state.copyWith(phase: PalacePhase.recall, currentIndex: 0, currentOptions: _generateOptions(0)));
  }

  List<String> _generateOptions(int index) {
    final correctItem = state.activeItems[index];
    List<String> pool = List.from(_allItems)..remove(correctItem)..shuffle(_rnd);
    List<String> options = pool.take(3).toList()..add(correctItem)..shuffle(_rnd);
    return options;
  }

  // OPRAVENO: Funkce je nyní async
  Future<void> _onAnswerSelected(AnswerSelected event, Emitter<MemoryPalaceState> emit) async {
    if (state.phase != PalacePhase.recall) return;

    final correctItem = state.activeItems[state.currentIndex];

    if (event.selectedItem == correctItem) {
      SystemSound.play(SystemSoundType.click);
      int nextIndex = state.currentIndex + 1;
      int newScore = state.score + 1;

      if (nextIndex >= state.currentSpan) {
        if (state.isAdaptive) {
          emit(state.copyWith(phase: PalacePhase.success, score: newScore, currentSpan: state.currentSpan + 1));
        } else {
          emit(state.copyWith(phase: PalacePhase.success, score: newScore)); 
        }
      } else {
        emit(state.copyWith(currentIndex: nextIndex, score: newScore, currentOptions: _generateOptions(nextIndex)));
      }
    } else {
      // --- HAPTICKÁ ODEZVA PŘI CHYBĚ ---
      final prefs = await SharedPreferences.getInstance();
      bool isHaptic = prefs.getBool('global_is_haptic') ?? true;
      if (isHaptic) {
        int hDuration = prefs.getInt('global_haptic_duration') ?? 500;
        Vibration.vibrate(duration: hDuration);
      }
      // ---------------------------------

      if (state.isAdaptive) {
        int newLives = state.lives - 1;
        if (newLives <= 0) {
          _saveResult(emit);
        } else {
          emit(state.copyWith(phase: PalacePhase.failure, lives: newLives));
        }
      } else {
        emit(state.copyWith(phase: PalacePhase.failure));
      }
    }
  }

        void _saveResult(Emitter<MemoryPalaceState> emit) {
    // 1. Modul si uloží svá surová data pro interní historii (počet asociací, např. 14)
    final newItem = PalaceHistoryItem(DateTime.now(), state.currentSpan, state.score, state.isAdaptive);
    final newHistory = List<PalaceHistoryItem>.from(state.history)..add(newItem);
    _prefs?.setStringList('palace_history', newHistory.map((e) => e.toRawString()).toList());
    
    // 2. Odeslání do Kognitivního profilu
    if (state.isAdaptive && _prefs != null) {
      final nowStr = DateTime.now().toIso8601String();
      
      // VÝPOČET PŘÍMO V MODULU: Profilu odesíláme už jen převedené KCI (např. 110)
      final exportKci = MemoryPalaceBloc.calculateKci(state.score).toDouble(); 
      
      // A: Historie pro Profil
      List<String> historyKCI = _prefs!.getStringList('history_palace') ?? [];
      historyKCI.add(exportKci.toString()); 
      if (historyKCI.length > 50) historyKCI.removeAt(0);
      _prefs!.setStringList('history_palace', historyKCI);
      
      // B: Denní agregát
      final today = nowStr.substring(0, 10); 
      List<String> dailyRaw = _prefs!.getStringList('palace_daily_history') ?? [];
      Map<String, double> dailyMap = {};
      
      for (String entry in dailyRaw) {
        final parts = entry.split('|');
        if (parts.length == 2) dailyMap[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
      }
      
      if (dailyMap.containsKey(today)) {
        if (exportKci > dailyMap[today]!) dailyMap[today] = exportKci;
      } else {
        dailyMap[today] = exportKci;
      }
      
      var sortedKeys = dailyMap.keys.toList()..sort();
      if (sortedKeys.length > 10) sortedKeys = sortedKeys.sublist(sortedKeys.length - 10);
      
      List<String> newDailyList = sortedKeys.map((k) => '$k|${dailyMap[k]}').toList();
      _prefs!.setStringList('palace_daily_history', newDailyList);
      
      // C: Validita dat pro zelené štítky
      _prefs!.setInt('validity_associative', sortedKeys.length);
    }

    emit(state.copyWith(phase: PalacePhase.result, history: newHistory));
  }




  @override
  Future<void> close() {
    _processId++;
    return super.close();
  }
}
