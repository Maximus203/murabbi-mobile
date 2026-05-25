import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/get_habit_stats_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_stats.dart';

void main() {
  final habitId = HabitId('habit-uuid-001');
  // Date de référence fixe pour des tests déterministes.
  final referenceDate = DateTime.utc(2026, 5, 17);

  DateTime dayAt(int daysAgo) =>
      referenceDate.subtract(Duration(days: daysAgo));

  HabitLog logAt(int daysAgo, HabitLogStatus status) =>
      HabitLog(habitId: habitId, date: dayAt(daysAgo), status: status);

  const useCase = GetHabitStatsUseCase();

  HabitStats run(List<HabitLog> logs) =>
      useCase(habitId: habitId, logs: logs, referenceDate: referenceDate);

  group('GetHabitStatsUseCase', () {
    test('returns currentStreak 0 for an empty log list', () {
      final stats = run([]);

      expect(stats.currentStreak, 0);
      expect(stats.recordStreak, 0);
      expect(stats.rate30Days, 0.0);
    });

    test('counts a growing streak over 7 consecutive done days', () {
      final logs = [
        for (var i = 0; i < 7; i++) logAt(i, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.currentStreak, 7);
    });

    test('treats a late log as part of the streak', () {
      final logs = [
        logAt(0, HabitLogStatus.onTime),
        logAt(1, HabitLogStatus.late),
        logAt(2, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.currentStreak, 3);
    });

    test('resets currentStreak to 0 when reference day is missed', () {
      final logs = [
        logAt(0, HabitLogStatus.missed),
        logAt(1, HabitLogStatus.onTime),
        logAt(2, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.currentStreak, 0);
    });

    test('breaks the streak on a missed day in the middle', () {
      final logs = [
        logAt(0, HabitLogStatus.onTime),
        logAt(1, HabitLogStatus.onTime),
        logAt(2, HabitLogStatus.missed),
        logAt(3, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.currentStreak, 2);
    });

    test('preserves recordStreak even after the current streak breaks', () {
      // 5 jours done, puis un missed, puis 2 jours done jusqu'a la reference.
      final logs = [
        logAt(0, HabitLogStatus.onTime),
        logAt(1, HabitLogStatus.onTime),
        logAt(2, HabitLogStatus.missed),
        logAt(3, HabitLogStatus.onTime),
        logAt(4, HabitLogStatus.onTime),
        logAt(5, HabitLogStatus.onTime),
        logAt(6, HabitLogStatus.onTime),
        logAt(7, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.currentStreak, 2);
      expect(stats.recordStreak, 5);
    });

    test('rate30Days is 0.0 when every day in the window is missed', () {
      final logs = [
        for (var i = 0; i < 30; i++) logAt(i, HabitLogStatus.missed),
      ];

      final stats = run(logs);

      expect(stats.rate30Days, 0.0);
    });

    test('rate30Days is 1.0 with 30 consecutive done days', () {
      final logs = [
        for (var i = 0; i < 30; i++) logAt(i, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.rate30Days, 1.0);
    });

    test('heatmapData contains exactly 30 entries', () {
      final stats = run([logAt(0, HabitLogStatus.onTime)]);

      expect(stats.heatmapData.length, 30);
    });

    test('heatmapData maps days without a log to null', () {
      final logs = [logAt(0, HabitLogStatus.onTime)];

      final stats = run(logs);

      expect(
        stats.heatmapData[DateTime.utc(2026, 5, 17)],
        HabitLogStatus.onTime,
      );
      expect(stats.heatmapData[DateTime.utc(2026, 5, 16)], isNull);
    });

    test('heatmapData keys are normalized to UTC midnight', () {
      final logs = [
        HabitLog(
          habitId: habitId,
          date: DateTime.utc(2026, 5, 17, 13, 42, 7),
          status: HabitLogStatus.late,
        ),
      ];

      final stats = run(logs);

      expect(stats.heatmapData[DateTime.utc(2026, 5, 17)], HabitLogStatus.late);
    });

    test('ignores logs outside the 30-day window', () {
      final logs = [
        logAt(40, HabitLogStatus.onTime),
        logAt(35, HabitLogStatus.onTime),
      ];

      final stats = run(logs);

      expect(stats.rate30Days, 0.0);
      expect(stats.heatmapData.values.every((s) => s == null), isTrue);
    });
  });
}
