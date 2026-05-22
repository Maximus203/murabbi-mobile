import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/collection_data_source.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockCollectionDataSource extends Mock implements CollectionDataSource {}

void main() {
  late MockCollectionDataSource ds;
  late CollectionRepositoryImpl repo;
  final userId = UserId('u-1');

  setUp(() {
    ds = MockCollectionDataSource();
    repo = CollectionRepositoryImpl(ds);
  });

  group('getCollections', () {
    test('mappe les rows datasource en entités Collection', () async {
      when(() => ds.getCollections('u-1')).thenAnswer(
        (_) async => [
          {
            'id': 'c-1',
            'name': 'Matin',
            'description': 'Routine',
            'is_system': true,
            'collection_habits': [
              {'habit_id': 'h-1'},
            ],
            'user_collections': [
              {'user_id': 'u-1'},
            ],
          },
        ],
      );

      final result = await repo.getCollections(userId);

      expect(result, hasLength(1));
      expect(result.first.id, CollectionId('c-1'));
      expect(result.first.isActive, true);
    });
  });

  group('activateCollection', () {
    test('délègue au datasource avec les bons ids', () async {
      when(
        () => ds.activateCollection(userId: 'u-1', collectionId: 'c-9'),
      ).thenAnswer((_) async {});

      await repo.activateCollection(
        userId: userId,
        collectionId: CollectionId('c-9'),
      );

      verify(
        () => ds.activateCollection(userId: 'u-1', collectionId: 'c-9'),
      ).called(1);
    });
  });

  group('createCollection', () {
    test(
      'insère la collection, lie les habitudes et renvoie l\'entité',
      () async {
        final collection = Collection(
          id: CollectionId('c-new'),
          name: NonEmptyString('Lecture'),
          description: NonEmptyString('Coran'),
          habitIds: [HabitId('h-1'), HabitId('h-2')],
          isSystem: false,
          isActive: false,
        );

        when(() => ds.createCollection(any())).thenAnswer(
          (_) async => {
            'id': 'c-new',
            'name': 'Lecture',
            'description': 'Coran',
            'is_system': false,
          },
        );
        when(
          () => ds.linkHabits(
            collectionId: any(named: 'collectionId'),
            habitIds: any(named: 'habitIds'),
          ),
        ).thenAnswer((_) async {});

        final result = await repo.createCollection(
          userId: userId,
          collection: collection,
        );

        expect(result.id, CollectionId('c-new'));
        expect(result.habitIds, [HabitId('h-1'), HabitId('h-2')]);
        verify(
          () => ds.linkHabits(collectionId: 'c-new', habitIds: ['h-1', 'h-2']),
        ).called(1);
      },
    );
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
        () => mockDs.getHabitsForCollection(collectionId.value),
      ).thenAnswer((_) async => expected);

      final result = await repo.getHabitsForCollection(
        collectionId: collectionId,
      );

      expect(result, expected);
      verify(() => mockDs.getHabitsForCollection(collectionId.value)).called(1);
    });

    test('traduit PostgrestException en CollectionDatabaseFailure', () async {
      when(
        () => mockDs.getHabitsForCollection(collectionId.value),
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
          () => mockDs.getHabitsForCollection(collectionId.value),
        ).thenAnswer((_) async => []);

        final result = await repo.getHabitsForCollection(
          collectionId: collectionId,
        );

        expect(result, isEmpty);
      },
    );
  });
}
