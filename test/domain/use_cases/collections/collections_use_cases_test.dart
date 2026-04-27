import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/activate_collection_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/create_collection_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/get_collections_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepo;
  final userId = UserId('user-uuid-001');

  final testCollection = Collection(
    id: CollectionId('coll-uuid-001'),
    name: NonEmptyString('Morning routine'),
    description: NonEmptyString('Start the day right'),
    habitIds: [HabitId('h-1'), HabitId('h-2')],
    isSystem: false,
    isActive: false,
  );

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(testCollection);
    registerFallbackValue(CollectionId('fallback-coll-id'));
  });

  group('GetCollectionsUseCase', () {
    late GetCollectionsUseCase useCase;

    setUp(() => useCase = GetCollectionsUseCase(mockRepo));

    test('calls repository.getCollections and returns list', () async {
      when(() => mockRepo.getCollections(userId))
          .thenAnswer((_) async => [testCollection]);

      final result = await useCase(userId);

      expect(result, [testCollection]);
      verify(() => mockRepo.getCollections(userId)).called(1);
    });
  });

  group('ActivateCollectionUseCase', () {
    late ActivateCollectionUseCase useCase;
    final collectionId = CollectionId('coll-uuid-001');

    setUp(() => useCase = ActivateCollectionUseCase(mockRepo));

    test('calls repository.activateCollection with correct params', () async {
      when(
        () => mockRepo.activateCollection(
          userId: userId,
          collectionId: collectionId,
        ),
      ).thenAnswer((_) async {});

      await useCase(userId: userId, collectionId: collectionId);

      verify(
        () => mockRepo.activateCollection(
          userId: userId,
          collectionId: collectionId,
        ),
      ).called(1);
    });
  });

  group('CreateCollectionUseCase', () {
    late CreateCollectionUseCase useCase;

    setUp(() => useCase = CreateCollectionUseCase(mockRepo));

    test('calls repository.createCollection and returns collection', () async {
      when(
        () => mockRepo.createCollection(
          userId: userId,
          collection: testCollection,
        ),
      ).thenAnswer((_) async => testCollection);

      final result = await useCase(
        userId: userId,
        collection: testCollection,
      );

      expect(result, testCollection);
      verify(
        () => mockRepo.createCollection(
          userId: userId,
          collection: testCollection,
        ),
      ).called(1);
    });
  });
}
