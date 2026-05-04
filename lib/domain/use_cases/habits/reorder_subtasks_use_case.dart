import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

/// Réordonne une liste de sous-tâches selon l'ordre fourni (drag & drop).
/// Logique pure : retourne une nouvelle liste avec `orderIndex` réassignés
/// de 0 à N-1, dans l'ordre de [newOrder].
class ReorderSubtasksUseCase {
  const ReorderSubtasksUseCase();

  List<HabitSubtask> call({
    required List<HabitSubtask> subtasks,
    required List<HabitSubtaskId> newOrder,
  }) {
    if (newOrder.length != subtasks.length) {
      throw ArgumentError(
        'ReorderSubtasksUseCase: newOrder length must match subtasks length',
      );
    }
    final byId = {for (final s in subtasks) s.id: s};
    final reordered = <HabitSubtask>[];
    for (var i = 0; i < newOrder.length; i++) {
      final id = newOrder[i];
      final s = byId[id];
      if (s == null) {
        throw ArgumentError.value(
          id.value,
          'newOrder[$i]',
          'unknown subtask id',
        );
      }
      reordered.add(s.copyWith(orderIndex: i));
    }
    return reordered;
  }
}
