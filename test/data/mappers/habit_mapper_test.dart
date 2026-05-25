import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/habit_mapper.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';
import 'package:murabbi_mobile/domain/value_objects/time_of_day_value.dart';
import '../../helpers/test_uuids.dart';

void main() {
  Map<String, dynamic> baseRow() => {
    'id': kHabitIdAlpha,
    'name': 'Lire le Coran',
    'category_id': kCategoryIdReligion,
    'frequency_type': 'daily',
    'frequency': 1,
    'monthly_day': null,
    'range_start': null,
    'range_end': null,
    'active_days': [1, 2, 3, 4, 5, 6, 7],
    'points': 5,
    'is_system': false,
    'target_value': null,
    'target_unit': null,
    'target_unit_custom': null,
    'has_timer': false,
    'subtasks_required': false,
  };

  group('HabitMapper.fromRow', () {
    test('maps a minimal daily habit with all optional columns null', () {
      final habit = HabitMapper.fromRow(baseRow());

      expect(habit.id, HabitId(kHabitIdAlpha));
      expect(habit.name, NonEmptyString('Lire le Coran'));
      expect(habit.categoryId, CategoryId(kCategoryIdReligion));
      expect(habit.frequencyType, HabitFrequencyType.daily);
      expect(habit.frequency, 1);
      expect(habit.monthlyDay, isNull);
      expect(habit.rangeStart, isNull);
      expect(habit.rangeEnd, isNull);
      expect(habit.activeDays, {1, 2, 3, 4, 5, 6, 7});
      expect(habit.points, HabitPoints(5));
      expect(habit.isSystem, false);
      expect(habit.target, const HabitTarget.none());
      expect(habit.subtasksAllRequired, false);
    });

    test('maps a monthly habit with monthly_day set', () {
      final row = baseRow()
        ..['frequency_type'] = 'monthly'
        ..['monthly_day'] = 15;
      final habit = HabitMapper.fromRow(row);
      expect(habit.frequencyType, HabitFrequencyType.monthly);
      expect(habit.monthlyDay, 15);
    });

    test('maps a habit with a time range', () {
      final row = baseRow()
        ..['range_start'] = '06:00'
        ..['range_end'] = '09:30';
      final habit = HabitMapper.fromRow(row);
      expect(habit.rangeStart, TimeOfDayValue(6, 0));
      expect(habit.rangeEnd, TimeOfDayValue(9, 30));
    });

    test('maps a v1.5 habit with a numeric target (no timer)', () {
      final row = baseRow()
        ..['target_value'] = 10
        ..['target_unit'] = 'pages';
      final habit = HabitMapper.fromRow(row);
      final target = habit.target;
      expect(target, isA<HabitTargetValue>());
      target as HabitTargetValue;
      expect(target.value, TargetValue(10));
      expect(target.unit, TargetUnit.pages);
    });

    test('maps a v1.5 habit with a timed target', () {
      final row = baseRow()
        ..['target_value'] = 30
        ..['target_unit'] = 'minutes'
        ..['has_timer'] = true;
      final habit = HabitMapper.fromRow(row);
      expect(habit.target, isA<HabitTargetTimed>());
    });

    test('maps a custom-unit target with target_unit_custom', () {
      final row = baseRow()
        ..['target_value'] = 3
        ..['target_unit'] = 'custom'
        ..['target_unit_custom'] = 'séances';
      final habit = HabitMapper.fromRow(row);
      final target = habit.target as HabitTargetValue;
      expect(target.unit, TargetUnit.custom);
      expect(target.customLabel, 'séances');
    });

    // ── #163 : points nullable ────────────────────────────────────────────────

    test('#163 fromRow avec points null → habit.points == null', () {
      final row = baseRow()..['points'] = null;
      final habit = HabitMapper.fromRow(row);
      // habitude utilisateur : points non fixés, doit être null
      expect(habit.points, isNull);
    });

    test('#163 fromRow avec points = 5 → habit.points == HabitPoints(5)', () {
      final row = baseRow()..['points'] = 5;
      final habit = HabitMapper.fromRow(row);
      expect(habit.points, HabitPoints(5));
    });
  });

  group('HabitMapper.toRow', () {
    test('round-trips a minimal daily habit', () {
      final habit = HabitMapper.fromRow(baseRow());
      final row = HabitMapper.toRow(habit);
      expect(row['name'], 'Lire le Coran');
      expect(row['category_id'], kCategoryIdReligion);
      expect(row['frequency_type'], 'daily');
      expect(row['monthly_day'], isNull);
      expect(row['range_start'], isNull);
      expect(row['target_value'], isNull);
      expect(row['has_timer'], false);
    });

    test('round-trips a v1.5 timed-target habit', () {
      final row = baseRow()
        ..['target_value'] = 30
        ..['target_unit'] = 'minutes'
        ..['has_timer'] = true;
      final habit = HabitMapper.fromRow(row);
      final out = HabitMapper.toRow(habit);
      expect(out['target_value'], 30);
      expect(out['target_unit'], 'minutes');
      expect(out['has_timer'], true);
    });

    test('round-trips a habit with time range', () {
      final row = baseRow()
        ..['range_start'] = '06:00'
        ..['range_end'] = '09:30';
      final out = HabitMapper.toRow(HabitMapper.fromRow(row));
      expect(out['range_start'], '06:00');
      expect(out['range_end'], '09:30');
    });

    // ── #163 : toRow ne doit pas envoyer 'points': null ──────────────────────

    test(
      "#163 toRow habitude user (points null) → clé 'points' absente du map",
      () {
        // Habitude utilisateur : is_system=false, points non fixés
        final habit = Habit(
          id: HabitId('habit-user'),
          name: NonEmptyString('Ma routine'),
          categoryId: CategoryId(kCategoryIdAlpha),
          frequencyType: HabitFrequencyType.daily,
          frequency: 1,
          activeDays: const {1, 2, 3, 4, 5, 6, 7},
          points: null,
          isSystem: false,
        );
        final row = HabitMapper.toRow(habit);
        // La clé 'points' ne doit PAS figurer dans la map (ne pas envoyer null)
        expect(row.containsKey('points'), isFalse);
      },
    );

    test(
      "#163 toRow habitude système (points: HabitPoints(3)) → 'points': 3",
      () {
        final habit = Habit(
          id: HabitId('habit-sys'),
          name: NonEmptyString('Habitude système'),
          categoryId: CategoryId(kCategoryIdAlpha),
          frequencyType: HabitFrequencyType.daily,
          frequency: 1,
          activeDays: const {1},
          points: HabitPoints(3),
          isSystem: true,
        );
        final row = HabitMapper.toRow(habit);
        expect(row['points'], 3);
      },
    );
  });
}
