import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class CreateHabitUseCase {
  final HabitRepository _repository;
  const CreateHabitUseCase(this._repository);

  Future<Habit> call({required UserId userId, required Habit habit}) =>
      _repository.createHabit(userId: userId, habit: habit);
}
