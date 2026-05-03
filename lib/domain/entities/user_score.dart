import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class UserScore extends Equatable {
  final UserId userId;
  final int totalPoints;
  final int weeklyPoints;
  final Level currentLevel;
  final int weeklyRank;

  UserScore({
    required this.userId,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.currentLevel,
    required this.weeklyRank,
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

  @override
  List<Object?> get props => [
    userId,
    totalPoints,
    weeklyPoints,
    currentLevel,
    weeklyRank,
  ];
}
