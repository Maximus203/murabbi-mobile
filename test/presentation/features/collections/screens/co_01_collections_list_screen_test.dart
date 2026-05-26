import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_01_collections_list_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';
import '../../../../helpers/test_uuids.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockCollectionRepo extends Mock implements CollectionRepository {}

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

void main() {
  late _MockAuthRepo authRepo;
  late _MockCollectionRepo collectionRepo;
  late _MockHabitRepo habitRepo;
  late _MockCategoryRepo categoryRepo;

  final testUser = User(
    id: UserId(kUserIdAlpha),
    pseudo: Pseudonym('Test'),
    email: NonEmptyString('test@test.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  /// Collection système inactive — section "SUGGESTIONS - SYSTÈME".
  final systemCollection = Collection(
    id: CollectionId(kCollectionIdAlpha),
    name: NonEmptyString('Routine matinale'),
    description: NonEmptyString('Commencer la journée'),
    habitIds: const [],
    isSystem: true,
    isActive: false,
  );

  /// Collection utilisateur active.
  final userCollectionActive = Collection(
    id: CollectionId(kCollectionIdBeta),
    name: NonEmptyString('Sport hebdo'),
    description: NonEmptyString('Activité physique'),
    habitIds: const [],
    isSystem: false,
    isActive: true,
  );

  setUpAll(() {
    registerFallbackValue(UserId(kUserIdAlpha));
    registerFallbackValue(HabitId(kHabitIdAlpha));
    registerFallbackValue(CollectionId(kCollectionIdAlpha));
    registerFallbackValue(DateTime.utc(2026, 1, 1));
  });

  setUp(() {
    authRepo = _MockAuthRepo();
    collectionRepo = _MockCollectionRepo();
    habitRepo = _MockHabitRepo();
    categoryRepo = _MockCategoryRepo();

    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);
    when(() => habitRepo.getHabits(any())).thenAnswer((_) async => <Habit>[]);
    when(
      () => habitRepo.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => categoryRepo.getCategories(any()),
    ).thenAnswer((_) async => []);
  });

  Widget buildSut({
    required List<Collection> collections,
    VoidCallback? onCreate,
    void Function(String)? onOpen,
  }) {
    when(
      () => collectionRepo.getCollections(any()),
    ).thenAnswer((_) async => collections);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        authRepositoryProvider.overrideWithValue(authRepo),
        collectionRepositoryProvider.overrideWithValue(collectionRepo),
        habitRepositoryProvider.overrideWithValue(habitRepo),
        categoryRepositoryProvider.overrideWithValue(categoryRepo),
      ],
      child: MaterialApp(
        home: Co01CollectionsListScreen(
          onCreate: onCreate ?? () {},
          onOpenCollection: onOpen ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('loading state — affiche AppSkeletonCard', (tester) async {
    await tester.pumpWidget(buildSut(collections: []));
    // CO-01 affiche 3 AppSkeletonCard pendant le chargement (avant le premier settle)
    expect(find.byType(AppSkeletonCard), findsWidgets);
  });

  testWidgets('empty state (0 collections) — affiche "Aucune collection"', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(collections: []));
    await tester.pumpAndSettle();
    expect(find.text('Aucune collection'), findsOneWidget);
  });

  testWidgets('aucune collection active — affiche carte "Aucune collection activée"', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(collections: [systemCollection]));
    await tester.pumpAndSettle();
    expect(find.text('Aucune collection activée'), findsOneWidget);
  });

  testWidgets('affiche une collection système et une collection utilisateur', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSut(collections: [systemCollection, userCollectionActive]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Routine matinale'), findsOneWidget);
    expect(find.text('Sport hebdo'), findsOneWidget);
  });

  testWidgets(
    'section "SUGGESTIONS - SYSTÈME" présente si aucune collection active',
    (tester) async {
      await tester.pumpWidget(buildSut(collections: [systemCollection]));
      await tester.pumpAndSettle();
      expect(find.textContaining('SUGGESTIONS'), findsOneWidget);
    },
  );

  testWidgets(
    'section "SYSTÈME" présente si au moins une collection système active',
    (tester) async {
      final systemActive = Collection(
        id: CollectionId(kCollectionIdAlpha),
        name: NonEmptyString('Routine matinale'),
        description: NonEmptyString('Commencer la journée'),
        habitIds: const [],
        isSystem: true,
        isActive: true,
      );
      await tester.pumpWidget(buildSut(collections: [systemActive]));
      await tester.pumpAndSettle();
      // "SYSTÈME" présent mais pas "SUGGESTIONS - SYSTÈME".
      expect(find.text('SYSTÈME'), findsOneWidget);
      expect(find.textContaining('SUGGESTIONS'), findsNothing);
    },
  );

  testWidgets('section "MES COLLECTIONS" présente si isSystem=false', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(collections: [userCollectionActive]));
    await tester.pumpAndSettle();
    expect(find.textContaining('MES COLLECTIONS'), findsOneWidget);
  });

  testWidgets('bouton "+" header appelle onCreate', (tester) async {
    var called = false;
    await tester.pumpWidget(
      buildSut(collections: [], onCreate: () => called = true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(IconButton));
    expect(called, isTrue);
  });

  testWidgets(
    'tap sur une collection utilisateur active appelle onOpenCollection',
    (tester) async {
      String? opened;
      await tester.pumpWidget(
        buildSut(
          collections: [userCollectionActive],
          onOpen: (id) => opened = id,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sport hebdo'));
      expect(opened, equals(kCollectionIdBeta));
    },
  );

  testWidgets('error state — affiche message erreur', (tester) async {
    when(
      () => collectionRepo.getCollections(any()),
    ).thenThrow(StateError('boom'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(testUser),
          authRepositoryProvider.overrideWithValue(authRepo),
          collectionRepositoryProvider.overrideWithValue(collectionRepo),
          habitRepositoryProvider.overrideWithValue(habitRepo),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
        ],
        child: MaterialApp(
          home: Co01CollectionsListScreen(
            onCreate: () {},
            onOpenCollection: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('erreur'), findsOneWidget);
  });
}
