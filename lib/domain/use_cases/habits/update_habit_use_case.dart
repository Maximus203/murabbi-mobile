import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';

class UpdateHabitUseCase {
  final HabitRepository _repository;
  const UpdateHabitUseCase(this._repository);

  Future<Habit> call(Habit habit) => _repository.updateHabit(habit);
}
