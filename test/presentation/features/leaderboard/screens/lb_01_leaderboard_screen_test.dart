import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/screens/lb_01_leaderboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class MockScoreRepository extends Mock implements ScoreRepository {}

void main() {
  late MockScoreRepository mockRepo;

  final testUser = User(
    id: UserId('user-uuid-001'),
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: Level.aspirant,
  );

  final score1 = UserScore(
    userId: UserId('user-uuid-001'),
    totalPoints: 1500,
    weeklyPoints: 200,
    currentLevel: Level.murid,
    weeklyRank: 1,
  );

  final score2 = UserScore(
    userId: UserId('user-uuid-002'),
    totalPoints: 1200,
    weeklyPoints: 150,
    currentLevel: Level.aspirant,
    weeklyRank: 2,
  );

  setUp(() {
    mockRepo = MockScoreRepository();
    registerFallbackValue(UserId('fallback'));
  });

  Widget buildSut(List<UserScore> scores) {
    when(
      () => mockRepo.getLeaderboard(limit: 50),
    ).thenAnswer((_) async => scores);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        scoreRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: Lb01LeaderboardScreen()),
    );
  }

  testWidgets('affiche les scores du leaderboard', (tester) async {
    await tester.pumpWidget(buildSut([score1, score2]));
    await tester.pumpAndSettle();

    // Les rangs
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    // Les points
    expect(find.text('200 pts'), findsOneWidget);
    expect(find.text('150 pts'), findsOneWidget);
  });

  testWidgets('affiche empty state si leaderboard vide', (tester) async {
    await tester.pumpWidget(buildSut([]));
    await tester.pumpAndSettle();

    expect(find.text('Aucun score disponible'), findsOneWidget);
  });

  testWidgets('affiche un indicateur de chargement', (tester) async {
    // Utilise un Completer pour bloquer la résolution sans timer pending.
    final completer = Completer<List<UserScore>>();
    when(
      () => mockRepo.getLeaderboard(limit: 50),
    ).thenAnswer((_) => completer.future);

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        scoreRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(() {
      if (!completer.isCompleted) completer.complete([]);
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Lb01LeaderboardScreen()),
      ),
    );

    // Première frame avant résolution — loading state
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
