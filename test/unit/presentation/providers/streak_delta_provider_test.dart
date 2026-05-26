import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/daily_summary_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/streak_delta_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class _MockDailySummaryRepo extends Mock implements DailySummaryRepository {}

/// Tests du [streakDeltaProvider] (issue #6, Phase 5 — Q-D Option A).
///
/// Ce provider est pur glue : il orchestre [DailySummaryRepository] +
/// [ComputeStreakDeltaUseCase] (déjà 100% testé). On valide ici les
/// comportements contractuels : utilisateur absent → 0, historique vide → 0,
/// exception → fallback 0, delta positif sur données cohérentes.
void main() {
  late _MockDailySummaryRepo repo;

  final userId = UserId('user-streak-test');
  final testUser = User(
    id: userId,
    pseudo: Pseudonym('Streaker'),
    email: NonEmptyString('streaker@example.com'),
    createdAt: DateTime(2026, 1, 1),
    level: Level.aspirant,
  );

  DailySummary makeDay(DateTime date, {required bool valid}) => DailySummary(
    userId: userId,
    day: date,
    completionRate: valid ? 100.0 : 0.0,
    streakValid: valid,
    habitPointsToday: valid ? 10 : 0,
  );

  setUp(() {
    repo = _MockDailySummaryRepo();
    registerFallbackValue(userId);
  });

  /// Crée un [ProviderContainer] isolé avec les overrides nécessaires.
  ProviderContainer makeContainer({required User? user}) {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        dailySummaryRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('streakDeltaProvider', () {
    test('retourne 0 et ne touche pas au repo si utilisateur absent', () async {
      final container = makeContainer(user: null);

      final result = await container.read(streakDeltaProvider.future);

      expect(result, 0);
      verifyNever(
        () => repo.getRecentSummaries(any(), days: any(named: 'days')),
      );
    });

    test('retourne 0 quand historique vide', () async {
      when(
        () => repo.getRecentSummaries(userId, days: 30),
      ).thenAnswer((_) async => []);
      final container = makeContainer(user: testUser);

      expect(await container.read(streakDeltaProvider.future), 0);
    });

    test(
      'retourne delta positif quand streak a progressé cette semaine',
      () async {
        // Construit un historique relatif à "maintenant" pour éviter les
        // dépendances à la date système fixe.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        // streak(now) = 2 (hier + aujourd'hui), streak(now-7j) = 0 → delta = 2
        when(() => repo.getRecentSummaries(userId, days: 30)).thenAnswer(
          (_) async => [
            makeDay(yesterday, valid: true),
            makeDay(today, valid: true),
          ],
        );
        final container = makeContainer(user: testUser);

        expect(await container.read(streakDeltaProvider.future), 2);
      },
    );

    test(
      'retourne 0 (fallback défensif) si le repository lève une exception',
      () async {
        when(
          () => repo.getRecentSummaries(userId, days: 30),
        ).thenThrow(Exception('Réseau indisponible'));
        final container = makeContainer(user: testUser);

        expect(await container.read(streakDeltaProvider.future), 0);
      },
    );
  });
}
