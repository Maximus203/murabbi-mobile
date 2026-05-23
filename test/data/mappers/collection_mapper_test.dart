import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/collection_mapper.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Mapper pur — rows Supabase `collections` + agrégation `habitIds` depuis
/// `published_catalog` ↔ entité [Collection] (issue #162).
///
/// Après la migration issue #162, la row passée à [CollectionMapper.fromRow]
/// ne contient PLUS de clé `collection_habits`. Les `habitIds` sont transmis
/// directement via la clé `habit_ids` (liste de strings), construite par le
/// datasource après interrogation de `published_catalog`.
void main() {
  group('CollectionMapper.fromRow', () {
    test('mappe une collection système active (structure post-#162)', () {
      // Structure attendue après migration : habit_ids est une liste de
      // strings, pas une liste d'objets imbriqués collection_habits.
      final row = {
        'id': 'coll-1',
        'name': 'Routine du matin',
        'description': 'Bien démarrer la journée',
        'is_system': true,
        'cover_image_url': 'https://cdn/x.jpg',
        'habit_ids': ['h-1', 'h-2'],
        'user_collections': [
          {'user_id': 'u-1'},
        ],
      };

      final c = CollectionMapper.fromRow(row);

      expect(c.id, CollectionId('coll-1'));
      expect(c.name.value, 'Routine du matin');
      expect(c.isSystem, true);
      expect(c.isActive, true);
      expect(c.habitIds, [HabitId('h-1'), HabitId('h-2')]);
      expect(c.coverImageUrl, 'https://cdn/x.jpg');
    });

    test('collection inactive quand user_collections vide', () {
      final row = {
        'id': 'coll-2',
        'name': 'Soir',
        'description': 'Routine du soir',
        'is_system': false,
        'cover_image_url': null,
        'habit_ids': ['h-9'],
        'user_collections': <dynamic>[],
      };

      final c = CollectionMapper.fromRow(row);

      expect(c.isActive, false);
      expect(c.isSystem, false);
      expect(c.coverImageUrl, isNull);
    });

    test(
      'collection sans habit_ids → habitIds vide (garde contre données corrompues)',
      () {
        final row = {
          'id': 'coll-3',
          'name': 'Vide',
          'description': 'Collection sans habitudes',
          'is_system': false,
          'cover_image_url': null,
          'habit_ids': null,
          'user_collections': <dynamic>[],
        };

        // Collection.habitIds doit être non-vide selon l'entité domain.
        // Le mapper délègue la validation à l'entité — si habit_ids est null
        // ou vide, le datasource doit filtrer en amont.
        // Ici on vérifie que fromRow ne plante pas sur null.
        expect(() => CollectionMapper.fromRow(row), returnsNormally);
      },
    );

    test("n'attend pas la clé collection_habits (migration issue #162)", () {
      // Ce test documente l'invariant post-migration : fromRow ne doit PAS
      // lire `collection_habits` dans la row.
      final rowSansCollectionHabits = {
        'id': 'coll-4',
        'name': 'Test',
        'description': 'Sans collection_habits',
        'is_system': false,
        'cover_image_url': null,
        'habit_ids': ['h-x'],
        'user_collections': <dynamic>[],
        // Pas de clé 'collection_habits' — doit fonctionner sans
      };

      expect(
        () => CollectionMapper.fromRow(rowSansCollectionHabits),
        returnsNormally,
        reason:
            'fromRow ne doit pas lire collection_habits après migration #162',
      );
    });
  });

  group('CollectionMapper.toRow', () {
    test('sérialise les champs persistables (sans habitIds joints)', () {
      final c = Collection(
        id: CollectionId('coll-5'),
        name: NonEmptyString('Lecture'),
        description: NonEmptyString('Coran quotidien'),
        habitIds: [HabitId('h-5')],
        isSystem: false,
        isActive: false,
      );

      final row = CollectionMapper.toRow(c);

      expect(row['id'], 'coll-5');
      expect(row['name'], 'Lecture');
      expect(row['description'], 'Coran quotidien');
      expect(row['is_system'], false);
      expect(row.containsKey('is_active'), false);
      // habit_ids n'est pas persisté dans `collections` — géré par
      // published_catalog (view read-only) et collection_habits (admin only).
      expect(row.containsKey('habit_ids'), false);
    });
  });

  group('CollectionMapper.fromPublishedCatalogRows', () {
    test('extrait les habit_ids depuis les rows published_catalog', () {
      // Colonnes de published_catalog : collection_id, habit_id, position,
      // collection_name, collection_description, cover_image_url, icon,
      // primary_category_id, category_name, category_color.
      final rows = [
        {'collection_id': 'coll-A', 'habit_id': 'h-1', 'position': 1},
        {'collection_id': 'coll-A', 'habit_id': 'h-2', 'position': 2},
        {'collection_id': 'coll-A', 'habit_id': 'h-3', 'position': 3},
      ];

      final habitIds = CollectionMapper.habitIdsFromCatalogRows(rows);

      expect(habitIds, [HabitId('h-1'), HabitId('h-2'), HabitId('h-3')]);
    });

    test('retourne liste vide si rows vides', () {
      final habitIds = CollectionMapper.habitIdsFromCatalogRows([]);
      expect(habitIds, isEmpty);
    });

    test('respecte le tri par position', () {
      // Les rows arrivent de Supabase triées par position ASC.
      // Le mapper préserve l'ordre.
      final rows = [
        {'collection_id': 'coll-B', 'habit_id': 'h-10', 'position': 1},
        {'collection_id': 'coll-B', 'habit_id': 'h-20', 'position': 2},
      ];

      final habitIds = CollectionMapper.habitIdsFromCatalogRows(rows);

      expect(habitIds.first, HabitId('h-10'));
      expect(habitIds.last, HabitId('h-20'));
    });
  });
}
