import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_collection_data_source.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockCollectionDataSource extends Mock
    implements SupabaseCollectionDataSource {}

void main() {
  late MockCollectionDataSource mockDs;
  late CollectionRepositoryImpl repo;

  final userId = UserId('user-uuid-001');
  final collectionId = CollectionId('coll-uuid-001');

  final testCollection = Collection(
    id: collectionId,
    name: NonEmptyString('Morning routine'),
    description: NonEmptyString('Start the day right'),
    habitIds: [HabitId('h-1'), HabitId('h-2')],
    isSystem: false,
    isActive: true,
  );

  setUp(() {
    mockDs = MockCollectionDataSource();
    repo = CollectionRepositoryImpl(mockDs);
    registerFallbackValue(userId);
    registerFallbackValue(collectionId);
    registerFallbackValue(testCollection);
  });

  group('CollectionRepositoryImpl.getCollections', () {
    test('retourne la liste des collections', () async {
      when(
        () => mockDs.getCollections(userId),
      ).thenAnswer((_) async => [testCollection]);

      final result = await repo.getCollections(userId);

      expect(result, [testCollection]);
      verify(() => mockDs.getCollections(userId)).called(1);
    });

    test('traduit PostgrestException en CollectionDatabaseFailure', () async {
      when(
        () => mockDs.getCollections(userId),
      ).thenThrow(const sb.PostgrestException(message: 'DB error'));

      expect(
        () => repo.getCollections(userId),
        throwsA(isA<CollectionDatabaseFailure>()),
      );
    });

    test('propage CollectionFailure telle quelle', () async {
      when(
        () => mockDs.getCollections(userId),
      ).thenThrow(const CollectionFailure.network());

      expect(
        () => repo.getCollections(userId),
        throwsA(isA<CollectionNetworkFailure>()),
      );
    });
  });

  group('CollectionRepositoryImpl.activateCollection', () {
    test('délègue au datasource sans erreur', () async {
      when(
        () => mockDs.activateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).thenAnswer((_) async {});

      await repo.activateCollection(userId: userId, collectionId: collectionId);

      verify(
        () => mockDs.activateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).called(1);
    });

    test('traduit PostgrestException en CollectionDatabaseFailure', () async {
      when(
        () => mockDs.activateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).thenThrow(const sb.PostgrestException(message: 'DB error'));

      expect(
        () =>
            repo.activateCollection(userId: userId, collectionId: collectionId),
        throwsA(isA<CollectionDatabaseFailure>()),
      );
    });
  });

  group('CollectionRepositoryImpl.deactivateCollection', () {
    test('délègue au datasource sans erreur', () async {
      when(
        () => mockDs.deactivateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).thenAnswer((_) async {});

      await repo.deactivateCollection(
        userId: userId,
        collectionId: collectionId,
      );

      verify(
        () => mockDs.deactivateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).called(1);
    });
  });

  group('CollectionRepositoryImpl.createCollection', () {
    test('crée et retourne la collection', () async {
      when(
        () =>
            mockDs.createCollection(collection: testCollection, userId: userId),
      ).thenAnswer((_) async => testCollection);

      final result = await repo.createCollection(
        userId: userId,
        collection: testCollection,
      );

      expect(result, testCollection);
    });

    test('traduit les erreurs inconnues en CollectionUnknownFailure', () async {
      when(
        () =>
            mockDs.createCollection(collection: testCollection, userId: userId),
      ).thenThrow(Exception('unexpected'));

      expect(
        () => repo.createCollection(userId: userId, collection: testCollection),
        throwsA(isA<CollectionUnknownFailure>()),
      );
    });
  });
}
