import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../helpers/in_memory_repositories.dart';
import '../../helpers/test_uuids.dart';

void main() {
  final userId = UserId(kUserIdAlpha);

  Habit makeHabit(String id, String name) => Habit(
    id: HabitId(id),
    name: NonEmptyString(name),
    categoryId: CategoryId(kCategoryIdReligion),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: const {1, 2, 3, 4, 5, 6, 7},
    points: HabitPoints(3),
    isSystem: false,
  );

  group('InMemoryHabitRepository', () {
    test('getHabits returns empty list initially', () async {
      final repo = InMemoryHabitRepository();
      expect(await repo.getHabits(userId), isEmpty);
    });

    test('createHabit persists + getHabits returns it', () async {
      final repo = InMemoryHabitRepository();
      final h = makeHabit('h1', 'Lecture Coran');
      await repo.createHabit(userId: userId, habit: h);
      final list = await repo.getHabits(userId);
      expect(list, hasLength(1));
      expect(list.first.name.value, 'Lecture Coran');
    });

    test('updateHabit replaces existing habit', () async {
      final repo = InMemoryHabitRepository();
      final h = makeHabit('h1', 'Original');
      await repo.createHabit(userId: userId, habit: h);
      final updated = Habit(
        id: HabitId('h1'),
        name: NonEmptyString('Renamed'),
        categoryId: CategoryId(kCategoryIdSport),
        frequencyType: HabitFrequencyType.daily,
        frequency: 1,
        activeDays: const {1, 2, 3, 4, 5, 6, 7},
        points: HabitPoints(5),
        isSystem: false,
      );
      await repo.updateHabit(updated);
      final list = await repo.getHabits(userId);
      expect(list.first.name.value, 'Renamed');
      expect(list.first.points?.value, 5);
    });

    test('deleteHabit removes from list', () async {
      final repo = InMemoryHabitRepository();
      await repo.createHabit(userId: userId, habit: makeHabit('h1', 'A'));
      await repo.createHabit(userId: userId, habit: makeHabit('h2', 'B'));
      await repo.deleteHabit(HabitId('h1'));
      final list = await repo.getHabits(userId);
      expect(list.map((h) => h.id.value), ['h2']);
    });

    test('updateHabit throws when habit not found', () async {
      final repo = InMemoryHabitRepository();
      expect(
        () => repo.updateHabit(makeHabit('missing', 'X')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('InMemoryCategoryRepository', () {
    test('getCategories returns the 5 system seeds', () async {
      final repo = InMemoryCategoryRepository();
      final list = await repo.getCategories(userId);
      expect(list, hasLength(5));
      expect(list.map((c) => c.name.value).toSet(), {
        'Religion',
        'Sport',
        'Santé',
        'Mental',
        'Social',
      });
      expect(list.every((c) => c.isSystem), isTrue);
    });
  });
}
