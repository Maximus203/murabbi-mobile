import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

/// Bascule la présence d'une sous-tâche dans la liste des cochées
/// (utilisé pendant l'exécution d'une habitude — spec v1.5 § 5.5).
///
/// Logique pure : opère sur la liste fournie, retourne la nouvelle liste.
/// La persistance est faite par `HabitLogRepository.logHabit` au moment
/// de la validation finale.
class ToggleSubtaskUseCase {
  const ToggleSubtaskUseCase();

  List<HabitSubtaskId> call({
    required List<HabitSubtaskId> completed,
    required HabitSubtaskId subtaskId,
  }) {
    if (completed.contains(subtaskId)) {
      return completed.where((id) => id != subtaskId).toList(growable: false);
    }
    return [...completed, subtaskId];
  }
}
