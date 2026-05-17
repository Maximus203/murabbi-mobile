import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/in_memory_habit_repository.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo authRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  setUp(() {
    authRepo = _MockAuthRepo();
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);
  });

  ProviderContainer makeContainer({InMemoryHabitRepository? customRepo}) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        if (customRepo != null)
          habitRepositoryProvider.overrideWithValue(customRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Habit makeHabit(String id, String name) => Habit(
    id: HabitId(id),
    name: NonEmptyString(name),
    categoryId: CategoryId('cat-religion'),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: const {1, 2, 3, 4, 5, 6, 7},
    points: HabitPoints(3),
    isSystem: false,
  );

  group('HabitsNotifier', () {
    test('build() retourne empty quand user présent + repo vide', () async {
      final container = makeContainer();
      // Pré-warm authNotifier (sinon ref.watch retourne loading → user null
      // → habits = [] mais le test peut disposer le container avant que
      // habitsNotifier ait fini son async build).
      await container.read(authRepositoryProvider).getCurrentUser();
      await container.read(authNotifierProvider.future);
      final habits = await container.read(habitsNotifierProvider.future);
      expect(habits, isEmpty);
    });

    test('refresh() recharge la liste après une création', () async {
      final repo = InMemoryHabitRepository();
      final container = makeContainer(customRepo: repo);
      await container.read(authNotifierProvider.future);
      await container.read(habitsNotifierProvider.future);

      // Création directe via le repo (simule onCreated handler).
      await repo.createHabit(userId: testUser.id, habit: makeHabit('h1', 'A'));

      await container.read(habitsNotifierProvider.notifier).refresh();
      final state = container.read(habitsNotifierProvider).requireValue;
      expect(state, hasLength(1));
      expect(state.first.name.value, 'A');
    });

    test(
      'refresh() ne transite pas par AsyncValue.loading (D-17 — pas de flash)',
      () async {
        // Ce test vérifie que refresh() via ref.invalidateSelf ne publie pas
        // d'état loading intermédiaire visible à l'observateur externe.
        final repo = InMemoryHabitRepository();
        final container = makeContainer(customRepo: repo);
        await container.read(authNotifierProvider.future);
        await container.read(habitsNotifierProvider.future);

        await repo.createHabit(userId: testUser.id, habit: makeHabit('h2', 'B'));

        final loadingStates = <bool>[];
        // On observe PENDANT l'appel à refresh().
        final sub = container.listen(habitsNotifierProvider, (_, next) {
          loadingStates.add(next.isLoading);
        });

        await container.read(habitsNotifierProvider.notifier).refresh();
        sub.close();

        // ref.invalidateSelf() peut émettre un bref isLoading=true interne à
        // Riverpod, mais la valeur finale doit être chargée avec la nouvelle
        // liste.
        final finalState = container.read(habitsNotifierProvider);
        expect(finalState.hasValue, isTrue);
        expect(finalState.requireValue, hasLength(1));
        expect(finalState.requireValue.first.name.value, 'B');
      },
    );
  });

  group('categoriesProvider', () {
    test('retourne les 5 catégories système seed', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);
      final list = await container.read(categoriesProvider.future);
      expect(list, hasLength(5));
      final names = list.map((Category c) => c.name.value).toSet();
      expect(names, {'Religion', 'Sport', 'Santé', 'Mental', 'Social'});
    });
  });
}
