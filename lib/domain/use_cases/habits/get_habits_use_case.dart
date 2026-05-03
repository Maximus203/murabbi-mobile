import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetHabitsUseCase {
  final HabitRepository _repository;
  const GetHabitsUseCase(this._repository);

  Future<List<Habit>> call(UserId userId) => _repository.getHabits(userId);
}
