import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:kognisinn/env.dart';


enum PalacePhase { menu, settings, setup, encoding, recall, success, failure, result, history }

class PalaceHistoryItem {
  final DateTime date;
  final int maxSpan;
  final int score;
  final bool isAdaptive;
  
  // Nové proměnné pro zpětnou kompatibilitu
  final int itemsPerLocation;
  final bool randomizeLocations;
  final bool randomizeItems;

  PalaceHistoryItem(
    this.date, 
    this.maxSpan, 
    this.score, 
    this.isAdaptive, 
    this.itemsPerLocation, 
    this.randomizeLocations, 
    this.randomizeItems
  );

  String toRawString() => '${date.millisecondsSinceEpoch}|$maxSpan|$score|${isAdaptive ? 1 : 0}|$itemsPerLocation|${randomizeLocations ? 1 : 0}|${randomizeItems ? 1 : 0}';
  
  static PalaceHistoryItem fromRawString(String raw) {
    final parts = raw.split('|');
    return PalaceHistoryItem(
      DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      int.parse(parts[1]),
      int.parse(parts[2]),
      parts.length > 3 ? parts[3] == '1' : true,
      
      // Zpětná kompatibilita: Pokud chybí, dosadí se původní základní hodnoty
      parts.length > 4 ? int.parse(parts[4]) : 1,
      parts.length > 5 ? parts[5] == '1' : false,
      parts.length > 6 ? parts[6] == '1' : false,
    );
  }
}

class MemoryPalaceState {
  final PalacePhase phase;
  final bool isAdaptive;
  final int defaultAdaptiveSpan;
  final int defaultSpeedMs;
  
  // Nová nastavení
  final int itemsPerLocation;
  final bool randomizeLocations;
  final bool randomizeItems;

  final int currentSpan;
  final int currentSpeedMs;
  final int lives;
  final int score;
  final List<String> activeLocations;
  final List<String> activeItems;
  final List<int> recallQueue; // Fronta pro pořadí vybavování
  final int currentIndex;
  final List<String> currentOptions;
  final List<PalaceHistoryItem> history;

  const MemoryPalaceState({
    this.phase = PalacePhase.menu,
    this.isAdaptive = true,
    this.defaultAdaptiveSpan = 3,
    this.defaultSpeedMs = 3000,
    this.itemsPerLocation = 1,
    this.randomizeLocations = false,
    this.randomizeItems = false,
    this.currentSpan = 3,
    this.currentSpeedMs = 3000,
    this.lives = 3,
    this.score = 0,
    this.activeLocations = const [],
    this.activeItems = const [],
    this.recallQueue = const [],
    this.currentIndex = -1,
    this.currentOptions = const [],
    this.history = const [],
  });

