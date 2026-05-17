import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepo;
  final userId = UserId('user-uuid-001');

  final testUser = User(
    id: userId,
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: Level.aspirant,
  );

  final collection1 = Collection(
    id: CollectionId('coll-1'),
    name: NonEmptyString('Routine matinale'),
    description: NonEmptyString('Commencer la journée'),
    habitIds: [HabitId('h-1')],
    isSystem: true,
    isActive: false,
  );

  final collection2 = Collection(
    id: CollectionId('coll-2'),
    name: NonEmptyString('Sport hebdo'),
    description: NonEmptyString('Activité physique'),
    habitIds: [HabitId('h-2'), HabitId('h-3')],
    isSystem: false,
    isActive: true,
  );

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(CollectionId('fallback-coll'));
    registerFallbackValue(userId);
    registerFallbackValue(collection1);
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('CollectionsNotifier', () {
    test('build charge les collections de l\'utilisateur', () async {
      when(() => mockRepo.getCollections(userId))
          .thenAnswer((_) async => [collection1, collection2]);

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(collectionsNotifierProvider.future);

      expect(result, [collection1, collection2]);
    });

    test('build retourne [] si user null', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          collectionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(collectionsNotifierProvider.future);
      expect(result, isEmpty);
    });

    test('activate appelle repository.activateCollection et refresh', () async {
      when(() => mockRepo.getCollections(userId))
          .thenAnswer((_) async => [collection1]);
      when(
        () => mockRepo.activateCollection(
          userId: userId,
          collectionId: collection1.id,
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      // Attendre le build initial
      await container.read(collectionsNotifierProvider.future);

      // Activer
      await container
          .read(collectionsNotifierProvider.notifier)
          .activate(collection1.id);

      verify(
        () => mockRepo.activateCollection(
          userId: userId,
          collectionId: collection1.id,
        ),
      ).called(1);
    });

    test('deactivate appelle repository.deactivateCollection et refresh', () async {
      when(() => mockRepo.getCollections(userId))
          .thenAnswer((_) async => [collection2]);
      when(
        () => mockRepo.deactivateCollection(
          userId: userId,
          collectionId: collection2.id,
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(collectionsNotifierProvider.future);

      await container
          .read(collectionsNotifierProvider.notifier)
          .deactivate(collection2.id);

      verify(
        () => mockRepo.deactivateCollection(
          userId: userId,
          collectionId: collection2.id,
        ),
      ).called(1);
    });
  });
}
