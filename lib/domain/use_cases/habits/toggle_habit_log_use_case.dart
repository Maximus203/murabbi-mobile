import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

class ToggleHabitLogUseCase {
  final HabitRepository _repository;
  const ToggleHabitLogUseCase(this._repository);

  Future<void> call({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  }) => _repository.toggleHabitLog(
        habitId: habitId,
        date: date,
        status: status,
      );
}
