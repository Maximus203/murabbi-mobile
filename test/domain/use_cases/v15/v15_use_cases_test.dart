import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
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
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../../helpers/test_uuids.dart';

void main() {
  final habitId = HabitId(kHabitIdAlpha);
  final catId = CategoryId(kCategoryIdAlpha);

  Habit makeHabit({
    HabitTarget target = const HabitTarget.none(),
    List<HabitSubtask> subtasks = const [],
    bool subtasksAllRequired = false,
    int points = 3,
  }) {
    return Habit(
      id: habitId,
      userId: UserId(kUserIdAlpha),
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

    test('throws if newOrder contains duplicate ids (Copilot review #2)', () {
      final a = sub('a', 0);
      final b = sub('b', 1);
      expect(
        () => useCase(
          subtasks: [a, b],
          newOrder: [HabitSubtaskId('a'), HabitSubtaskId('a')],
        ),
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

    test('elapsedAt(at:) is pure (no system clock) — Copilot review #3', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(
        target: const Duration(minutes: 10),
        now: t0,
      );
      timer = timer.pause(now: t0.add(const Duration(minutes: 2)));
      timer = timer.resume(now: t0.add(const Duration(minutes: 5)));
      timer = timer.pause(now: t0.add(const Duration(minutes: 6)));
      // Elapsed effective = 2 + 1 = 3 minutes (3 paused minutes 2..5 don't count).
      // The reference instant is provided explicitly — no DateTime.now() call.
      expect(
        timer.elapsedAt(at: t0.add(const Duration(minutes: 6))),
        const Duration(minutes: 3),
      );
    });

    test('elapsedAt while paused freezes at pausedAt regardless of "at"', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(
        target: const Duration(minutes: 10),
        now: t0,
      );
      timer = timer.pause(now: t0.add(const Duration(minutes: 3)));
      // Even if caller passes a much later instant, elapsed stays 3 minutes
      // (the timer is paused).
      expect(
        timer.elapsedAt(at: t0.add(const Duration(hours: 1))),
        const Duration(minutes: 3),
      );
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

    test('pause(now) before startedAt throws (Copilot review #4)', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      final timer = HabitTimer.start(
        target: const Duration(minutes: 5),
        now: t0,
      );
      expect(
        () => timer.pause(now: t0.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    test('resume(now) before pausedAt throws (Copilot review #4)', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      var timer = HabitTimer.start(target: const Duration(minutes: 5), now: t0);
      timer = timer.pause(now: t0.add(const Duration(minutes: 2)));
      expect(
        () => timer.resume(now: t0.add(const Duration(minutes: 1))),
        throwsArgumentError,
      );
    });

    test('stop(now) before startedAt throws (Copilot review #4)', () {
      final t0 = DateTime.utc(2026, 5, 4, 9);
      final timer = HabitTimer.start(
        target: const Duration(minutes: 5),
        now: t0,
      );
      expect(
        () => timer.stop(now: t0.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
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
      HabitLogStatus status = HabitLogStatus.onTime,
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

    test('habit with target — actualValue >= target but targetReached null '
        'still scores full points (Copilot review #5 — domain truth)', () {
      final h = makeHabit(
        points: 3,
        target: HabitTarget.value(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
      );
      // log.targetReached is null (DB GENERATED column not yet hydrated),
      // but actualValue=5 >= target=5 → domaine considère atteint.
      expect(useCase.forHabit(h, log(actualValue: 5)), 3);
    });

    test('habit with target — actualValue < target scores 0 even if '
        'targetReached null (Copilot review #5)', () {
      final h = makeHabit(
        target: HabitTarget.value(
          value: TargetValue(5),
          unit: TargetUnit.pages,
        ),
      );
      expect(useCase.forHabit(h, log(actualValue: 3)), 0);
    });

    test(
      'habit with target — actualValue null scores 0 (no progress recorded)',
      () {
        final h = makeHabit(
          target: HabitTarget.value(
            value: TargetValue(5),
            unit: TargetUnit.pages,
          ),
        );
        expect(useCase.forHabit(h, log()), 0);
      },
    );

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
        habitStatuses: const [HabitLogStatus.onTime, HabitLogStatus.onTime],
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
          habitStatuses: const [HabitLogStatus.onTime, HabitLogStatus.onTime],
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
        habitStatuses: const [HabitLogStatus.onTime],
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
  // Global streak (Q-17 → rewrite DailySummary — Q-A/Q-23)
  // ---------------------------------------------------------------------------

  group('ComputeGlobalStreakUseCase (Q-17 DailySummary)', () {
    const useCase = ComputeGlobalStreakUseCase();
    final ref = DateTime(2026, 5, 4);

    DailySummary d(int daysAgo, {required bool valid}) => DailySummary(
      userId: UserId('u'),
      day: ref.subtract(Duration(days: daysAgo)),
      completionRate: valid ? 87.5 : 25.0,
      streakValid: valid,
      habitPointsToday: valid ? 70 : 20,
    );

    test('returns 0 for empty history', () {
      expect(useCase(history: const [], referenceDate: ref), 0);
    });

    test('counts consecutive valid days back from reference', () {
      final history = [
        d(0, valid: true),
        d(1, valid: true),
        d(2, valid: true),
        d(3, valid: false),
      ];
      expect(useCase(history: history, referenceDate: ref), 3);
    });

    test('breaks on first invalid day', () {
      final history = [d(0, valid: true), d(1, valid: false), d(2, valid: true)];
      expect(useCase(history: history, referenceDate: ref), 1);
    });

    test('today not done does not penalise streak — counts from J-1', () {
      final history = [d(0, valid: false), d(1, valid: true), d(2, valid: true)];
      expect(useCase(history: history, referenceDate: ref), 2);
    });

    test('today absent — counts from J-1', () {
      final history = [d(1, valid: true), d(2, valid: true)];
      expect(useCase(history: history, referenceDate: ref), 2);
    });

    test('missing day acts as a break', () {
      // daysAgo=1 absent → streak stops at today.
      final history = [d(0, valid: true), d(2, valid: true)];
      expect(useCase(history: history, referenceDate: ref), 1);
    });
  });
}
