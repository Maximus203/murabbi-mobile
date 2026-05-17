import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

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
      when(() => ds.getUserScore('u-1')).thenAnswer(
        (_) async => {
          'user_id': 'u-1',
          'total_points': 30000,
          'weekly_score': 90,
          'rank': 2,
        },
      );

      final score = await repo.getUserScore(UserId('u-1'));

      expect(score.totalPoints, 30000);
      expect(score.currentLevel, Level.salik);
      expect(score.weeklyRank, 2);
    });
  });

  group('getLeaderboard', () {
    test('transmet le limit et mappe les rows triées', () async {
      when(() => ds.getLeaderboard(limit: 20)).thenAnswer(
        (_) async => [
          {
            'user_id': 'u-1',
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
