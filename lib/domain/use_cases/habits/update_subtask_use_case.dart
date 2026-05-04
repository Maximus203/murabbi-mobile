import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';

class UpdateSubtaskUseCase {
  final HabitRepository _repository;
  const UpdateSubtaskUseCase(this._repository);

  Future<HabitSubtask> call(HabitSubtask subtask) =>
      _repository.updateSubtask(subtask);
}
