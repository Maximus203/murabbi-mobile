import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Tests du getter [UserScore.rankMovement] et du champ [previousWeekRank]
/// (issue #6, Phase 5 — Q-F Option A : `user_scores.previous_week_rank`).
void main() {
  UserScore makeScore({int weeklyRank = 5, int? previousWeekRank}) {
    return UserScore(
      userId: UserId('u-1'),
      totalPoints: 1000,
      weeklyPoints: 100,
      currentLevel: Level.aspirant,
      weeklyRank: weeklyRank,
      previousWeekRank: previousWeekRank,
    );
  }

  group('UserScore.rankMovement', () {
    test('null quand previousWeekRank est absent', () {
      expect(makeScore().rankMovement, isNull);
    });

    test('positif quand rang a progressé (ex. 8 → 5 = +3)', () {
      // previousWeekRank=8, weeklyRank=5 → 8-5=3 (monté de 3 places)
      expect(makeScore(weeklyRank: 5, previousWeekRank: 8).rankMovement, 3);
    });

    test('négatif quand rang a regressé (ex. 3 → 7 = -4)', () {
      // previousWeekRank=3, weeklyRank=7 → 3-7=-4 (descendu de 4 places)
      expect(makeScore(weeklyRank: 7, previousWeekRank: 3).rankMovement, -4);
    });

    test('zéro quand rang identique', () {
      expect(makeScore(weeklyRank: 4, previousWeekRank: 4).rankMovement, 0);
    });
  });
}
