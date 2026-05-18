import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_filter.dart';

/// Crée une habitude de test paramétrable.
Habit _habit(
  String id,
  String name, {
  String categoryId = 'cat-religion',
  int points = 3,
  Set<int> activeDays = const {1, 2, 3, 4, 5, 6, 7},
}) => Habit(
  id: HabitId(id),
  name: NonEmptyString(name),
  categoryId: CategoryId(categoryId),
  frequencyType: HabitFrequencyType.weekly,
  frequency: 1,
  activeDays: activeDays,
  points: HabitPoints(points),
  isSystem: false,
);

void main() {
  // Référence : un lundi (weekday == 1).
  final monday = DateTime.utc(2026, 5, 18);

  group('HabitsFilter — recherche full-text sur le nom', () {
    test(
      'filtre les habitudes dont le nom contient la query (insensible casse)',
      () {
        final habits = [
          _habit('h1', 'Lecture Coran'),
          _habit('h2', 'Sport matinal'),
          _habit('h3', 'Méditation'),
        ];
        final filter = HabitsFilter(query: 'coran', referenceDate: monday);

        final result = filter.apply(habits);

        expect(result.map((h) => h.id.value), ['h1']);
      },
    );

    test('query vide ne filtre rien', () {
      final habits = [_habit('h1', 'A'), _habit('h2', 'B')];
      final filter = HabitsFilter(referenceDate: monday);

      expect(filter.apply(habits), hasLength(2));
    });

    test('query avec espaces autour est trimée', () {
      final habits = [_habit('h1', 'Coran'), _habit('h2', 'Sport')];
      final filter = HabitsFilter(query: '  coran  ', referenceDate: monday);

      expect(filter.apply(habits).map((h) => h.id.value), ['h1']);
    });
  });

  group('HabitsFilter — filtre par statut', () {
    test('all retourne toutes les habitudes', () {
      final habits = [
        _habit('h1', 'A', activeDays: {1}),
        _habit('h2', 'B', activeDays: {3}),
      ];
      final filter = HabitsFilter(
        status: HabitFilterStatus.all,
        referenceDate: monday,
      );

      expect(filter.apply(habits), hasLength(2));
    });

    test('active retient les habitudes programmées le jour de référence', () {
      final habits = [
        _habit('h1', 'Lundi', activeDays: {1}),
        _habit('h2', 'Mardi', activeDays: {2}),
      ];
      final filter = HabitsFilter(
        status: HabitFilterStatus.active,
        referenceDate: monday,
      );

      expect(filter.apply(habits).map((h) => h.id.value), ['h1']);
    });

    test(
      'inactive retient les habitudes non programmées le jour de référence',
      () {
        final habits = [
          _habit('h1', 'Lundi', activeDays: {1}),
          _habit('h2', 'Mardi', activeDays: {2}),
        ];
        final filter = HabitsFilter(
          status: HabitFilterStatus.inactive,
          referenceDate: monday,
        );

        expect(filter.apply(habits).map((h) => h.id.value), ['h2']);
      },
    );
  });

  group('HabitsFilter — tri', () {
    test('tri par nom A-Z', () {
      final habits = [
        _habit('h1', 'Zakat'),
        _habit('h2', 'Ablution'),
        _habit('h3', 'Méditation'),
      ];
      final filter = HabitsFilter(
        sortBy: HabitSortBy.name,
        referenceDate: monday,
      );

      expect(filter.apply(habits).map((h) => h.name.value), [
        'Ablution',
        'Méditation',
        'Zakat',
      ]);
    });

    test('tri par points décroissant', () {
      final habits = [
        _habit('h1', 'A', points: 2),
        _habit('h2', 'B', points: 9),
        _habit('h3', 'C', points: 5),
      ];
      final filter = HabitsFilter(
        sortBy: HabitSortBy.points,
        referenceDate: monday,
      );

      expect(filter.apply(habits).map((h) => h.id.value), ['h2', 'h3', 'h1']);
    });

    test('tri par catégorie (ordre alphabétique de categoryId)', () {
      final habits = [
        _habit('h1', 'A', categoryId: 'cat-sport'),
        _habit('h2', 'B', categoryId: 'cat-religion'),
      ];
      final filter = HabitsFilter(
        sortBy: HabitSortBy.category,
        referenceDate: monday,
      );

      expect(filter.apply(habits).map((h) => h.id.value), ['h2', 'h1']);
    });

    test('tri createdAt utilise id.value comme proxy (ordre stable)', () {
      final habits = [_habit('h3', 'C'), _habit('h1', 'A'), _habit('h2', 'B')];
      final filter = HabitsFilter(
        sortBy: HabitSortBy.createdAt,
        referenceDate: monday,
      );

      expect(filter.apply(habits).map((h) => h.id.value), ['h1', 'h2', 'h3']);
    });
  });

  group('HabitsFilter — combinaison recherche + filtre + tri', () {
    test('applique recherche puis filtre statut puis tri', () {
      final habits = [
        _habit('h1', 'Coran soir', activeDays: {1}, points: 2),
        _habit('h2', 'Coran matin', activeDays: {1}, points: 8),
        _habit('h3', 'Coran nuit', activeDays: {2}, points: 5),
        _habit('h4', 'Sport', activeDays: {1}, points: 9),
      ];
      final filter = HabitsFilter(
        query: 'coran',
        status: HabitFilterStatus.active,
        sortBy: HabitSortBy.points,
        referenceDate: monday,
      );

      // 'coran' garde h1/h2/h3 ; active(lundi) garde h1/h2 ; tri points → h2,h1.
      expect(filter.apply(habits).map((h) => h.id.value), ['h2', 'h1']);
    });
  });

  group('HabitsFilter — groupement par catégorie', () {
    test('groupBy retourne les habitudes regroupées par categoryId', () {
      final habits = [
        _habit('h1', 'A', categoryId: 'cat-religion'),
        _habit('h2', 'B', categoryId: 'cat-sport'),
        _habit('h3', 'C', categoryId: 'cat-religion'),
      ];
      final filter = HabitsFilter(referenceDate: monday);

      final groups = filter.groupByCategory(habits);

      expect(groups.keys, containsAll(['cat-religion', 'cat-sport']));
      expect(groups['cat-religion']!.map((h) => h.id.value), ['h1', 'h3']);
      expect(groups['cat-sport']!.map((h) => h.id.value), ['h2']);
    });
  });

  group('HabitsFilter — copyWith', () {
    test('copyWith modifie uniquement les champs fournis', () {
      const base = HabitsFilter(status: HabitFilterStatus.active);
      final updated = base.copyWith(query: 'x');

      expect(updated.query, 'x');
      expect(updated.status, HabitFilterStatus.active);
      expect(updated.sortBy, base.sortBy);
    });
  });
}
