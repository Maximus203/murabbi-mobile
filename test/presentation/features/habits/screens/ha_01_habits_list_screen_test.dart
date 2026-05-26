import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
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
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_01_habits_list_screen.dart';
import '../../../../helpers/in_memory_repositories.dart';

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

  Widget pumpable({InMemoryHabitRepository? customRepo}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        habitRepositoryProvider.overrideWithValue(
          customRepo ?? InMemoryHabitRepository(),
        ),
      ],
      child: MaterialApp(home: Ha01HabitsListScreen(onCreate: () {})),
    );
  }

  testWidgets(
    'empty state : CTA "Aucune habitude" + bouton "Créer une habitude"',
    (tester) async {
      await tester.pumpWidget(pumpable());
      await tester.pumpAndSettle();

      // Texte exact du redesign HA-01 (cf. ha_01_habits_list_screen.dart ligne 501).
      expect(find.text("Aucune habitude pour l'instant"), findsOneWidget);
      expect(find.text('Créer une habitude'), findsWidgets);
    },
  );

  testWidgets('rend la liste avec nom + points', (tester) async {
    final repo = InMemoryHabitRepository()
      ..createHabit(
        userId: testUser.id,
        habit: Habit(
          id: HabitId('h1'),
          userId: UserId('user-001'),
          name: NonEmptyString('Lecture Coran'),
          categoryId: CategoryId('cat-religion'),
          frequencyType: HabitFrequencyType.daily,
          frequency: 1,
          activeDays: const {1, 2, 3, 4, 5, 6, 7},
          points: HabitPoints(5),
          isSystem: false,
        ),
      );
    await tester.pumpWidget(pumpable(customRepo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Lecture Coran'), findsOneWidget);
    expect(find.text('+5 pts'), findsOneWidget);
  });

  testWidgets('empty state affiche l\'icône Lucide (#77)', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    // Icône du redesign HA-01 : LucideIcons.activity (cf. ha_01 ligne 493).
    expect(find.byIcon(LucideIcons.activity), findsOneWidget);
  });

  testWidgets('FAB tap déclenche onCreate', (tester) async {
    var created = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          habitRepositoryProvider.overrideWithValue(InMemoryHabitRepository()),
        ],
        child: MaterialApp(
          home: Ha01HabitsListScreen(onCreate: () => created = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Bouton du redesign HA-01 (cf. ha_01_habits_list_screen.dart ligne 512).
    await tester.tap(find.text('Créer une habitude').first);
    await tester.pumpAndSettle();
    expect(created, isTrue);
  });

  testWidgets(
    'empty state : bouton "Voir les collections" appelle onOpenCollections',
    (tester) async {
      var opened = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            habitRepositoryProvider.overrideWithValue(
              InMemoryHabitRepository(),
            ),
          ],
          child: MaterialApp(
            home: Ha01HabitsListScreen(
              onCreate: () {},
              onOpenCollections: () => opened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Voir les collections'), findsOneWidget);
      await tester.tap(find.text('Voir les collections'));
      expect(opened, isTrue);
    },
  );
}
