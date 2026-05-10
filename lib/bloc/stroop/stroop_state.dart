import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum StroopPhase { menu, playing, result, history }
enum StroopGameType { standard, reverse, trueFalse }

class StroopHistoryItem extends Equatable {
  final DateTime date;
  final int score;
  final int total;
  final double medianReactionTime;
  final StroopGameType gameType; // Nový parametr

  const StroopHistoryItem(this.date, this.score, this.total, this.medianReactionTime, this.gameType);

  @override
  List<Object?> get props => [date, score, total, medianReactionTime, gameType];

  String toRawString() => "${date.millisecondsSinceEpoch}|$score|$total|$medianReactionTime|${gameType.index}";
  
  static StroopHistoryItem fromRawString(String raw) {
    final parts = raw.split('|');
    // Pokud je to starý formát uložení bez typu hry, hodí se to do standardního (index 0)
    final typeIndex = parts.length > 4 ? int.parse(parts[4]) : 0; 
    return StroopHistoryItem(
      DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      int.parse(parts[1]),
      int.parse(parts[2]),
      double.parse(parts[3]),
      StroopGameType.values[typeIndex],
    );
  }
}

class StroopState extends Equatable {
  final StroopPhase phase;
  final StroopGameType activeGameType;
  final String currentWord;
  final Color currentInkColor;
  final List<String> options; // Nyní ukládáme textové odpovědi
  final String correctAnswer; // Správná textová odpověď
  final int score;
  final int totalRounds;
  final int currentRound;
  final List<StroopHistoryItem> history;
  final List<int> currentReactionTimesMs;

  const StroopState({
    this.phase = StroopPhase.menu,
    this.activeGameType = StroopGameType.standard,
    this.currentWord = '',
    this.currentInkColor = Colors.white,
    this.options = const [],
    this.correctAnswer = '',
    this.score = 0,
    this.totalRounds = 20, // Jednotná délka 20 kol
    this.currentRound = 0,
    this.history = const [],
    this.currentReactionTimesMs = const [],
  });

  // Výpočet mediánu pouze pro konkrétní typ hry
  double last5Median(StroopGameType type) {
    final filtered = history.where((e) => e.gameType == type).toList();
    if (filtered.isEmpty) return 0.0;
    final last5 = filtered.reversed.take(5).map((e) => e.medianReactionTime).toList();
    last5.sort();
    int mid = last5.length ~/ 2;
    return last5.length % 2 != 0 ? last5[mid] : (last5[mid - 1] + last5[mid]) / 2;
  }

  StroopState copyWith({
    StroopPhase? phase, StroopGameType? activeGameType, String? currentWord, Color? currentInkColor,
    List<String>? options, String? correctAnswer, int? score, int? totalRounds, int? currentRound,
    List<StroopHistoryItem>? history, List<int>? currentReactionTimesMs,
  }) {
    return StroopState(
      phase: phase ?? this.phase, activeGameType: activeGameType ?? this.activeGameType,
      currentWord: currentWord ?? this.currentWord, currentInkColor: currentInkColor ?? this.currentInkColor,
      options: options ?? this.options, correctAnswer: correctAnswer ?? this.correctAnswer,
      score: score ?? this.score, totalRounds: totalRounds ?? this.totalRounds,
      currentRound: currentRound ?? this.currentRound, history: history ?? this.history,
      currentReactionTimesMs: currentReactionTimesMs ?? this.currentReactionTimesMs,
    );
  }

  @override
  List<Object?> get props => [phase, activeGameType, currentWord, currentInkColor, options, correctAnswer, score, totalRounds, currentRound, history, currentReactionTimesMs];
}
