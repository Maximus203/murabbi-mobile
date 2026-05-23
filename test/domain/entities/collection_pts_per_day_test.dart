import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Helpers — construction minimale d'un Habit avec des points donnés.
/// [points] = null simule une habitude user sans points fixés (#163).
Habit _habit(String id, int? points) => Habit(
  id: HabitId(id),
  name: NonEmptyString('Habit $id'),
  categoryId: CategoryId('cat-1'),
  frequencyType: HabitFrequencyType.daily,
  frequency: 1,
  activeDays: const {1},
  points: points != null ? HabitPoints(points) : null,
  isSystem: false,
);

Collection _collection(List<String> habitIds) => Collection(
  id: CollectionId('col-1'),
  name: NonEmptyString('Test collection'),
  description: NonEmptyString('desc'),
  habitIds: habitIds.map(HabitId.new).toList(),
  isSystem: false,
  isActive: false,
);

void main() {
  group('Collection.ptsPerDay', () {
    test('sums points of all matching habits', () {
      final col = _collection(['h1', 'h2', 'h3']);
      final habits = [_habit('h1', 10), _habit('h2', 5), _habit('h3', 3)];
      expect(col.ptsPerDay(habits), 18);
    });

    test('returns 0 when habits list is empty', () {
      final col = _collection(['h1']);
      expect(col.ptsPerDay([]), 0);
    });

    test('ignores habits not referenced by the collection', () {
      final col = _collection(['h1']);
      final habits = [_habit('h1', 10), _habit('h2', 7)];
      expect(col.ptsPerDay(habits), 10);
    });

    test('ignores collection habitIds not present in the habits list', () {
      // Race condition : habitude supprimée mais collection pas encore mise à jour.
      final col = _collection(['h1', 'h-deleted']);
      final habits = [_habit('h1', 10)];
      expect(col.ptsPerDay(habits), 10);
    });

    test('returns 0 when no collection habit is present in the list', () {
      final col = _collection(['h-missing']);
      final habits = [_habit('h1', 10)];
      expect(col.ptsPerDay(habits), 0);
    });

    test('handles single habit correctly', () {
      final col = _collection(['h1']);
      final habits = [_habit('h1', 8)];
      expect(col.ptsPerDay(habits), 8);
    });

    // #163 : habitude user sans points (null) → compte 0 dans ptsPerDay
    test('#163 habitude user (points null) contribue 0 à ptsPerDay', () {
      final col = _collection(['h1', 'h2']);
      final habits = [_habit('h1', 5), _habit('h2', null)];
      // h1=5 + h2=0 (null → 0 par fallback)
      expect(col.ptsPerDay(habits), 5);
    });
  });
}
