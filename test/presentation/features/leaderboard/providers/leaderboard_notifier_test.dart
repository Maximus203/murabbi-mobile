import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/level.dart' as level_lib;
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/providers/leaderboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import '../../../../helpers/test_uuids.dart';

class MockScoreRepository extends Mock implements ScoreRepository {}

void main() {
  late MockScoreRepository mockRepo;

  final testUser = User(
    id: UserId(kUserIdAlpha),
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: level_lib.Level.aspirant,
  );

  final score1 = UserScore(
    userId: UserId(kUserIdAlpha),
    totalPoints: 1500,
    weeklyPoints: 200,
    currentLevel: Level.aspirant,
    weeklyRank: 1,
  );

  final score2 = UserScore(
    userId: UserId(kUserIdBeta),
    totalPoints: 1200,
    weeklyPoints: 150,
    currentLevel: Level.aspirant,
    weeklyRank: 2,
  );

  setUp(() {
    mockRepo = MockScoreRepository();
    registerFallbackValue(UserId('fallback-user'));
  });

  ProviderContainer makeContainer({User? user}) {
    return ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(user ?? testUser),
        scoreRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('LeaderboardNotifier', () {
    test('build charge le leaderboard top 50', () async {
      when(
        () => mockRepo.getLeaderboard(limit: 50),
      ).thenAnswer((_) async => [score1, score2]);

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(leaderboardNotifierProvider.future);

      expect(result, [score1, score2]);
      verify(() => mockRepo.getLeaderboard(limit: 50)).called(1);
    });

    test('build retourne [] si user null', () async {
      // scoreRepositoryProvider doit aussi être overridé même si non appelé
      // pour éviter que Riverpod essaie d'instancier le client Supabase.
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          scoreRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(leaderboardNotifierProvider.future);
      expect(result, isEmpty);
    });

    test('refresh recharge le leaderboard', () async {
      when(
        () => mockRepo.getLeaderboard(limit: 50),
      ).thenAnswer((_) async => [score1]);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(leaderboardNotifierProvider.future);
      await container.read(leaderboardNotifierProvider.notifier).refresh();

      // Appelé 2 fois : build initial + refresh
      verify(() => mockRepo.getLeaderboard(limit: 50)).called(2);
    });
  });
}
