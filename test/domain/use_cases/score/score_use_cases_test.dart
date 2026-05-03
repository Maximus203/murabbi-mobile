import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_leaderboard_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_user_score_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockScoreRepository extends Mock implements ScoreRepository {}

void main() {
  late MockScoreRepository mockRepo;
  final userId = UserId('user-uuid-001');

  final testScore = UserScore(
    userId: userId,
    totalPoints: 1500,
    weeklyPoints: 120,
    currentLevel: Level.murid,
    weeklyRank: 3,
  );

  setUp(() {
    mockRepo = MockScoreRepository();
  });

  group('GetUserScoreUseCase', () {
    late GetUserScoreUseCase useCase;

    setUp(() => useCase = GetUserScoreUseCase(mockRepo));

    test('calls repository.getUserScore and returns score', () async {
      when(
        () => mockRepo.getUserScore(userId),
      ).thenAnswer((_) async => testScore);

      final result = await useCase(userId);

      expect(result, testScore);
      verify(() => mockRepo.getUserScore(userId)).called(1);
    });
  });

  group('GetLeaderboardUseCase', () {
    late GetLeaderboardUseCase useCase;

    setUp(() => useCase = GetLeaderboardUseCase(mockRepo));

    test('calls repository.getLeaderboard and returns list', () async {
      when(
        () => mockRepo.getLeaderboard(limit: 20),
      ).thenAnswer((_) async => [testScore]);

      final result = await useCase(limit: 20);

      expect(result, [testScore]);
      verify(() => mockRepo.getLeaderboard(limit: 20)).called(1);
    });
  });
}
