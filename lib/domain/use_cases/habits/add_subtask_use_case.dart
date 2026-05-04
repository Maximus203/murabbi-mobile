import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';

class AddSubtaskUseCase {
  final HabitRepository _repository;
  const AddSubtaskUseCase(this._repository);

  Future<HabitSubtask> call(HabitSubtask subtask) =>
      _repository.addSubtask(subtask);
}
