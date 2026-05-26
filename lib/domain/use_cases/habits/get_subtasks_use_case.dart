import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

class GetSubtasksUseCase {
  final HabitRepository _repository;
  const GetSubtasksUseCase(this._repository);

  Future<List<HabitSubtask>> call(HabitId habitId) =>
      _repository.getSubtasks(habitId);
}
