import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/in_memory_habit_repository.dart';
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
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_02_create_habit_screen.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

/// Repo de test qui peut être configuré pour throw — simule un wiring
/// Supabase défaillant.
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

  Habit makeHabit() => Habit(
    id: HabitId('habit-edit-001'),
    name: NonEmptyString('Lecture Coran'),
    categoryId: CategoryId('cat-religion'),
    frequencyType: HabitFrequencyType.weekly,
    frequency: 1,
    activeDays: const {1, 3, 5},
    points: HabitPoints(7),
    isSystem: false,
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
    Habit? initialHabit,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        habitRepositoryProvider.overrideWithValue(
          customRepo ?? InMemoryHabitRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          InMemoryCategoryRepository(),
        ),
      ],
      child: MaterialApp(
        home: Ha02CreateHabitScreen(
          onCreated: onCreated ?? () {},
          onCancel: onCancel ?? () {},
          initialHabit: initialHabit,
        ),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    InMemoryHabitRepository? customRepo,
    VoidCallback? onCreated,
    Habit? initialHabit,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      pumpable(
        customRepo: customRepo,
        onCreated: onCreated,
        initialHabit: initialHabit,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rend le formulaire (nom + catégorie + récurrence + points)', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('NOM'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);
    expect(find.text('Récurrence'), findsOneWidget);
    expect(find.text('Difficulté'), findsOneWidget);
    expect(find.text('Créer l\'habitude'), findsOneWidget);
  });

  testWidgets('#143 : submit nom vide → erreur inline sous NOM, repo non '
      'appelé', (tester) async {
    final repo = InMemoryHabitRepository();
    await pumpScreen(tester, customRepo: repo);

    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis.'), findsOneWidget);
    expect(await repo.getHabits(testUser.id), isEmpty);
  });

  testWidgets('#142 : erreur "nom requis" effacée dès la frappe', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();
    expect(find.text('Le nom est requis.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Sport');
    await tester.pumpAndSettle();
    expect(find.text('Le nom est requis.'), findsNothing);
  });

  testWidgets('#144 : submit success → repo appelé + onCreated + snackbar', (
    tester,
  ) async {
    final repo = InMemoryHabitRepository();
    var createdCalled = false;
    await pumpScreen(
      tester,
      customRepo: repo,
      onCreated: () => createdCalled = true,
    );

    await tester.enterText(find.byType(TextField).first, 'Lecture Coran');
    await tester.pump();
    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final habits = await repo.getHabits(testUser.id);
    expect(habits, hasLength(1));
    expect(habits.first.name.value, 'Lecture Coran');
    expect(createdCalled, isTrue);
    expect(find.text('Habitude créée.'), findsOneWidget);
  });

  testWidgets('submit error → message d\'erreur affiché, onCreated PAS '
      'appelé', (tester) async {
    final repo = _FailingHabitRepo(shouldThrow: true);
    var createdCalled = false;
    await pumpScreen(
      tester,
      customRepo: repo,
      onCreated: () => createdCalled = true,
    );

    await tester.enterText(find.byType(TextField).first, 'Test habit');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Impossible de créer'), findsOneWidget);
    expect(createdCalled, isFalse);
  });

  testWidgets('#141 : chips jours non pré-sélectionnés en création', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Jours précis de la semaine'));
    await tester.pumpAndSettle();

    // Aucun jour sélectionné → submit avec nom valide doit afficher l'erreur
    // de jours, pas créer l'habitude.
    await tester.enterText(find.byType(TextField).first, 'Sport');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    expect(find.text('Sélectionne au moins un jour.'), findsOneWidget);
  });

  testWidgets('switch récurrence weekly affiche les day chips L-D', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('L'), findsNothing);
    await tester.tap(find.text('Jours précis de la semaine'));
    await tester.pumpAndSettle();

    expect(find.text('L'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
    expect(find.text('V'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
  });

  testWidgets('#139 : stepper difficulté ne descend pas sous 1', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Difficulté démarre à 3 — on tente de descendre 5 fois.
    final minusBtn = find.ancestor(
      of: find.byTooltip('Diminuer les points'),
      matching: find.byType(IconButton),
    );
    for (var i = 0; i < 5; i++) {
      // Une fois à la borne, le bouton est désactivé (onPressed == null).
      final enabled = tester.widget<IconButton>(minusBtn).onPressed != null;
      if (enabled) await tester.tap(minusBtn);
      await tester.pumpAndSettle();
    }
    // Ne doit jamais afficher moins de "1 pt".
    expect(find.text('1 pt'), findsOneWidget);
    expect(find.text('0 pts'), findsNothing);
  });

  testWidgets('mode édition : champs pré-remplis depuis l\'entité', (
    tester,
  ) async {
    await pumpScreen(tester, initialHabit: makeHabit());

    expect(find.text('Modifier l\'habitude'), findsOneWidget);
    expect(find.text('Enregistrer les modifications'), findsOneWidget);
    // Nom pré-rempli.
    expect(find.text('Lecture Coran'), findsOneWidget);
  });

  testWidgets('mode édition : updateHabit appelé au submit', (tester) async {
    final repo = InMemoryHabitRepository();
    final habit = makeHabit();
    await repo.createHabit(userId: testUser.id, habit: habit);

    var savedCalled = false;
    await pumpScreen(
      tester,
      customRepo: repo,
      initialHabit: habit,
      onCreated: () => savedCalled = true,
    );

    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(savedCalled, isTrue);
    expect(find.text('Habitude mise à jour.'), findsOneWidget);
    // Toujours une seule habitude — update, pas create.
    expect(await repo.getHabits(testUser.id), hasLength(1));
  });
}
