import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../helpers/test_uuids.dart';

class MockScoreDataSource extends Mock implements ScoreDataSource {}

void main() {
  late MockScoreDataSource ds;
  late ScoreRepositoryImpl repo;

  setUp(() {
    ds = MockScoreDataSource();
    repo = ScoreRepositoryImpl(ds);
  });

  group('getUserScore', () {
    test('mappe la row datasource en UserScore avec niveau dérivé', () async {
      when(() => ds.getUserScore(kUserIdAlpha)).thenAnswer(
        (_) async => {
          'user_id': kUserIdAlpha,
          'total_points': 30000,
          'weekly_score': 90,
          'rank': 2,
        },
      );

      final score = await repo.getUserScore(UserId(kUserIdAlpha));

      expect(score.totalPoints, 30000);
      expect(score.currentLevel, Level.salik);
      expect(score.weeklyRank, 2);
    });

    // Q-F — previous_week_rank propagé depuis la datasource jusqu'au domaine.
    test('previousWeekRank propagé depuis la row datasource', () async {
      when(() => ds.getUserScore(kUserIdAlpha)).thenAnswer(
        (_) async => {
          'user_id': kUserIdAlpha,
          'total_points': 5000,
          'weekly_score': 100,
          'rank': 3,
          'previous_week_rank': 6,
        },
      );

      final score = await repo.getUserScore(UserId(kUserIdAlpha));

      expect(score.previousWeekRank, 6);
      expect(score.rankMovement, 3); // 6 - 3 = monté de 3 places
    });

    test('previousWeekRank null → rankMovement null (première semaine)', () async {
      when(() => ds.getUserScore(kUserIdAlpha)).thenAnswer(
        (_) async => {
          'user_id': kUserIdAlpha,
          'total_points': 0,
          'weekly_score': 0,
          'rank': 1,
          // pas de clé 'previous_week_rank' — simule première semaine
        },
      );

      final score = await repo.getUserScore(UserId(kUserIdAlpha));

      expect(score.previousWeekRank, isNull);
      expect(score.rankMovement, isNull);
    });

    test('rankMovement négatif si régression de rang', () async {
      when(() => ds.getUserScore(kUserIdAlpha)).thenAnswer(
        (_) async => {
          'user_id': kUserIdAlpha,
          'total_points': 1000,
          'weekly_score': 20,
          'rank': 8,
          'previous_week_rank': 5,
        },
      );

      final score = await repo.getUserScore(UserId(kUserIdAlpha));

      // 5 - 8 = -3 → redescendu de 3 places
      expect(score.rankMovement, -3);
    });
  });

  group('getLeaderboard', () {
    test('transmet le limit et mappe les rows triées', () async {
      when(() => ds.getLeaderboard(limit: 20)).thenAnswer(
        (_) async => [
          {
            'user_id': kUserIdAlpha,
            'total_points': 100,
            'weekly_score': 50,
            'rank': 1,
          },
          {'user_id': 'u-2', 'total_points': 80, 'weekly_score': 40, 'rank': 2},
        ],
      );

      final result = await repo.getLeaderboard(limit: 20);

      expect(result, hasLength(2));
      expect(result.first.weeklyRank, 1);
      verify(() => ds.getLeaderboard(limit: 20)).called(1);
    });
  });
}
