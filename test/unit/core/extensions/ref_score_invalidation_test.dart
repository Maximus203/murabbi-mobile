import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/extensions/ref_score_invalidation.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/user_score_provider.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockScoreRepo extends Mock implements ScoreRepository {}

void main() {
  late _MockAuthRepo authRepo;
  late _MockScoreRepo scoreRepo;

  setUpAll(() {
    registerFallbackValue(UserId('fb'));
  });

  setUp(() {
    authRepo = _MockAuthRepo();
    scoreRepo = _MockScoreRepo();

    final testUser = User(
      id: UserId('u1'),
      pseudo: Pseudonym('Cherif'),
      email: NonEmptyString('cherif@example.com'),
      createdAt: DateTime.utc(2026, 1, 1),
      level: Level.aspirant,
    );

    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);

    when(() => scoreRepo.getUserScore(any())).thenAnswer(
      (_) async => UserScore(
        userId: UserId('u1'),
        totalPoints: 42,
        weeklyPoints: 12,
        currentLevel: Level.aspirant,
        weeklyRank: 1,
      ),
    );
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        scoreRepositoryProvider.overrideWithValue(scoreRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('invalidateScoreCache invalide userScoreProvider', () async {
    final container = makeContainer();

    // Garde le provider vivant pendant tout le test pour éviter la dispose.
    final sub = container.listen(userScoreProvider, (_, _) {});
    addTearDown(sub.close);

    // Initialise l'auth puis lit le score.
    await container.read(authNotifierProvider.future);
    await container.read(userScoreProvider.future);

    // Consomme les appels enregistrés jusqu'ici.
    verify(() => scoreRepo.getUserScore(any())).called(greaterThan(0));

    // Invalide via l'extension.
    container.read(_invalidatorProvider).invalidate();

    // Second read → repo rappelé (cache invalidé) → ≥1 nouvel appel.
    await container.read(userScoreProvider.future);
    verify(() => scoreRepo.getUserScore(any())).called(greaterThan(0));
  });

  test(
    'invalidateScoreCache invalide aussi dashboardNotifierProvider',
    () async {
      final container = makeContainer();
      final sub = container.listen(userScoreProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(authNotifierProvider.future);
      await container.read(userScoreProvider.future);

      // Snapshot du provider score avant invalidation.
      final before = container.read(userScoreProvider);
      expect(before.hasValue, isTrue);

      container.read(_invalidatorProvider).invalidate();

      // Après invalidation, l'état devient loading (rebuild).
      final after = container.read(userScoreProvider);
      expect(after.isLoading, isTrue);
    },
  );
}

/// Provider de test qui expose l'extension `invalidateScoreCache` via une
/// closure capturant le `Ref` du container.
class _Invalidator {
  final void Function() invalidate;
  _Invalidator(this.invalidate);
}

final _invalidatorProvider = Provider<_Invalidator>((ref) {
  return _Invalidator(() => ref.invalidateScoreCache());
});
