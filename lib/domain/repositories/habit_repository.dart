import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class HabitRepository {
  Future<List<Habit>> getHabits(UserId userId);
  Future<Habit> createHabit({required UserId userId, required Habit habit});
  Future<Habit> updateHabit(Habit habit);
  Future<void> deleteHabit(HabitId habitId);

  Future<void> toggleHabitLog({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  });

  /// Persiste un log v1.5 complet (`actualValue`, `subtasksCompleted`,
  /// `duration`, `targetReached` calculé côté SQL via colonne GENERATED).
  /// Cf. spec v1.5 § 2.3.
  Future<void> logHabit(HabitLog log);

  // -------------------- Subtasks (spec v1.5 § 2.2 / § 3.3) --------------------
  Future<List<HabitSubtask>> getSubtasks(HabitId habitId);
  Future<HabitSubtask> addSubtask(HabitSubtask subtask);
  Future<HabitSubtask> updateSubtask(HabitSubtask subtask);
  Future<void> deleteSubtask(HabitSubtaskId subtaskId);

  /// Persiste le nouvel ordre. Implémentations : transaction qui réécrit
  /// `order_index` 0..N-1 selon [orderedIds].
  Future<void> reorderSubtasks({
    required HabitId habitId,
    required List<HabitSubtaskId> orderedIds,
  });
}
