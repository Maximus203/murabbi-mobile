import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

/// Fait avancer le log d'une habitude dans le cycle d'états (issue #151).
///
/// Cycle :
/// ```
/// null / missed  →  onTime
/// onTime         →  late
/// late           →  missed
/// ```
///
/// Règle métier : `missed` est distinct de l'absence de log (`null`). Un tap
/// sur `missed` replace à `onTime` (reset visuel).
class ToggleHabitLogUseCase {
  final HabitRepository _repository;
  const ToggleHabitLogUseCase(this._repository);

  /// Calcule l'état suivant à partir de l'état courant ([current] peut être
  /// `null` si aucun log n'existe encore pour la date).
  ///
  /// Logique pure — testable sans repository.
  static HabitLogStatus nextStatus(HabitLogStatus? current) {
    switch (current) {
      case null:
      case HabitLogStatus.missed:
        return HabitLogStatus.onTime;
      case HabitLogStatus.onTime:
        return HabitLogStatus.late;
      case HabitLogStatus.late:
        return HabitLogStatus.missed;
    }
  }

  /// Calcule le prochain statut, le persiste et le retourne.
  ///
  /// [currentStatus] : statut actuel du log pour [date] (`null` si aucun).
  /// Retourne le statut nouvellement persisté.
  Future<HabitLogStatus> call({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus? currentStatus,
  }) async {
    final next = nextStatus(currentStatus);
    await _repository.toggleHabitLog(
      habitId: habitId,
      date: date,
      status: next,
    );
    return next;
  }
}
