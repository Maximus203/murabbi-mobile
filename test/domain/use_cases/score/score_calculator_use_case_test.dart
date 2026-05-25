import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/use_cases/score/score_calculator_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';

// Constructeur d'habitude de test — évite la répétition du boilerplate.
// [points] est nullable : null simule une habitude user sans points fixés.
Habit _makeHabit({
  String id = 'h-1',
  int? points = 5,
  HabitTarget target = const HabitTarget.none(),
  List<HabitSubtask> subtasks = const [],
  bool subtasksAllRequired = false,
}) {
  return Habit(
    id: HabitId(id),
    name: NonEmptyString('Test habit'),
    categoryId: CategoryId('cat-1'),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: {1, 2, 3, 4, 5, 6, 7},
    points: points != null ? HabitPoints(points) : null,
    isSystem: false,
    target: target,
    subtasks: subtasks,
    subtasksAllRequired: subtasksAllRequired,
  );
}

HabitLog _makeLog({
  String habitId = 'h-1',
  HabitLogStatus status = HabitLogStatus.onTime,
  int? actualValue,
  bool? targetReached,
  List<HabitSubtaskId> subtasksCompleted = const [],
}) {
  return HabitLog(
    habitId: HabitId(habitId),
    date: DateTime.utc(2026, 5, 17),
    status: status,
    actualValue: actualValue,
    targetReached: targetReached,
    subtasksCompleted: subtasksCompleted,
  );
}

