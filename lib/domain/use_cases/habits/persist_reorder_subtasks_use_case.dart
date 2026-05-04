import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

/// Persiste un nouvel ordre de sous-tâches après drag & drop UI.
/// La logique pure de réindexation vit dans `ReorderSubtasksUseCase` ;
/// ce use case se contente de pousser le résultat au repository.
class PersistReorderSubtasksUseCase {
  final HabitRepository _repository;
  const PersistReorderSubtasksUseCase(this._repository);

  Future<void> call({
    required HabitId habitId,
    required List<HabitSubtaskId> orderedIds,
  }) =>
      _repository.reorderSubtasks(habitId: habitId, orderedIds: orderedIds);
}