  MemoryPalaceState copyWith({
    PalacePhase? phase, bool? isAdaptive, int? defaultAdaptiveSpan, int? defaultSpeedMs,
    int? itemsPerLocation, bool? randomizeLocations, bool? randomizeItems,
    int? currentSpan, int? currentSpeedMs, int? lives, int? score,
    List<String>? activeLocations, List<String>? activeItems, List<int>? recallQueue,
    int? currentIndex, List<String>? currentOptions, List<PalaceHistoryItem>? history,
  }) {
    return MemoryPalaceState(
      phase: phase ?? this.phase, isAdaptive: isAdaptive ?? this.isAdaptive,
      defaultAdaptiveSpan: defaultAdaptiveSpan ?? this.defaultAdaptiveSpan,
      defaultSpeedMs: defaultSpeedMs ?? this.defaultSpeedMs,
      itemsPerLocation: itemsPerLocation ?? this.itemsPerLocation,
      randomizeLocations: randomizeLocations ?? this.randomizeLocations,
      randomizeItems: randomizeItems ?? this.randomizeItems,
      currentSpan: currentSpan ?? this.currentSpan,
      currentSpeedMs: currentSpeedMs ?? this.currentSpeedMs,
      lives: lives ?? this.lives, score: score ?? this.score,
      activeLocations: activeLocations ?? this.activeLocations,
      activeItems: activeItems ?? this.activeItems,
      recallQueue: recallQueue ?? this.recallQueue,
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
class UpdateSettings extends PalaceEvent { 
  final int? span; final int? speedMs; final int? itemsPerLoc; final bool? randLocs; final bool? randItems; 
  UpdateSettings({this.span, this.speedMs, this.itemsPerLoc, this.randLocs, this.randItems}); 
}
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

  // Upravený výpočet KCI zohledňující modifikátory obtížnosti
  static int calculateKci(int rawAssociations, int itemsPerLoc, bool randLocs, bool randItems) {
    if (rawAssociations <= 0) return 0;
    
    double modifier = 1.0;
    if (itemsPerLoc > 1) modifier += (itemsPerLoc - 1) * 0.10; // +10% za každý předmět navíc
    if (randLocs) modifier += 0.20; // +20% za zničenou prostorovou strukturu paláce
    if (itemsPerLoc > 1 && randItems) modifier += 0.15; // +15% za zpřeházené pořadí na stole

    double effectiveAssociations = rawAssociations * modifier;
    
    double score = 0;
    if (effectiveAssociations <= 10) {
      score = (effectiveAssociations / 10.0) * 100.0;
    } else {
      score = 100.0 + ((effectiveAssociations - 10) / 40.0) * 100.0;
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
      final newItemsPerLoc = event.itemsPerLoc ?? state.itemsPerLocation;
      final newRandLocs = event.randLocs ?? state.randomizeLocations;
      final newRandItems = event.randItems ?? state.randomizeItems;

      _prefs?.setInt('palace_def_span', newSpan);
      _prefs?.setInt('palace_def_speed', newSpeed);
      _prefs?.setInt('palace_def_items_loc', newItemsPerLoc);
      _prefs?.setBool('palace_def_rand_locs', newRandLocs);
      _prefs?.setBool('palace_def_rand_items', newRandItems);

      emit(state.copyWith(
        defaultAdaptiveSpan: newSpan, defaultSpeedMs: newSpeed,
        itemsPerLocation: newItemsPerLoc, randomizeLocations: newRandLocs, randomizeItems: newRandItems
      ));
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
    final itemsLoc = _prefs?.getInt('palace_def_items_loc') ?? 1;
    final randLocs = _prefs?.getBool('palace_def_rand_locs') ?? false;
    final randItems = _prefs?.getBool('palace_def_rand_items') ?? false;
    
    final rawHistory = _prefs?.getStringList('palace_history') ?? [];
    final history = rawHistory.map((s) => PalaceHistoryItem.fromRawString(s)).toList();
    
    emit(state.copyWith(
      defaultAdaptiveSpan: span, defaultSpeedMs: speed,
      itemsPerLocation: itemsLoc, randomizeLocations: randLocs, randomizeItems: randItems,
      history: history
    ));
  }

  List<String> _generateUniqueList(List<String> source, int count) {
    List<String> result = [];
    List<String> pool = List.from(source)..shuffle(_rnd);
    for (int i = 0; i < count; i++) {
      if (pool.isEmpty) pool = List.from(source)..shuffle(_rnd);
      result.add(pool.removeLast());
    }
    return result;
  }

  void _onNextRound(NextRound event, Emitter<MemoryPalaceState> emit) {
    _processId++;
    
    final activeLocs = _generateUniqueList(_allLocations, state.currentSpan);
    final activeItms = _generateUniqueList(_allItems, state.currentSpan * state.itemsPerLocation);

    emit(state.copyWith(
      phase: PalacePhase.encoding, 
      activeLocations: activeLocs, 
      activeItems: activeItms, 
      currentIndex: -1
    ));
    _runEncodingSequence();
  }

  Future<void> _runEncodingSequence() async {
    final currentId = _processId;
    await Future.delayed(const Duration(milliseconds: 1500)); 
    if (currentId != _processId) return;

    int totalItems = state.currentSpan * state.itemsPerLocation;
    for (int i = 0; i < totalItems; i++) {
      add(NextEncodingStep()); 
      SystemSound.play(SystemSoundType.click);
      
      await Future.delayed(Duration(milliseconds: state.currentSpeedMs)); 
      if (currentId != _processId) return;
    }
    
    add(StartRecall());
  }

    void _onStartRecall(StartRecall event, Emitter<MemoryPalaceState> emit) {
    if (Env.useHaptics) HapticFeedback.lightImpact(); // OPRAVA PRO WINDOWS
    
    List<int> queue = [];
    List<List<int>> chunks = [];
    
    for (int i = 0; i < state.currentSpan; i++) {
      List<int> chunk = [];
      for (int j = 0; j < state.itemsPerLocation; j++) {
        chunk.add(i * state.itemsPerLocation + j);
      }
      if (state.randomizeItems) chunk.shuffle(_rnd);
      chunks.add(chunk);
    }
    
    if (state.randomizeLocations) chunks.shuffle(_rnd);
    
    for (var chunk in chunks) {
      queue.addAll(chunk);
    }

    emit(state.copyWith(phase: PalacePhase.recall, recallQueue: queue, currentIndex: 0, currentOptions: _generateOptions(0, queue)));
  }

    List<String> _generateOptions(int index, List<int> queue) {
    int targetItemIndex = queue[index];
    final correctItem = state.activeItems[targetItemIndex];
    List<String> pool = List.from(_allItems)..remove(correctItem)..shuffle(_rnd);
    List<String> options = pool.take(3).toList()..add(correctItem)..shuffle(_rnd);
    return options;
  }

  Future<void> _onAnswerSelected(AnswerSelected event, Emitter<MemoryPalaceState> emit) async {
    if (state.phase != PalacePhase.recall) return;

    int targetItemIndex = state.recallQueue[state.currentIndex];
    final correctItem = state.activeItems[targetItemIndex];

    if (event.selectedItem == correctItem) {
      SystemSound.play(SystemSoundType.click);
      int nextIndex = state.currentIndex + 1;
      int newScore = state.score + 1;
      int totalItems = state.currentSpan * state.itemsPerLocation;

      if (nextIndex >= totalItems) {
        if (state.isAdaptive) {
          emit(state.copyWith(phase: PalacePhase.success, score: newScore, currentSpan: state.currentSpan + 1));
        } else {
          emit(state.copyWith(phase: PalacePhase.success, score: newScore)); 
        }
      } else {
        emit(state.copyWith(currentIndex: nextIndex, score: newScore, currentOptions: _generateOptions(nextIndex, state.recallQueue)));
      }
    } else {
      // --- OPRAVA HAPTIKY PRO WINDOWS ---
      if (Env.useHaptics) {
        final prefs = await SharedPreferences.getInstance();
        bool isHaptic = prefs.getBool('global_is_haptic') ?? true;
        if (isHaptic) {
          int hDuration = prefs.getInt('global_haptic_duration') ?? 500;
          Vibration.vibrate(duration: hDuration);
        }
      }

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
    final newItem = PalaceHistoryItem(
      DateTime.now(), state.currentSpan, state.score, state.isAdaptive,
      state.itemsPerLocation, state.randomizeLocations, state.randomizeItems
    );
    final newHistory = List<PalaceHistoryItem>.from(state.history)..add(newItem);
    _prefs?.setStringList('palace_history', newHistory.map((e) => e.toRawString()).toList());
    
    if (state.isAdaptive && _prefs != null) {
      final nowStr = DateTime.now().toIso8601String();
      
      final exportKci = calculateKci(state.score, state.itemsPerLocation, state.randomizeLocations, state.randomizeItems).toDouble(); 
      
      List<String> historyKCI = _prefs!.getStringList('history_palace') ?? [];
      historyKCI.add(exportKci.toString()); 
      if (historyKCI.length > 50) historyKCI.removeAt(0);
      _prefs!.setStringList('history_palace', historyKCI);
      
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
