import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

/// Persiste le log d'une habitude à objectif chiffré ou timer (spec v1.5 § 2.3).
///
/// Calcule [HabitLog.targetReached] : `actualValue >= targetValue`.
/// Toujours enregistré avec [HabitLogStatus.onTime] — l'utilisateur valide
/// explicitement via le modal objectif ou timer.
class LogHabitValueUseCase {
  final HabitRepository _repository;
  const LogHabitValueUseCase(this._repository);

  Future<void> call({
    required HabitId habitId,
    required DateTime date,
    required int actualValue,
    required int targetValue,
    List<HabitSubtaskId> subtasksCompleted = const [],
    Duration? duration,
    DateTime? openedAt,
  }) async {
    final log = HabitLog(
      habitId: habitId,
      date: date,
      status: HabitLogStatus.onTime,
      actualValue: actualValue,
      targetReached: actualValue >= targetValue,
      subtasksCompleted: subtasksCompleted,
      duration: duration,
      openedAt: openedAt,
      loggedAt: DateTime.now().toUtc(),
    );
    await _repository.logHabit(log);
  }
}
