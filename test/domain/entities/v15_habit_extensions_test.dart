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
import '../../helpers/test_uuids.dart';

void main() {
  final habitId = HabitId(kHabitIdAlpha);
  final catId = CategoryId(kCategoryIdAlpha);

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
      expect(() => baseHabit(subtasksAllRequired: true), throwsArgumentError);
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
        status: HabitLogStatus.onTime,
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
        status: HabitLogStatus.onTime,
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
          status: HabitLogStatus.onTime,
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
          status: HabitLogStatus.onTime,
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
          status: HabitLogStatus.onTime,
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
          status: HabitLogStatus.onTime,
          actualValue: null,
          targetReached: true,
        ),
        throwsArgumentError,
      );
    });

    test('openedAt and loggedAt default to null (legacy / 1-tap heatmap)', () {
      final log = HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 4),
        status: HabitLogStatus.onTime,
      );
      expect(log.openedAt, isNull);
      expect(log.loggedAt, isNull);
    });

    test('accepts openedAt and loggedAt session timestamps', () {
      final opened = DateTime.utc(2026, 5, 9, 10, 30);
      final logged = DateTime.utc(2026, 5, 9, 10, 32);
      final log = HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 9),
        status: HabitLogStatus.onTime,
        openedAt: opened,
        loggedAt: logged,
      );
      expect(log.openedAt, opened);
      expect(log.loggedAt, logged);
    });

    test(
      'allows openedAt set without loggedAt (form opened, not yet validated)',
      () {
        final log = HabitLog(
          habitId: habitId,
          date: DateTime(2026, 5, 9),
          status: HabitLogStatus.onTime,
          openedAt: DateTime.utc(2026, 5, 9, 10, 30),
        );
        expect(log.openedAt, isNotNull);
        expect(log.loggedAt, isNull);
      },
    );

    test('allows loggedAt set without openedAt (1-tap heatmap save)', () {
      final log = HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 9),
        status: HabitLogStatus.onTime,
        loggedAt: DateTime.utc(2026, 5, 9, 22),
      );
      expect(log.openedAt, isNull);
      expect(log.loggedAt, isNotNull);
    });

    test('throws when both timestamps set and loggedAt is before openedAt', () {
      expect(
        () => HabitLog(
          habitId: habitId,
          date: DateTime(2026, 5, 9),
          status: HabitLogStatus.onTime,
          openedAt: DateTime.utc(2026, 5, 9, 10, 30),
          loggedAt: DateTime.utc(2026, 5, 9, 10, 29),
        ),
        throwsArgumentError,
      );
    });

    test('accepts loggedAt == openedAt (instantaneous validation)', () {
      final t = DateTime.utc(2026, 5, 9, 10, 30);
      final log = HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 9),
        status: HabitLogStatus.onTime,
        openedAt: t,
        loggedAt: t,
      );
      expect(log.openedAt, t);
      expect(log.loggedAt, t);
    });
  });
}
