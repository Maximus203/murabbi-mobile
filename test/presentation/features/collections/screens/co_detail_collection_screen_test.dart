import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_detail_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import '../../../../helpers/test_uuids.dart';

class _MockCollectionRepo extends Mock implements CollectionRepository {}

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

void main() {
  late _MockCollectionRepo mockCollectionRepo;
  late _MockHabitRepo mockHabitRepo;
  late _MockCategoryRepo mockCategoryRepo;

  final userId = UserId(kUserIdAlpha);
  final testUser = User(
    id: userId,
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: Level.aspirant,
  );

  final userInactive = Collection(
    id: CollectionId('coll-1'),
    name: NonEmptyString('Routine matinale'),
    description: NonEmptyString('Commencer la journée'),
    habitIds: [HabitId(kHabitIdAlpha)],
    isSystem: false,
    isActive: false,
  );

  final userActive = Collection(
    id: CollectionId('coll-2'),
    name: NonEmptyString('Sport hebdo'),
    description: NonEmptyString('Activité physique'),
    habitIds: [HabitId(kHabitIdBeta)],
    isSystem: false,
    isActive: true,
  );

  final systemCollection = Collection(
    id: CollectionId('coll-sys'),
    name: NonEmptyString('Matin du musulman'),
    description: NonEmptyString('Routine système'),
    habitIds: [HabitId(kHabitIdAlpha)],
    isSystem: true,
    isActive: false,
  );

  setUpAll(() {
    registerFallbackValue(CollectionId('fallback'));
    registerFallbackValue(userId);
    registerFallbackValue(HabitId(kHabitIdAlpha));
    registerFallbackValue(DateTime(2024));
  });

  setUp(() {
    mockCollectionRepo = _MockCollectionRepo();
    mockHabitRepo = _MockHabitRepo();
    mockCategoryRepo = _MockCategoryRepo();

    when(
      () => mockCollectionRepo.getCollections(any()),
    ).thenAnswer((_) async => [userInactive, userActive]);

    when(
      () => mockHabitRepo.getHabits(any()),
    ).thenAnswer((_) async => <Habit>[]);

    when(
      () => mockHabitRepo.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockCategoryRepo.getCategories(any()),
    ).thenAnswer((_) async => []);
  });

  Widget buildSut(Collection collection) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        collectionRepositoryProvider.overrideWithValue(mockCollectionRepo),
        habitRepositoryProvider.overrideWithValue(mockHabitRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
      ],
      child: MaterialApp(
        home: CoDetailCollectionScreen(collection: collection, onBack: () {}),
      ),
    );
  }

  testWidgets('affiche le nom et la description de la collection', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    expect(find.text('Routine matinale'), findsWidgets);
    expect(find.text('Commencer la journée'), findsOneWidget);
  });

  testWidgets('affiche la section HABITUDES INCLUSES', (tester) async {
    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    expect(find.text('HABITUDES INCLUSES'), findsOneWidget);
  });

  testWidgets('affiche le footer POTENTIEL JOURNALIER', (tester) async {
    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    expect(find.text('POTENTIEL JOURNALIER'), findsOneWidget);
  });

  testWidgets('bouton Activer présent si collection inactive (Key btn_activate)', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_activate')), findsOneWidget);
    expect(find.byKey(const Key('btn_deactivate')), findsNothing);
  });

  testWidgets('bouton Désactiver présent si collection active (Key btn_deactivate)', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(userActive));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_deactivate')), findsOneWidget);
    expect(find.byKey(const Key('btn_activate')), findsNothing);
  });

  testWidgets('menu ... absent pour une collection système', (tester) async {
    await tester.pumpWidget(buildSut(systemCollection));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_delete_menu')), findsNothing);
  });

  testWidgets('menu ... présent pour une collection utilisateur', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_delete_menu')), findsOneWidget);
  });

  testWidgets('tap sur menu ... affiche dialogue de confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_delete_menu')));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer la collection'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
  });

  testWidgets('tap Activer appelle activateCollection', (tester) async {
    when(
      () => mockCollectionRepo.activateCollection(
        userId: any(named: 'userId'),
        collectionId: any(named: 'collectionId'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildSut(userInactive));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_activate')));
    await tester.pumpAndSettle();

    verify(
      () => mockCollectionRepo.activateCollection(
        userId: any(named: 'userId'),
        collectionId: any(named: 'collectionId'),
      ),
    ).called(1);
  });
}
