import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class UserScore extends Equatable {
  final UserId userId;
  final int totalPoints;
  final int weeklyPoints;
  final Level currentLevel;
  final int weeklyRank;

  /// Rang de la semaine précédente — null si c'est la première semaine.
  final int? previousWeekRank;

  UserScore({
    required this.userId,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.currentLevel,
    required this.weeklyRank,
    this.previousWeekRank,
  }) {
    if (totalPoints < 0) {
      throw ArgumentError.value(
        totalPoints,
        'totalPoints',
        'totalPoints cannot be negative',
      );
    }
    if (weeklyRank <= 0) {
      throw ArgumentError.value(
        weeklyRank,
        'weeklyRank',
        'weeklyRank must be positive',
      );
    }
  }

  /// Mouvement de rang depuis la semaine précédente.
  /// Positif = montée, négatif = descente, null = première semaine.
  int? get rankMovement {
    if (previousWeekRank == null) return null;
    return previousWeekRank! - weeklyRank;
  }

  @override
  List<Object?> get props => [
    userId,
    totalPoints,
    weeklyPoints,
    currentLevel,
    weeklyRank,
    previousWeekRank,
  ];
}
