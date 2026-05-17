import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_score_data_source.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockScoreDataSource extends Mock implements SupabaseScoreDataSource {}

void main() {
  late MockScoreDataSource mockDs;
  late ScoreRepositoryImpl repo;

  final userId = UserId('user-uuid-001');
  final testScore = UserScore(
    userId: userId,
    totalPoints: 1500,
    weeklyPoints: 120,
    currentLevel: Level.murid,
    weeklyRank: 3,
  );

  setUp(() {
    mockDs = MockScoreDataSource();
    repo = ScoreRepositoryImpl(mockDs);
    registerFallbackValue(userId);
  });

  group('ScoreRepositoryImpl.getUserScore', () {
    test('délègue au datasource et retourne le UserScore mappé', () async {
      when(
        () => mockDs.getUserScore(userId),
      ).thenAnswer((_) async => testScore);

      final result = await repo.getUserScore(userId);

      expect(result, testScore);
      verify(() => mockDs.getUserScore(userId)).called(1);
    });

    test('traduit PostgrestException en ScoreDatabaseFailure', () async {
      when(
        () => mockDs.getUserScore(userId),
      ).thenThrow(const sb.PostgrestException(message: 'DB error'));

      expect(
        () => repo.getUserScore(userId),
        throwsA(isA<ScoreDatabaseFailure>()),
      );
    });

    test('propage ScoreFailure telle quelle', () async {
      when(
        () => mockDs.getUserScore(userId),
      ).thenThrow(const ScoreFailure.network());

      expect(
        () => repo.getUserScore(userId),
        throwsA(isA<ScoreNetworkFailure>()),
      );
    });

    test('traduit les erreurs inconnues en ScoreUnknownFailure', () async {
      when(
        () => mockDs.getUserScore(userId),
      ).thenThrow(Exception('unexpected error'));

      expect(
        () => repo.getUserScore(userId),
        throwsA(isA<ScoreUnknownFailure>()),
      );
    });
  });

  group('ScoreRepositoryImpl.getLeaderboard', () {
    test('retourne la liste des scores ordonnée', () async {
      final scores = [
        testScore,
        UserScore(
          userId: UserId('user-uuid-002'),
          totalPoints: 1200,
          weeklyPoints: 90,
          currentLevel: Level.aspirant,
          weeklyRank: 5,
        ),
      ];

      when(
        () => mockDs.getLeaderboard(limit: 50),
      ).thenAnswer((_) async => scores);

      final result = await repo.getLeaderboard(limit: 50);

      expect(result, scores);
      verify(() => mockDs.getLeaderboard(limit: 50)).called(1);
    });

    test('traduit PostgrestException en ScoreDatabaseFailure', () async {
      when(
        () => mockDs.getLeaderboard(limit: 50),
      ).thenThrow(const sb.PostgrestException(message: 'DB error'));

      expect(
        () => repo.getLeaderboard(limit: 50),
        throwsA(isA<ScoreDatabaseFailure>()),
      );
    });
  });
}
