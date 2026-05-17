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

  // ── Logique pure : labels FR de fréquence (issue #127) ──────────────────

  group('frequencyLabel — issue #127', () {
    test('chaque valeur de l\'enum a un label FR explicite', () {
      const expected = {
        HabitFrequencyType.daily: 'Quotidien',
        HabitFrequencyType.perDay: 'Plusieurs fois/jour',
        HabitFrequencyType.perWeek: 'Plusieurs fois/sem.',
        HabitFrequencyType.weekly: 'Jours précis de la semaine',
        HabitFrequencyType.monthly: 'Mensuel',
        HabitFrequencyType.custom: 'Personnalisé',
      };
      for (final t in HabitFrequencyType.values) {
        final label = Ha02CreateHabitScreen.frequencyLabel(t);
        expect(label, expected[t]);
        // Aucun label ne doit être le nom brut anglais de l'enum.
        expect(label, isNot(equals(t.name)));
      }
    });
  });

  // ── Rendu du formulaire ─────────────────────────────────────────────────

  testWidgets('rend le formulaire (nom + catégorie + fréquence + difficulté)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAndPreWarmAuth(tester);

    expect(find.text('NOM'), findsOneWidget);
    expect(find.text('CATÉGORIE'), findsOneWidget);
    expect(find.text('FRÉQUENCE'), findsOneWidget);
    expect(find.text('DIFFICULTÉ'), findsOneWidget);
    expect(find.text('Créer l\'habitude'), findsOneWidget);
  });

  // ── Validation NOM : inline + clear à la frappe (issues #142/#143) ──────

  testWidgets(
    'submit avec nom vide → erreur inline sous le champ, repo non appelé',
    (tester) async {
      final repo = InMemoryHabitRepository();
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(pumpable(customRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer l\'habitude'));
      await tester.pumpAndSettle();

      expect(find.text('Le nom est requis.'), findsOneWidget);
      expect(await repo.getHabits(testUser.id), isEmpty);
    },
  );

  testWidgets('erreur NOM disparaît dès que l\'utilisateur tape — issue #142', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAndPreWarmAuth(tester);

    // Déclenche l'erreur.
    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();
    expect(find.text('Le nom est requis.'), findsOneWidget);

    // Frappe dans le champ NOM.
    await tester.enterText(find.byType(TextField).first, 'Lecture du Coran');
    await tester.pumpAndSettle();

    // L'erreur a disparu.
    expect(find.text('Le nom est requis.'), findsNothing);
  });

  // ── Succès : repo appelé + SnackBar + onCreated (issue #144) ────────────

  testWidgets('submit success → habitude créée + SnackBar succès + onCreated', (
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

    await tester.enterText(find.byType(TextField).first, 'Lecture Coran');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    final habits = await repo.getHabits(testUser.id);
    expect(habits, hasLength(1));
    expect(habits.first.name.value, 'Lecture Coran');
    expect(createdCalled, isTrue);
    expect(find.text('Habitude créée avec succès'), findsOneWidget);
  });

  testWidgets(
    'submit error → bannière d\'erreur affichée, onCreated PAS appelé',
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

  // ── Sélecteur de jours : labels non ambigus + défaut vide ───────────────

  testWidgets(
    'mode "Jours précis" affiche des labels jours non ambigus — issue #129',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpAndPreWarmAuth(tester);

      await tester.tap(find.text('Jours précis de la semaine'));
      await tester.pumpAndSettle();

      // Labels 2 lettres uniques — plus de double 'M'.
      for (final label in ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di']) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets('mode "Jours précis" → aucun jour pré-sélectionné — issue #141', (
    tester,
  ) async {
    final repo = InMemoryHabitRepository();
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(pumpable(customRepo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Habitude');
    await tester.tap(find.text('Jours précis de la semaine'));
    await tester.pumpAndSettle();

    // Aucun jour sélectionné : submit refuse et ne crée rien.
    await tester.tap(find.text('Créer l\'habitude'));
    await tester.pumpAndSettle();

    expect(find.text('Sélectionne au moins un jour.'), findsOneWidget);
    expect(await repo.getHabits(testUser.id), isEmpty);
  });
}
