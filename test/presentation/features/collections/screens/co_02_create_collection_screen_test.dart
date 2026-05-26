import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_02_create_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

/// Stub AuthNotifier — retourne immédiatement [testUser] sans appel Supabase.
class _StubAuthNotifier extends AuthNotifier {
  final User _user;
  _StubAuthNotifier(this._user);

  @override
  Future<User?> build() async => _user;
}

/// Stub HabitsNotifier — retourne une liste fixe sans dépendance Supabase.
/// Doit étendre [HabitsNotifier] pour satisfaire le type de [habitsNotifierProvider].
class _StubHabitsNotifier extends HabitsNotifier {
  final List<Habit> _habits;
  _StubHabitsNotifier(this._habits);

  @override
  Future<List<Habit>> build() async => _habits;
}

/// Stub CategoriesNotifier — retourne une liste vide sans dépendance Supabase.
/// Doit étendre [CategoriesNotifier] pour satisfaire le type du provider.
class _StubCategoriesNotifier extends CategoriesNotifier {
  @override
  Future<List<Category>> build() async => const [];
}

/// Stub CollectionsNotifier — délègue uniquement `create()` au vrai repo
/// (via [collectionRepositoryProvider] surchargé) sans nécessiter Supabase.
class _StubCollectionsNotifier extends CollectionsNotifier {
  final User _user;
  _StubCollectionsNotifier(this._user);

  @override
  Future<List<Collection>> build() async => const [];

  @override
  Future<void> create(Collection collection) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(createCollectionUseCaseProvider)(
        userId: _user.id,
        collection: collection,
      );
      return const <Collection>[];
    });
  }
}

/// Habitude factice pour les tests de sélection.
final _kMockHabit = Habit(
  id: HabitId('habit-test-1'),
  userId: UserId('user-uuid-001'),
  name: NonEmptyString('Habitude test'),
  categoryId: CategoryId('cat-test'),
  frequencyType: HabitFrequencyType.daily,
  frequency: 1,
  activeDays: {1},
  isSystem: false,
);

void main() {
  late MockCollectionRepository mockRepo;

  final testUser = User(
    id: UserId('user-uuid-001'),
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: Level.aspirant,
  );

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(UserId('fallback-user'));
    registerFallbackValue(CollectionId('fallback-coll'));
    registerFallbackValue(
      Collection(
        id: CollectionId('fallback-coll'),
        name: NonEmptyString('fallback'),
        description: NonEmptyString('fallback'),
        habitIds: [HabitId('placeholder')],
        isSystem: false,
        isActive: false,
      ),
    );
  });

  Widget buildSut({
    VoidCallback? onCreated,
    VoidCallback? onCancel,
    List<Habit> habits = const [],
  }) {
    return ProviderScope(
      overrides: [
        // Fournit user + auth sans passer par Supabase.
        currentUserProvider.overrideWithValue(testUser),
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(testUser)),
        // Isole les listes de données de l'infrastructure Supabase.
        habitsNotifierProvider.overrideWith(() => _StubHabitsNotifier(habits)),
        categoriesNotifierProvider.overrideWith(
          () => _StubCategoriesNotifier(),
        ),
        collectionsNotifierProvider.overrideWith(
          () => _StubCollectionsNotifier(testUser),
        ),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Co02CreateCollectionScreen(
          onCreated: onCreated ?? () {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  testWidgets('affiche les champs titre et description', (tester) async {
    await tester.pumpWidget(buildSut());
    await tester.pump();
    // AppInput.label est rendu en majuscules (label!.toUpperCase()) — cf. app_input.dart:156.
    expect(find.text('TITRE'), findsOneWidget);
    expect(find.text('DESCRIPTION'), findsOneWidget);
  });

  testWidgets('erreur si titre vide à la soumission', (tester) async {
    await tester.pumpWidget(buildSut());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer la collection'));
    await tester.pumpAndSettle();

    expect(find.text('Titre requis'), findsOneWidget);
  });

  testWidgets('appelle createCollection et onCreated si formulaire valide', (
    tester,
  ) async {
    when(
      () => mockRepo.createCollection(
        userId: any(named: 'userId'),
        collection: any(named: 'collection'),
      ),
    ).thenAnswer(
      (_) async => Collection(
        id: CollectionId('new-coll'),
        name: NonEmptyString('Test'),
        description: NonEmptyString('Desc'),
        habitIds: [HabitId('habit-test-1')],
        isSystem: false,
        isActive: false,
      ),
    );

    var created = false;
    await tester.pumpWidget(
      buildSut(
        onCreated: () => created = true,
        // Fournit 1 habitude pour satisfaire la validation _selected.isNotEmpty.
        habits: [_kMockHabit],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Test');
    await tester.enterText(find.byType(TextField).last, 'Desc');

    // Sélectionner l'habitude factice dans le _HabitPicker.
    await tester.tap(find.text('Habitude test'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer la collection'));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    verify(
      () => mockRepo.createCollection(
        userId: any(named: 'userId'),
        collection: any(named: 'collection'),
      ),
    ).called(1);
  });
}
