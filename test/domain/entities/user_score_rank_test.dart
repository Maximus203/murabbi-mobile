import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../helpers/test_uuids.dart';

void main() {
  final userId = UserId(kUserIdAlpha);

  group('UserScore.previousWeekRank', () {
    test('defaults to null (première semaine)', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
      );
      expect(score.previousWeekRank, isNull);
    });

    test('can be set to a positive rank', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
        previousWeekRank: 7,
      );
      expect(score.previousWeekRank, 7);
    });

    test('participates in equality', () {
      final a = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
        previousWeekRank: 7,
      );
      final b = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('UserScore.rankMovement', () {
    test('null quand previousWeekRank est null', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
      );
      expect(score.rankMovement, isNull);
    });

    test('positif quand le rang monte (previousWeekRank > weeklyRank)', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
        previousWeekRank: 7,
      );
      expect(score.rankMovement, 2);
    });

    test('négatif quand le rang descend (previousWeekRank < weeklyRank)', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 8,
        previousWeekRank: 5,
      );
      expect(score.rankMovement, -3);
    });

    test('zéro quand le rang est stable', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 500,
        weeklyPoints: 100,
        currentLevel: Level.aspirant,
        weeklyRank: 5,
        previousWeekRank: 5,
      );
      expect(score.rankMovement, 0);
    });
  });
}
