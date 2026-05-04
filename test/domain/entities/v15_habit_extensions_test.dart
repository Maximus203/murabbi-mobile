import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';

void main() {
  final habitId = HabitId('habit-uuid-001');
  final catId = CategoryId('cat-uuid-001');

  Habit baseHabit({
    HabitTarget? target,
    List<HabitSubtask>? subtasks,
    bool subtasksAllRequired = false,
  }) {
    return Habit(
      id: habitId,
      name: NonEmptyString('Lecture du Coran'),
      categoryId: catId,
      frequencyType: HabitFrequencyType.daily,
      frequency: 1,
      activeDays: {1, 2, 3, 4, 5, 6, 7},
      points: HabitPoints(3),
      isSystem: false,
      target: target ?? const HabitTarget.none(),
      subtasks: subtasks ?? const [],
      subtasksAllRequired: subtasksAllRequired,
    );
  }

  HabitSubtask sub(String id, int order) => HabitSubtask(
    id: HabitSubtaskId(id),
    habitId: habitId,
    title: NonEmptyString('Étape $order'),
    orderIndex: order,
  );

  group('Habit v1.5 extensions', () {
    test('default target is HabitTarget.none and subtasks empty', () {
      final h = baseHabit();
      expect(h.target, isA<HabitTargetNone>());
      expect(h.subtasks, isEmpty);
      expect(h.subtasksAllRequired, isFalse);
    });

    test('accepts a HabitTarget.value with up to 15 subtasks', () {
      final subs = List.generate(15, (i) => sub('s-$i', i));
      final h = baseHabit(
        target: HabitTarget.value(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
        subtasks: subs,
      );
      expect(h.subtasks.length, 15);
    });

    test('throws if more than 15 subtasks (spec § 2.4)', () {
      final subs = List.generate(16, (i) => sub('s-$i', i));
      expect(() => baseHabit(subtasks: subs), throwsArgumentError);
    });

    test('throws if a subtask references a different habitId', () {
      final foreign = HabitSubtask(
        id: HabitSubtaskId('s-1'),
        habitId: HabitId('other-habit'),
        title: NonEmptyString('foreign'),
        orderIndex: 0,
      );
      expect(() => baseHabit(subtasks: [foreign]), throwsArgumentError);
    });

    test('throws if subtasks orderIndex collide', () {
      final subs = [sub('s-1', 0), sub('s-2', 0)];
      expect(() => baseHabit(subtasks: subs), throwsArgumentError);
    });

    test('subtasksAllRequired=true requires at least one subtask', () {
      expect(
        () => baseHabit(subtasksAllRequired: true),
        throwsArgumentError,
      );
    });

    test('subtasksAllRequired=true with subtasks is accepted', () {
      final h = baseHabit(
        subtasks: [sub('s-1', 0), sub('s-2', 1)],
        subtasksAllRequired: true,
      );
      expect(h.subtasksAllRequired, isTrue);
      expect(h.subtasks.length, 2);
    });

    test('two habits with same fields (incl. v1.5) are equal', () {
      final t = HabitTarget.value(
        value: TargetValue(5),
        unit: TargetUnit.pages,
      );
      final a = baseHabit(target: t);
      final b = baseHabit(target: t);
      expect(a, equals(b));
    });
  });

  group('HabitLog v1.5 extensions', () {
    test('creates with optional v1.5 fields all null/empty by default', () {
      final log = HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 4),
        status: HabitLogStatus.done,
      );
      expect(log.actualValue, isNull);
      expect(log.targetReached, isNull);
      expect(log.subtasksCompleted, isEmpty);
      expect(log.duration, isNull);
    });

    test('creates with full v1.5 payload', () {
      final log = HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 4),
        status: HabitLogStatus.done,
        actualValue: 7,
        targetReached: true,
        subtasksCompleted: [HabitSubtaskId('s-1'), HabitSubtaskId('s-2')],
        duration: const Duration(minutes: 18),
      );
      expect(log.actualValue, 7);
      expect(log.targetReached, isTrue);
      expect(log.subtasksCompleted.length, 2);
      expect(log.duration, const Duration(minutes: 18));
    });

    test('throws on negative actualValue (spec § 8.2)', () {
      expect(
        () => HabitLog(
          habitId: habitId,
          date: DateTime(2026, 5, 4),
          status: HabitLogStatus.done,
          actualValue: -1,
        ),
        throwsArgumentError,
      );
    });

    test('throws on negative duration', () {
      expect(
        () => HabitLog(
          habitId: habitId,
          date: DateTime(2026, 5, 4),
          status: HabitLogStatus.done,
          duration: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('throws on duration > 24h (spec § 2.4 cap 86400s)', () {
      expect(
        () => HabitLog(
          habitId: habitId,
          date: DateTime(2026, 5, 4),
          status: HabitLogStatus.done,
          duration: const Duration(seconds: 86401),
        ),
        throwsArgumentError,
      );
    });

    test('targetReached must be null when actualValue is null', () {
      expect(
        () => HabitLog(
          habitId: habitId,
          date: DateTime(2026, 5, 4),
          status: HabitLogStatus.done,
          actualValue: null,
          targetReached: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
