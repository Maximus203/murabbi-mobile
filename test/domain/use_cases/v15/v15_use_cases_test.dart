import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/compute_day_color_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/reorder_subtasks_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/toggle_subtask_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_global_streak_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/score/score_calculator_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/timer/habit_timer.dart';
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

  Habit makeHabit({
    HabitTarget target = const HabitTarget.none(),
    List<HabitSubtask> subtasks = const [],
    bool subtasksAllRequired = false,
    int points = 3,
  }) {
    return Habit(
      id: habitId,
      name: NonEmptyString('Habit'),
      categoryId: catId,
      frequencyType: HabitFrequencyType.daily,
      frequency: 1,
      activeDays: {1, 2, 3, 4, 5, 6, 7},
      points: HabitPoints(points),
      isSystem: false,
      target: target,
      subtasks: subtasks,
      subtasksAllRequired: subtasksAllRequired,
    );
  }

  HabitSubtask sub(String id, int order) => HabitSubtask(
    id: HabitSubtaskId(id),
    habitId: habitId,
    title: NonEmptyString('Étape $order'),
    orderIndex: order,
  );

  // ---------------------------------------------------------------------------
  // Subtasks — Toggle / Reorder
  // ---------------------------------------------------------------------------

  group('ToggleSubtaskUseCase', () {
    const useCase = ToggleSubtaskUseCase();
    final id1 = HabitSubtaskId('s-1');
    final id2 = HabitSubtaskId('s-2');

    test('adds subtask id when not present', () {
      final result = useCase(completed: const [], subtaskId: id1);
      expect(result, [id1]);
    });

    test('removes subtask id when already present', () {
      final result = useCase(completed: [id1, id2], subtaskId: id1);
      expect(result, [id2]);
    });

    test('preserves ordering of remaining ids', () {
      final id3 = HabitSubtaskId('s-3');
      final result = useCase(completed: [id1, id2, id3], subtaskId: id2);
      expect(result, [id1, id3]);
    });
  });

  group('ReorderSubtasksUseCase', () {
    const useCase = ReorderSubtasksUseCase();

    test('reassigns orderIndex according to new order', () {
      final a = sub('a', 0);
      final b = sub('b', 1);
      final c = sub('c', 2);
      final reordered = useCase(
        subtasks: [a, b, c],
        newOrder: [
          HabitSubtaskId('c'),
          HabitSubtaskId('a'),
          HabitSubtaskId('b'),
        ],
      );
      expect(reordered.map((s) => s.id.value).toList(), ['c', 'a', 'b']);
      expect(reordered.map((s) => s.orderIndex).toList(), [0, 1, 2]);
    });

    test('throws if newOrder length differs from subtasks length', () {
      final a = sub('a', 0);
      final b = sub('b', 1);
      expect(
        () => useCase(subtasks: [a, b], newOrder: [HabitSubtaskId('a')]),
        throwsArgumentError,
      );
    });

    test('throws if newOrder contains unknown id', () {
      final a = sub('a', 0);
      expect(
        () => useCase(subtasks: [a], newOrder: [HabitSubtaskId('zzz')]),
        throwsArgumentError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Timer — Start / Pause / Resume / Stop (pure state machine)
  // ---------------------------------------------------------------------------

  group('HabitTimer', () {
    test('start initialises with full target duration remaining', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      final timer = HabitTimer.start(
        target: const Duration(minutes: 20),
        now: t0,
      );
      expect(timer.totalDuration, const Duration(minutes: 20));
      expect(timer.remaining(at: t0), const Duration(minutes: 20));
      expect(timer.isRunning, isTrue);
      expect(timer.isPaused, isFalse);
    });

    test('remaining decreases linearly while running', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      final timer = HabitTimer.start(
        target: const Duration(minutes: 5),
        now: t0,
      );
      expect(
        timer.remaining(at: t0.add(const Duration(minutes: 2))),
        const Duration(minutes: 3),
      );
    });

    test('remaining clamps to zero when target elapsed', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      final timer = HabitTimer.start(
        target: const Duration(minutes: 5),
        now: t0,
      );
      expect(
        timer.remaining(at: t0.add(const Duration(minutes: 10))),
        Duration.zero,
      );
    });

    test('pause then resume preserves elapsed time before pause', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(
        target: const Duration(minutes: 10),
        now: t0,
      );
      timer = timer.pause(now: t0.add(const Duration(minutes: 3)));
      expect(timer.isPaused, isTrue);
      // 10 minutes pass while paused — remaining must still be 7 minutes.
      expect(
        timer.remaining(at: t0.add(const Duration(minutes: 13))),
        const Duration(minutes: 7),
      );
      // Resume and advance 2 more minutes.
      timer = timer.resume(now: t0.add(const Duration(minutes: 13)));
      expect(timer.isRunning, isTrue);
      expect(
        timer.remaining(at: t0.add(const Duration(minutes: 15))),
        const Duration(minutes: 5),
      );
    });

    test('elapsed accumulates across multiple pauses', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(
        target: const Duration(minutes: 10),
        now: t0,
      );
      timer = timer.pause(now: t0.add(const Duration(minutes: 2)));
      timer = timer.resume(now: t0.add(const Duration(minutes: 5)));
      timer = timer.pause(now: t0.add(const Duration(minutes: 6)));
      // Elapsed effective = 2 + 1 = 3 minutes (3 paused minutes 2..5 don't count).
      expect(timer.elapsed, const Duration(minutes: 3));
    });

    test('stop returns final elapsed at the stop instant', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      final timer = HabitTimer.start(
        target: const Duration(minutes: 10),
        now: t0,
      );
      final result = timer.stop(now: t0.add(const Duration(minutes: 4)));
      expect(result, const Duration(minutes: 4));
    });

    test('pause is idempotent (does not double-pause)', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(target: const Duration(minutes: 5), now: t0);
      timer = timer.pause(now: t0.add(const Duration(minutes: 1)));
      final paused1 = timer;
      timer = timer.pause(now: t0.add(const Duration(minutes: 2)));
      expect(timer, equals(paused1));
    });

    test('resume on a running timer is a no-op', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(target: const Duration(minutes: 5), now: t0);
      final running = timer;
      timer = timer.resume(now: t0.add(const Duration(seconds: 30)));
      expect(timer, equals(running));
    });
  });

  // ---------------------------------------------------------------------------
  // Scoring — conditional v1.5 (spec § 3.2) + Q-07 makeup +1
  // ---------------------------------------------------------------------------

  group('ScoreCalculatorUseCase — habit (matrix v1.5 § 3.2/4)', () {
    const useCase = ScoreCalculatorUseCase();

    HabitLog log({
      HabitLogStatus status = HabitLogStatus.done,
      int? actualValue,
      bool? targetReached,
      List<HabitSubtaskId> subtasksCompleted = const [],
    }) {
      return HabitLog(
        habitId: habitId,
        date: DateTime(2026, 5, 4),
        status: status,
        actualValue: actualValue,
        targetReached: targetReached,
        subtasksCompleted: subtasksCompleted,
      );
    }

    test('plain habit done on time returns full points', () {
      final h = makeHabit(points: 3);
      expect(useCase.forHabit(h, log()), 3);
    });

    test('plain habit late returns +1 (Q-02 + spec § 3.2)', () {
      final h = makeHabit(points: 5);
      expect(useCase.forHabit(h, log(status: HabitLogStatus.late)), 1);
    });

    test('plain habit missed returns 0', () {
      final h = makeHabit();
      expect(useCase.forHabit(h, log(status: HabitLogStatus.missed)), 0);
    });

    test('habit with target — target reached on time returns full points', () {
      final h = makeHabit(
        points: 3,
        target: HabitTarget.value(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
      );
      expect(useCase.forHabit(h, log(actualValue: 5, targetReached: true)), 3);
    });

    test('habit with target — target missed returns 0 even if status=done', () {
      final h = makeHabit(
        target: HabitTarget.value(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
      );
      expect(useCase.forHabit(h, log(actualValue: 3, targetReached: false)), 0);
    });

    test('habit with target — target reached but late returns +1', () {
      final h = makeHabit(
        target: HabitTarget.value(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
      );
      expect(
        useCase.forHabit(
          h,
          log(status: HabitLogStatus.late, actualValue: 5, targetReached: true),
        ),
        1,
      );
    });

    test(
      'habit with subtasksAllRequired — all checked returns full points',
      () {
        final s1 = sub('s-1', 0);
        final s2 = sub('s-2', 1);
        final h = makeHabit(subtasks: [s1, s2], subtasksAllRequired: true);
        expect(useCase.forHabit(h, log(subtasksCompleted: [s1.id, s2.id])), 3);
      },
    );

    test('habit with subtasksAllRequired — partial returns 0', () {
      final s1 = sub('s-1', 0);
      final s2 = sub('s-2', 1);
      final h = makeHabit(subtasks: [s1, s2], subtasksAllRequired: true);
      expect(useCase.forHabit(h, log(subtasksCompleted: [s1.id])), 0);
    });

    test('combo target + subtasks — both must be satisfied', () {
      final s1 = sub('s-1', 0);
      final h = makeHabit(
        target: HabitTarget.timed(
          value: TargetValue(20),
          unit: TargetUnit.minutes,
        ),
        subtasks: [s1],
        subtasksAllRequired: true,
      );
      expect(
        useCase.forHabit(
          h,
          log(actualValue: 20, targetReached: true, subtasksCompleted: [s1.id]),
        ),
        3,
      );
      expect(
        useCase.forHabit(
          h,
          log(
            actualValue: 20,
            targetReached: true,
            subtasksCompleted: const [],
          ),
        ),
        0,
      );
    });
  });

  group('ScoreCalculatorUseCase — prayer (Q-02 + Q-07 makeup)', () {
    const useCase = ScoreCalculatorUseCase();

    test('onTime returns +3', () {
      expect(useCase.forPrayer(PrayerStatus.onTime), 3);
    });
    test('late returns +1', () {
      expect(useCase.forPrayer(PrayerStatus.late), 1);
    });
    test('makeup returns +1 (Q-07 verrouillée)', () {
      expect(useCase.forPrayer(PrayerStatus.makeup), 1);
    });
    test('missed returns 0', () {
      expect(useCase.forPrayer(PrayerStatus.missed), 0);
    });
    test('pending returns 0', () {
      expect(useCase.forPrayer(PrayerStatus.pending), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Day color (Q-08-cal)
  // ---------------------------------------------------------------------------

  group('ComputeDayColorUseCase (Q-08-cal)', () {
    const useCase = ComputeDayColorUseCase();

    test('all events ontime → bestSeverity, fillPercent=1.0', () {
      final result = useCase(
        prayerStatuses: const [
          PrayerStatus.onTime,
          PrayerStatus.onTime,
          PrayerStatus.onTime,
          PrayerStatus.onTime,
          PrayerStatus.onTime,
        ],
        habitStatuses: const [HabitLogStatus.done, HabitLogStatus.done],
      );
      expect(result.worst, DayStatusSeverity.success);
      expect(result.fillPercent, closeTo(1.0, 1e-9));
    });

    test(
      'one missed prayer → worst=missed, fillPercent reflects done ratio',
      () {
        final result = useCase(
          prayerStatuses: const [
            PrayerStatus.onTime,
            PrayerStatus.onTime,
            PrayerStatus.onTime,
            PrayerStatus.onTime,
            PrayerStatus.missed,
          ],
          habitStatuses: const [HabitLogStatus.done, HabitLogStatus.done],
        );
        expect(result.worst, DayStatusSeverity.missed);
        // 6 done out of 7 → ~0.857
        expect(result.fillPercent, closeTo(6 / 7, 1e-9));
      },
    );

    test('mixed late + makeup → worst=late (makeup is OK)', () {
      final result = useCase(
        prayerStatuses: const [
          PrayerStatus.onTime,
          PrayerStatus.late,
          PrayerStatus.makeup,
        ],
        habitStatuses: const [HabitLogStatus.done],
      );
      expect(result.worst, DayStatusSeverity.late);
      expect(result.fillPercent, closeTo(1.0, 1e-9));
    });

    test('no events → empty severity, fill=0', () {
      final result = useCase(prayerStatuses: const [], habitStatuses: const []);
      expect(result.worst, DayStatusSeverity.empty);
      expect(result.fillPercent, 0.0);
    });

    test('pending counts as not done (lowers fillPercent) but not worst', () {
      final result = useCase(
        prayerStatuses: const [PrayerStatus.onTime, PrayerStatus.pending],
        habitStatuses: const [],
      );
      expect(result.worst, DayStatusSeverity.success);
      expect(result.fillPercent, closeTo(0.5, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // Global streak (Q-17 option C)
  // ---------------------------------------------------------------------------

  group('ComputeGlobalStreakUseCase (Q-17 option C)', () {
    const useCase = ComputeGlobalStreakUseCase();
    final ref = DateTime(2026, 5, 4);

    DailyScore d(int daysAgo, int points) => DailyScore(
      date: ref.subtract(Duration(days: daysAgo)),
      points: points,
    );

    test('returns 0 for empty history', () {
      expect(
        useCase(history: const [], referenceDate: ref, level: Level.aspirant),
        0,
      );
    });

    test('counts consecutive days >= dailyGoal back from reference', () {
      // Aspirant goal = 30 pts/j
      final history = [d(0, 35), d(1, 40), d(2, 30), d(3, 10)];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        3,
      );
    });

    test('breaks on day below goal', () {
      final history = [d(0, 35), d(1, 25)];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        1,
      );
    });

    test('returns 0 if today below goal', () {
      final history = [d(0, 10), d(1, 50)];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        0,
      );
    });

    test('uses the level dailyGoal (Murid = 45)', () {
      final history = [d(0, 50), d(1, 40)]; // 40 < 45 → break
      expect(
        useCase(history: history, referenceDate: ref, level: Level.murid),
        1,
      );
    });

    test('skips missing days as breaks (no day off in V1)', () {
      // No record for daysAgo=1 → break.
      final history = [d(0, 60), d(2, 60)];
      expect(
        useCase(history: history, referenceDate: ref, level: Level.aspirant),
        1,
      );
    });
  });
}
