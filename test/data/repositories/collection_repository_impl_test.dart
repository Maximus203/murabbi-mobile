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

class MockSupabaseCollectionDataSource extends Mock
    implements SupabaseCollectionDataSource {}

Collection _collection({
  String id = 'c-1',
  String name = 'Matin',
  bool isSystem = false,
  bool isActive = false,
  List<String>? habitIds,
}) => Collection(
  id: CollectionId(id),
  name: NonEmptyString(name),
  description: NonEmptyString('Desc'),
  habitIds: (habitIds ?? ['h-1']).map(HabitId.new).toList(),
  isSystem: isSystem,
  isActive: isActive,
);

void main() {
  late MockSupabaseCollectionDataSource ds;
  late CollectionRepositoryImpl repo;
  final userId = UserId('u-1');
  final collectionId = CollectionId('c-1');

  setUp(() {
    ds = MockSupabaseCollectionDataSource();
    repo = CollectionRepositoryImpl(ds);
  });

  group('getCollections', () {
    test('délègue au datasource et retourne les entités Collection', () async {
      final expected = [_collection()];
      when(() => ds.getCollections(userId)).thenAnswer((_) async => expected);

      final result = await repo.getCollections(userId);

      expect(result, expected);
      verify(() => ds.getCollections(userId)).called(1);
    });
  });

  group('activateCollection', () {
    test('délègue au datasource avec les bons ids', () async {
      when(
        () => ds.activateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).thenAnswer((_) async {});

      await repo.activateCollection(
        userId: userId,
        collectionId: collectionId,
      );

      verify(
        () => ds.activateCollection(
          collectionId: collectionId,
          userId: userId,
        ),
      ).called(1);
    });
  });

  group('createCollection', () {
    test('délègue au datasource et renvoie l\'entité créée', () async {
      final collection = _collection(id: 'c-new', name: 'Lecture');

      when(
        () => ds.createCollection(collection: collection, userId: userId),
      ).thenAnswer((_) async => collection);

      final result = await repo.createCollection(
        userId: userId,
        collection: collection,
      );

      expect(result.id, CollectionId('c-new'));
      verify(
        () => ds.createCollection(collection: collection, userId: userId),
      ).called(1);
    });
  });

  group('CollectionRepositoryImpl.getHabitsForCollection', () {
    // Tests couvrant la migration issue #162 : published_catalog remplace
    // les accès directs à collection_habits (RLS révoquée).
    test('délègue au datasource et retourne la liste de rows', () async {
      final expected = [
        {'habit_id': 'h-1', 'position': 1},
        {'habit_id': 'h-2', 'position': 2},
      ];
      when(
        () => ds.getHabitsForCollection(collectionId.value),
      ).thenAnswer((_) async => expected);

      final result = await repo.getHabitsForCollection(
        collectionId: collectionId,
      );

      expect(result, expected);
      verify(() => ds.getHabitsForCollection(collectionId.value)).called(1);
    });

    test('traduit PostgrestException en CollectionDatabaseFailure', () async {
      when(
        () => ds.getHabitsForCollection(collectionId.value),
      ).thenThrow(const sb.PostgrestException(message: 'RLS denied'));

      expect(
        () => repo.getHabitsForCollection(collectionId: collectionId),
        throwsA(isA<CollectionDatabaseFailure>()),
      );
    });

    test(
      'retourne liste vide si collection sans habits dans published_catalog',
      () async {
        when(
          () => ds.getHabitsForCollection(collectionId.value),
        ).thenAnswer((_) async => []);

        final result = await repo.getHabitsForCollection(
          collectionId: collectionId,
        );

        expect(result, isEmpty);
      },
    );
  });
}
