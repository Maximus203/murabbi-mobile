import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/collection_mapper.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Mapper pur — rows Supabase `collections` (+ jointure `collection_habits`,
/// `user_collections`) ↔ entité [Collection] (issue #6, Phase 5).
void main() {
  group('CollectionMapper.fromRow', () {
    test('mappe une collection système active', () {
      final row = {
        'id': 'coll-1',
        'name': 'Routine du matin',
        'description': 'Bien démarrer la journée',
        'is_system': true,
        'cover_image_url': 'https://cdn/x.jpg',
        'collection_habits': [
          {'habit_id': 'h-1'},
          {'habit_id': 'h-2'},
        ],
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
        'collection_habits': [
          {'habit_id': 'h-9'},
        ],
        'user_collections': <dynamic>[],
      };

      final c = CollectionMapper.fromRow(row);

      expect(c.isActive, false);
      expect(c.isSystem, false);
      expect(c.coverImageUrl, isNull);
    });
  });

  group('CollectionMapper.toRow', () {
    test('sérialise les champs persistables (sans habitIds joints)', () {
      final c = Collection(
        id: CollectionId('coll-3'),
        name: NonEmptyString('Lecture'),
        description: NonEmptyString('Coran quotidien'),
        habitIds: [HabitId('h-5')],
        isSystem: false,
        isActive: false,
      );

      final row = CollectionMapper.toRow(c);

      expect(row['id'], 'coll-3');
      expect(row['name'], 'Lecture');
      expect(row['description'], 'Coran quotidien');
      expect(row['is_system'], false);
      expect(row.containsKey('is_active'), false);
    });
  });
}
