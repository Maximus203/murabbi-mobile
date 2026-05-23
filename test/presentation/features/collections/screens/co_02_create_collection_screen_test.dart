import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
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
import 'package:murabbi_mobile/presentation/features/collections/screens/co_02_create_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

/// Stub de HabitsNotifier pour isoler les tests CO-02 de l'auth réelle.
/// Retourne une liste fixe de [List<Habit>] sans toucher à authNotifierProvider.
class _StubHabitsNotifier extends AsyncNotifier<List<Habit>> {
  final List<Habit> _habits;
  _StubHabitsNotifier(this._habits);

  @override
  Future<List<Habit>> build() async => _habits;
}

/// Habitude factice pour les tests de sélection.
final _kMockHabit = Habit(
  id: HabitId('habit-test-1'),
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
        currentUserProvider.overrideWithValue(testUser),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
        // Stub habitsNotifierProvider pour éviter la dépendance sur authNotifierProvider
        // qui n'est pas initialisé dans l'environnement de test.
        habitsNotifierProvider.overrideWith(() => _StubHabitsNotifier(habits)),
      ],
      child: MaterialApp(
        home: Co02CreateCollectionScreen(
          onCreated: onCreated ?? () {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  testWidgets('affiche les champs nom et description', (tester) async {
    await tester.pumpWidget(buildSut());
    await tester.pumpAndSettle();
    // Trouvés via key sémantique — robuste au toUpperCase() du label AppInput.
    expect(find.byKey(const Key('field_name')), findsOneWidget);
    expect(find.byKey(const Key('field_description')), findsOneWidget);
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

    // getCollections est appelé par CollectionsNotifier.build() après create
    when(() => mockRepo.getCollections(any())).thenAnswer((_) async => []);

    var created = false;
    await tester.pumpWidget(
      buildSut(
        onCreated: () => created = true,
        // On passe 1 habitude factice pour que _isValid puisse être true.
        habits: [_kMockHabit],
      ),
    );
    await tester.pumpAndSettle();

    // Remplir le titre et la description via les keys sémantiques
    await tester.enterText(find.byKey(const Key('field_name')), 'Test');
    await tester.enterText(find.byKey(const Key('field_description')), 'Desc');

    // Sélectionner l'habitude factice dans la grille _HabitPicker
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
