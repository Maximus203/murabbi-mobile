import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/deactivate_collection_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepo;
  final userId = UserId('user-uuid-001');
  final collectionId = CollectionId('coll-uuid-001');

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(CollectionId('fallback-coll-id'));
    registerFallbackValue(UserId('fallback-user-id'));
  });

  group('DeactivateCollectionUseCase', () {
    late DeactivateCollectionUseCase useCase;

    setUp(() => useCase = DeactivateCollectionUseCase(mockRepo));

    test(
      'délègue à repository.deactivateCollection avec les bons paramètres',
      () async {
        when(
          () => mockRepo.deactivateCollection(
            userId: userId,
            collectionId: collectionId,
          ),
        ).thenAnswer((_) async {});

        await useCase(userId: userId, collectionId: collectionId);

        verify(
          () => mockRepo.deactivateCollection(
            userId: userId,
            collectionId: collectionId,
          ),
        ).called(1);
      },
    );

    test('propage les exceptions du repository', () async {
      when(
        () => mockRepo.deactivateCollection(
          userId: userId,
          collectionId: collectionId,
        ),
      ).thenThrow(Exception('DB error'));

      expect(
        () => useCase(userId: userId, collectionId: collectionId),
        throwsException,
      );
    });
  });
}
