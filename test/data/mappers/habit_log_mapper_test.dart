import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/habit_log_mapper.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

void main() {
  group('HabitLogMapper.fromRow', () {
    test('maps a minimal log with optional v1.5 columns null', () {
      final log = HabitLogMapper.fromRow({
        'habit_id': 'habit-1',
        'date': '2026-05-09',
        'status': 'ontime',
        'actual_value': null,
        'target_reached': null,
        'subtasks_completed': null,
        'duration_seconds': null,
        'opened_at': null,
        'logged_at': null,
      });
      expect(log.habitId, HabitId('habit-1'));
      expect(log.date, DateTime.utc(2026, 5, 9));
      expect(log.status, HabitLogStatus.onTime);
      expect(log.actualValue, isNull);
      expect(log.targetReached, isNull);
      expect(log.subtasksCompleted, isEmpty);
      expect(log.duration, isNull);
    });

    test('maps a full v1.5 log', () {
      final log = HabitLogMapper.fromRow({
        'habit_id': 'habit-1',
        'date': '2026-05-09',
        'status': 'late',
        'actual_value': 12,
        'target_reached': true,
        'subtasks_completed': ['st-1', 'st-2'],
        'duration_seconds': 1800,
        'opened_at': '2026-05-09T08:00:00.000Z',
        'logged_at': '2026-05-09T08:30:00.000Z',
      });
      expect(log.status, HabitLogStatus.late);
      expect(log.actualValue, 12);
      expect(log.targetReached, true);
      expect(log.subtasksCompleted, [
        HabitSubtaskId('st-1'),
        HabitSubtaskId('st-2'),
      ]);
      expect(log.duration, const Duration(seconds: 1800));
      expect(log.openedAt, DateTime.utc(2026, 5, 9, 8));
      expect(log.loggedAt, DateTime.utc(2026, 5, 9, 8, 30));
    });
  });

  group('HabitLogMapper.toRow', () {
    test('round-trips a full v1.5 log', () {
      final log = HabitLog(
        habitId: HabitId('habit-1'),
        date: DateTime.utc(2026, 5, 9),
        status: HabitLogStatus.missed,
        actualValue: 5,
        targetReached: false,
        subtasksCompleted: [HabitSubtaskId('st-1')],
        duration: const Duration(seconds: 600),
      );
      final row = HabitLogMapper.toRow(log);
      expect(row['habit_id'], 'habit-1');
      expect(row['date'], '2026-05-09');
      expect(row['status'], 'missed');
      expect(row['actual_value'], 5);
      expect(row['target_reached'], false);
      expect(row['subtasks_completed'], ['st-1']);
      expect(row['duration_seconds'], 600);
    });

    test('emits nulls for absent optional fields', () {
      final log = HabitLog(
        habitId: HabitId('habit-1'),
        date: DateTime.utc(2026, 5, 9),
        status: HabitLogStatus.onTime,
      );
      final row = HabitLogMapper.toRow(log);
      expect(row['actual_value'], isNull);
      expect(row['duration_seconds'], isNull);
      expect(row['subtasks_completed'], isEmpty);
    });
  });
}
