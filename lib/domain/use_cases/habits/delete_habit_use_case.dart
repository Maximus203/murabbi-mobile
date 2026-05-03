import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

class DeleteHabitUseCase {
  final HabitRepository _repository;
  const DeleteHabitUseCase(this._repository);

  Future<void> call(HabitId habitId) => _repository.deleteHabit(habitId);
}
