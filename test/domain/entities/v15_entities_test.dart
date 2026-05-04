import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';

void main() {
  group('HabitTarget sealed (ADR-008)', () {
    test('HabitTarget.none creates without fields', () {
      const target = HabitTarget.none();
      expect(target, isA<HabitTargetNone>());
      expect(target.hasValue, isFalse);
      expect(target.hasTimer, isFalse);
    });

    test('HabitTarget.value creates with unit non-custom and no customLabel', () {
      final target = HabitTarget.value(
        value: TargetValue(5),
        unit: TargetUnit.pages,
      );
      expect(target, isA<HabitTargetValue>());
      expect(target.hasValue, isTrue);
      expect(target.hasTimer, isFalse);
      final v = target as HabitTargetValue;
      expect(v.value.value, 5);
      expect(v.unit, TargetUnit.pages);
      expect(v.customLabel, isNull);
    });

    test('HabitTarget.value with unit=custom requires non-empty customLabel', () {
      final target = HabitTarget.value(
        value: TargetValue(33),
        unit: TargetUnit.custom,
        customLabel: 'salutations',
      );
      final v = target as HabitTargetValue;
      expect(v.customLabel, 'salutations');
    });

    test('HabitTarget.value with unit=custom and null customLabel throws', () {
      expect(
        () => HabitTarget.value(
          value: TargetValue(1),
          unit: TargetUnit.custom,
        ),
        throwsArgumentError,
      );
    });

    test('HabitTarget.value with unit=custom and empty customLabel throws', () {
      expect(
        () => HabitTarget.value(
          value: TargetValue(1),
          unit: TargetUnit.custom,
          customLabel: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('HabitTarget.value with non-custom unit and customLabel throws', () {
      expect(
        () => HabitTarget.value(
          value: TargetValue(1),
          unit: TargetUnit.pages,
          customLabel: 'pages but with label',
        ),
        throwsArgumentError,
      );
    });

    test('HabitTarget.value with customLabel > 30 chars throws', () {
      expect(
        () => HabitTarget.value(
          value: TargetValue(1),
          unit: TargetUnit.custom,
          customLabel: 'a' * 31,
        ),
        throwsArgumentError,
      );
    });

    test('HabitTarget.timed accepts only minutes/hours', () {
      final t1 = HabitTarget.timed(
        value: TargetValue(20),
        unit: TargetUnit.minutes,
      );
      final t2 = HabitTarget.timed(
        value: TargetValue(2),
        unit: TargetUnit.hours,
      );
      expect(t1, isA<HabitTargetTimed>());
      expect(t1.hasTimer, isTrue);
      expect(t2.hasTimer, isTrue);
    });

    test('HabitTarget.timed with non-time unit throws (chk_timer_unit)', () {
      expect(
        () => HabitTarget.timed(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
        throwsArgumentError,
      );
    });

    test('two HabitTarget.value with same fields are equal', () {
      final a = HabitTarget.value(
        value: TargetValue(5),
        unit: TargetUnit.pages,
      );
      final b = HabitTarget.value(
        value: TargetValue(5),
        unit: TargetUnit.pages,
      );
      expect(a, equals(b));
    });

    test('HabitTarget.none singletons are equal', () {
      expect(const HabitTarget.none(), equals(const HabitTarget.none()));
    });
  });

  group('HabitSubtask entity', () {
    final habitId = HabitId('habit-uuid-001');
    final subtaskId = HabitSubtaskId('subtask-uuid-001');

    test('creates with valid fields', () {
      final sub = HabitSubtask(
        id: subtaskId,
        habitId: habitId,
        title: NonEmptyString('Échauffement 5 min'),
        orderIndex: 0,
      );
      expect(sub.id, subtaskId);
      expect(sub.habitId, habitId);
      expect(sub.title.value, 'Échauffement 5 min');
      expect(sub.orderIndex, 0);
    });

    test('throws on negative orderIndex', () {
      expect(
        () => HabitSubtask(
          id: subtaskId,
          habitId: habitId,
          title: NonEmptyString('x'),
          orderIndex: -1,
        ),
        throwsArgumentError,
      );
    });

    test('throws on title > 120 chars', () {
      expect(
        () => HabitSubtask(
          id: subtaskId,
          habitId: habitId,
          title: NonEmptyString('a' * 121),
          orderIndex: 0,
        ),
        throwsArgumentError,
      );
    });

    test('accepts title at exact 120 chars', () {
      final sub = HabitSubtask(
        id: subtaskId,
        habitId: habitId,
        title: NonEmptyString('a' * 120),
        orderIndex: 0,
      );
      expect(sub.title.value.length, 120);
    });

    test('two subtasks with same fields are equal', () {
      final a = HabitSubtask(
        id: subtaskId,
        habitId: habitId,
        title: NonEmptyString('A'),
        orderIndex: 0,
      );
      final b = HabitSubtask(
        id: subtaskId,
        habitId: habitId,
        title: NonEmptyString('A'),
        orderIndex: 0,
      );
      expect(a, equals(b));
    });
  });
}
