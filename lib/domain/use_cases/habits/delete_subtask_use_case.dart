import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

class DeleteSubtaskUseCase {
  final HabitRepository _repository;
  const DeleteSubtaskUseCase(this._repository);

  Future<void> call(HabitSubtaskId id) => _repository.deleteSubtask(id);
}
