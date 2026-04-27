import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
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
}
