import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/in_memory_habit_repository.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_02_create_habit_screen.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

/// Repo de test qui peut être configuré pour throw — simule un wiring
/// Supabase défaillant. Garde la signature `InMemoryHabitRepository` pour
/// override via `habitRepositoryProvider`.
class _FailingHabitRepo extends InMemoryHabitRepository {
  _FailingHabitRepo({this.shouldThrow = false});
  bool shouldThrow;

  @override
  Future<Habit> createHabit({
    required UserId userId,
    required Habit habit,
  }) async {
    if (shouldThrow) {
      throw StateError('boom — Supabase down');
    }
    return super.createHabit(userId: userId, habit: habit);
  }
}

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

  Widget pumpable({
    InMemoryHabitRepository? customRepo,
    VoidCallback? onCreated,
    VoidCallback? onCancel,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        if (customRepo != null)
          habitRepositoryProvider.overrideWithValue(customRepo),
      ],
      child: MaterialApp(
        home: Ha02CreateHabitScreen(
          onCreated: onCreated ?? () {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  Future<void> pumpAndPreWarmAuth(WidgetTester tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
  }

  testWidgets('rend le formulaire (nom + catégorie + récurrence + points)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAndPreWarmAuth(tester);

    expect(find.text('NOM'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);
    expect(find.text('Récurrence'), findsOneWidget);
    expect(find.text('Difficulté'), findsOneWidget);
    expect(find.text('Créer l\'habitude'), findsOneWidget);
  });

  testWidgets('submit avec nom vide → message d\'erreur, repo non appelé', (
    tester,
  ) async {
    final repo = InMemoryHabitRepository();
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(pumpable(customRepo: repo));
    await tester.pumpAndSettle();

    // Tap "Créer" sans avoir saisi le nom.
    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis.'), findsOneWidget);
    expect(await repo.getHabits(testUser.id), isEmpty);
  });

  testWidgets('submit success → createHabit appelé + onCreated déclenché', (
    tester,
  ) async {
    final repo = InMemoryHabitRepository();
    var createdCalled = false;

    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      pumpable(customRepo: repo, onCreated: () => createdCalled = true),
    );
    await tester.pumpAndSettle();

    // Saisie nom.
    await tester.enterText(find.byType(TextField).first, 'Lecture Coran');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    final habits = await repo.getHabits(testUser.id);
    expect(habits, hasLength(1));
    expect(habits.first.name.value, 'Lecture Coran');
    expect(createdCalled, isTrue);
  });

  testWidgets(
    'submit error → message d\'erreur affiché, onCreated PAS appelé',
    (tester) async {
      final repo = _FailingHabitRepo(shouldThrow: true);
      var createdCalled = false;

      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        pumpable(customRepo: repo, onCreated: () => createdCalled = true),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Test habit');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer l\'habitude'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Impossible de créer'), findsOneWidget);
      expect(createdCalled, isFalse);
    },
  );

  testWidgets('switch récurrence weekly affiche les day chips L-D', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAndPreWarmAuth(tester);

    // Au boot : daily sélectionnée, pas de day chips.
    expect(find.text('L'), findsNothing);

    await tester.tap(find.text('Jours précis de la semaine'));
    await tester.pumpAndSettle();

    // Day chips L M M J V S D apparaissent. "M" apparaît 2x (mardi + mercredi).
    expect(find.text('L'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });
}