void main() {
  const calc = ScoreCalculatorUseCase();
  final date = DateTime.utc(2026, 5, 17);

  // ── forPrayer ────────────────────────────────────────────────────────────────

  group('ScoreCalculatorUseCase.forPrayer', () {
    test('onTime → +3 points', () {
      expect(calc.forPrayer(PrayerStatus.onTime), 3);
    });

    test('late → +1 point', () {
      expect(calc.forPrayer(PrayerStatus.late), 1);
    });

    test('makeup → +1 point (Q-02 : makeup compte comme late)', () {
      expect(calc.forPrayer(PrayerStatus.makeup), 1);
    });

    test('missed → 0 point', () {
      expect(calc.forPrayer(PrayerStatus.missed), 0);
    });

    test('pending → 0 point', () {
      expect(calc.forPrayer(PrayerStatus.pending), 0);
    });

    test('5/5 prières onTime → score total prières = 15', () {
      const statuses = [
        PrayerStatus.onTime,
        PrayerStatus.onTime,
        PrayerStatus.onTime,
        PrayerStatus.onTime,
        PrayerStatus.onTime,
      ];
      final total = statuses.fold(0, (acc, s) => acc + calc.forPrayer(s));
      expect(total, 15);
    });

    test('mix : 3 onTime + 1 late + 1 missed → 3×3 + 1×1 + 0 = 10', () {
      const statuses = [
        PrayerStatus.onTime,
        PrayerStatus.onTime,
        PrayerStatus.onTime,
        PrayerStatus.late,
        PrayerStatus.missed,
      ];
      final total = statuses.fold(0, (acc, s) => acc + calc.forPrayer(s));
      expect(total, 10);
    });

    test('0 prière (toutes missed) → score prières = 0', () {
      const statuses = [
        PrayerStatus.missed,
        PrayerStatus.missed,
        PrayerStatus.missed,
        PrayerStatus.missed,
        PrayerStatus.missed,
      ];
      final total = statuses.fold(0, (acc, s) => acc + calc.forPrayer(s));
      expect(total, 0);
    });

    test('makeup non comptée dans streak (toujours 1 pt, pas 3)', () {
      // La prière makeup donne le même score que late — elle n'est pas
      // équivalente à onTime pour le scoring.
      expect(calc.forPrayer(PrayerStatus.makeup), isNot(3));
      expect(calc.forPrayer(PrayerStatus.makeup), 1);
    });
  });

  // ── forHabit — sans objectif ─────────────────────────────────────────────────

  group('ScoreCalculatorUseCase.forHabit — sans objectif', () {
    test('onTime sans objectif → habit.points.value', () {
      final habit = _makeHabit(points: 5);
      final log = _makeLog(status: HabitLogStatus.onTime);
      expect(calc.forHabit(habit, log), 5);
    });

    test('late sans objectif → +1 (latePoints)', () {
      final habit = _makeHabit(points: 5);
      final log = _makeLog(status: HabitLogStatus.late);
      expect(calc.forHabit(habit, log), 1);
    });

    test('missed sans objectif → 0', () {
      final habit = _makeHabit(points: 5);
      final log = _makeLog(status: HabitLogStatus.missed);
      expect(calc.forHabit(habit, log), 0);
    });
  });

  // ── forHabit — avec objectif chiffré ────────────────────────────────────────

  group('ScoreCalculatorUseCase.forHabit — avec objectif chiffré', () {
    test(
      'objectif atteint (actualValue >= target) + onTime → habit.points',
      () {
        final habit = _makeHabit(
          points: 7,
          target: HabitTarget.value(
            value: TargetValue(10),
            unit: TargetUnit.pages,
          ),
        );
        // actualValue = 10 (exactement le target)
        final log = _makeLog(
          status: HabitLogStatus.onTime,
          actualValue: 10,
          targetReached: true,
        );
        expect(calc.forHabit(habit, log), 7);
      },
    );

    test('objectif dépassé (actualValue > target) + onTime → habit.points', () {
      final habit = _makeHabit(
        points: 7,
        target: HabitTarget.value(
          value: TargetValue(10),
          unit: TargetUnit.pages,
        ),
      );
      final log = _makeLog(
        status: HabitLogStatus.onTime,
        actualValue: 15,
        targetReached: true,
      );
      expect(calc.forHabit(habit, log), 7);
    });

    test(
      'target non atteint (actualValue < target) → 0, peu importe le statut',
      () {
        final habit = _makeHabit(
          points: 7,
          target: HabitTarget.value(
            value: TargetValue(10),
            unit: TargetUnit.pages,
          ),
        );
        // Même si "onTime", le target n'est pas atteint → 0
        final log = _makeLog(
          status: HabitLogStatus.onTime,
          actualValue: 5,
          targetReached: false,
        );
        expect(calc.forHabit(habit, log), 0);
      },
    );

    test('target non atteint + late → 0 (target bloque toujours)', () {
      final habit = _makeHabit(
        points: 7,
        target: HabitTarget.value(
          value: TargetValue(10),
          unit: TargetUnit.pages,
        ),
      );
      final log = _makeLog(
        status: HabitLogStatus.late,
        actualValue: 3,
        targetReached: false,
      );
      expect(calc.forHabit(habit, log), 0);
    });

    test(
      'actualValue null + targetReached null → utilise HabitTargetNone path',
      () {
        // Pas de target : actualValue null est sans effet
        final habit = _makeHabit(points: 4);
        final log = _makeLog(status: HabitLogStatus.onTime);
        expect(calc.forHabit(habit, log), 4);
      },
    );

    test('target timed atteint (minutes) → habit.points', () {
      final habit = _makeHabit(
        points: 6,
        target: HabitTarget.timed(
          value: TargetValue(30),
          unit: TargetUnit.minutes,
        ),
      );
      final log = _makeLog(
        status: HabitLogStatus.onTime,
        actualValue: 30,
        targetReached: true,
      );
      expect(calc.forHabit(habit, log), 6);
    });

    test('target timed non atteint → 0', () {
      final habit = _makeHabit(
        points: 6,
        target: HabitTarget.timed(
          value: TargetValue(30),
          unit: TargetUnit.minutes,
        ),
      );
      final log = _makeLog(
        status: HabitLogStatus.onTime,
        actualValue: 15,
        targetReached: false,
      );
      expect(calc.forHabit(habit, log), 0);
    });
  });

  // ── forHabit — avec sous-tâches obligatoires ─────────────────────────────────

  group('ScoreCalculatorUseCase.forHabit — sous-tâches obligatoires', () {
    final habitId = HabitId('h-sub');
    final subtask1 = HabitSubtask(
      id: HabitSubtaskId('st-1'),
      habitId: habitId,
      title: NonEmptyString('Sous-tâche 1'),
      orderIndex: 0,
    );
    final subtask2 = HabitSubtask(
      id: HabitSubtaskId('st-2'),
      habitId: habitId,
      title: NonEmptyString('Sous-tâche 2'),
      orderIndex: 1,
    );

    late Habit habitWithSubtasks;

    setUp(() {
      habitWithSubtasks = Habit(
        id: habitId,
        name: NonEmptyString('Habit avec sous-tâches'),
        categoryId: CategoryId('cat-1'),
        frequencyType: HabitFrequencyType.daily,
        frequency: 1,
        activeDays: {1},
        points: HabitPoints(8),
        isSystem: false,
        subtasks: [subtask1, subtask2],
        subtasksAllRequired: true,
      );
    });

    test('toutes les sous-tâches cochées + onTime → habit.points', () {
      final log = HabitLog(
        habitId: habitId,
        date: date,
        status: HabitLogStatus.onTime,
        subtasksCompleted: [HabitSubtaskId('st-1'), HabitSubtaskId('st-2')],
      );
      expect(calc.forHabit(habitWithSubtasks, log), 8);
    });

    test('sous-tâches partiellement cochées → 0', () {
      final log = HabitLog(
        habitId: habitId,
        date: date,
        status: HabitLogStatus.onTime,
        subtasksCompleted: [HabitSubtaskId('st-1')],
        // st-2 manque
      );
      expect(calc.forHabit(habitWithSubtasks, log), 0);
    });

    test('aucune sous-tâche cochée → 0', () {
      final log = HabitLog(
        habitId: habitId,
        date: date,
        status: HabitLogStatus.onTime,
        subtasksCompleted: const [],
      );
      expect(calc.forHabit(habitWithSubtasks, log), 0);
    });

    test(
      'sous-tâches toutes cochées + statut late → latePoints (1) car subtask ok mais statut late',
      () {
        final log = HabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.late,
          subtasksCompleted: [HabitSubtaskId('st-1'), HabitSubtaskId('st-2')],
        );
        // sous-tâches OK + late → latePoints = 1
        expect(calc.forHabit(habitWithSubtasks, log), 1);
      },
    );

    test('sous-tâches incomplètes + statut late → 0 (subtask bloque)', () {
      final log = HabitLog(
        habitId: habitId,
        date: date,
        status: HabitLogStatus.late,
        subtasksCompleted: const [],
      );
      expect(calc.forHabit(habitWithSubtasks, log), 0);
    });
  });

  // ── forHabit — combinaison objectif + sous-tâches ────────────────────────────

  group(
    'ScoreCalculatorUseCase.forHabit — combinaison objectif ET sous-tâches',
    () {
      final habitId = HabitId('h-combo');
      final subtask = HabitSubtask(
        id: HabitSubtaskId('st-combo'),
        habitId: habitId,
        title: NonEmptyString('Sous-tâche combo'),
        orderIndex: 0,
      );

      late Habit comboHabit;

      setUp(() {
        comboHabit = Habit(
          id: habitId,
          name: NonEmptyString('Habit combo'),
          categoryId: CategoryId('cat-1'),
          frequencyType: HabitFrequencyType.daily,
          frequency: 1,
          activeDays: {1},
          points: HabitPoints(10),
          isSystem: false,
          target: HabitTarget.value(
            value: TargetValue(5),
            unit: TargetUnit.pages,
          ),
          subtasks: [subtask],
          subtasksAllRequired: true,
        );
      });

      test(
        'target atteint + sous-tâche cochée + onTime → habit.points (ET logique)',
        () {
          final log = HabitLog(
            habitId: habitId,
            date: date,
            status: HabitLogStatus.onTime,
            actualValue: 5,
            targetReached: true,
            subtasksCompleted: [HabitSubtaskId('st-combo')],
          );
          expect(calc.forHabit(comboHabit, log), 10);
        },
      );

      test('target atteint mais sous-tâche non cochée → 0 (ET logique)', () {
        final log = HabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.onTime,
          actualValue: 5,
          targetReached: true,
          subtasksCompleted: const [],
        );
        expect(calc.forHabit(comboHabit, log), 0);
      });

      test('sous-tâche cochée mais target non atteint → 0 (ET logique)', () {
        final log = HabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.onTime,
          actualValue: 2,
          targetReached: false,
          subtasksCompleted: [HabitSubtaskId('st-combo')],
        );
        expect(calc.forHabit(comboHabit, log), 0);
      });
    },
  );

  // ── #163 : fallback scoring quand points == null ──────────────────────────

  group('ScoreCalculatorUseCase.forHabit — fallback quand points == null', () {
    test('points null + onTime → 0 (pas de points fixés)', () {
      // Habitude user sans points spécifiés : le scoring retourne 0
      // (pas de catégorie injectée dans l'entité Habit pour le fallback).
      final habit = _makeHabit(points: null);
      final log = _makeLog(status: HabitLogStatus.onTime);
      expect(calc.forHabit(habit, log), 0);
    });

    test('points null + late → latePoints (1)', () {
      final habit = _makeHabit(points: null);
      final log = _makeLog(status: HabitLogStatus.late);
      expect(calc.forHabit(habit, log), 1);
    });

    test('points null + missed → 0', () {
      final habit = _makeHabit(points: null);
      final log = _makeLog(status: HabitLogStatus.missed);
      expect(calc.forHabit(habit, log), 0);
    });
  });
}
