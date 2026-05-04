import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';

/// Calcul de score (logique pure).
///
/// **Habit** (spec v1.5 § 3.2, validation matrix § 4) :
/// - Sans extras : `done` ⇒ habit.points, `late` ⇒ +1, sinon 0
/// - Avec objectif chiffré : 0 si objectif non atteint, peu importe le statut
/// - Avec sous-tâches obligatoires : 0 si pas toutes cochées
/// - Combinaison : ET logique (les deux conditions doivent être satisfaites)
///
/// **Prayer** (Q-02 + Q-07 makeup verrouillées) :
/// - `onTime` ⇒ +3, `late` ⇒ +1, `makeup` ⇒ +1, `missed`/`pending` ⇒ 0
class ScoreCalculatorUseCase {
  static const int latePoints = 1;
  static const int prayerOnTimePoints = 3;

  const ScoreCalculatorUseCase();

  int forHabit(Habit habit, HabitLog log) {
    if (habit.target.hasValue && log.targetReached != true) {
      return 0;
    }
    if (habit.subtasksAllRequired) {
      final completed = log.subtasksCompleted.toSet();
      final required = habit.subtasks.map((s) => s.id).toSet();
      if (!completed.containsAll(required)) {
        return 0;
      }
    }
    switch (log.status) {
      case HabitLogStatus.done:
        return habit.points.value;
      case HabitLogStatus.late:
        return latePoints;
      case HabitLogStatus.missed:
        return 0;
    }
  }

  int forPrayer(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.onTime:
        return prayerOnTimePoints;
      case PrayerStatus.late:
      case PrayerStatus.makeup:
        return latePoints;
      case PrayerStatus.missed:
      case PrayerStatus.pending:
        return 0;
    }
  }
}
