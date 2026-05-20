import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

Habit _habit(String id, int pts) => Habit(
      id: HabitId(id),
      name: NonEmptyString('Habit $id'),
      categoryId: CategoryId('cat-1'),
      frequencyType: HabitFrequencyType.daily,
      frequency: 1,
      activeDays: const {1, 2, 3, 4, 5, 6, 7},
      points: HabitPoints(pts),
      isSystem: false,
      target: const HabitTarget.none(),
      subtasks: const [],
    );

Collection _collection(List<String> habitIds) => Collection(
      id: CollectionId('col-1'),
      name: NonEmptyString('Test Collection'),
      description: NonEmptyString('Desc'),
      habitIds: habitIds.map(HabitId.new).toList(),
      isSystem: false,
      isActive: false,
    );

void main() {
  group('Collection.ptsPerDay', () {
    test('somme correcte de 3 habitudes incluses', () {
      final habits = [_habit('h1', 3), _habit('h2', 5), _habit('h3', 7)];
      final collection = _collection(['h1', 'h2', 'h3']);
      expect(collection.ptsPerDay(habits), 15);
    });

    test('retourne 0 si la liste d\'habitudes est vide', () {
      final collection = _collection(['h1']);
      expect(collection.ptsPerDay([]), 0);
    });

    test('ignore les habitudes non référencées par la collection', () {
      final habits = [_habit('h1', 4), _habit('h2', 6), _habit('h99', 8)];
      final collection = _collection(['h1', 'h2']);
      expect(collection.ptsPerDay(habits), 10);
    });

    test('ignore les habitIds absents de la liste (race/suppression)', () {
      final habits = [_habit('h1', 10)];
      final collection = _collection(['h1', 'h-deleted']);
      expect(collection.ptsPerDay(habits), 10);
    });

    test('retourne 0 si aucune habitude de la collection n\'est présente', () {
      final habits = [_habit('hX', 5)];
      final collection = _collection(['h1', 'h2']);
      expect(collection.ptsPerDay(habits), 0);
    });

    test('cas nominal à 1 habitude', () {
      final habits = [_habit('h1', 7)];
      final collection = _collection(['h1']);
      expect(collection.ptsPerDay(habits), 7);
    });
  });
}
