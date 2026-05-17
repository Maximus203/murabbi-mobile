import 'package:murabbi_mobile/domain/constants/scoring_constants.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';

/// Calcul de score (logique pure).
///
/// **Habit** (spec v1.5 § 3.2, validation matrix § 4) :
/// - Sans extras : `onTime` ⇒ habit.points, `late` ⇒ +1, sinon 0
/// - Avec objectif chiffré : 0 si objectif non atteint, peu importe le statut
/// - Avec sous-tâches obligatoires : 0 si pas toutes cochées
/// - Combinaison : ET logique (les deux conditions doivent être satisfaites)
///
/// **Prayer** (Q-02 + Q-07 makeup verrouillées) :
/// - `onTime` ⇒ +3, `late` ⇒ +1, `makeup` ⇒ +1, `missed`/`pending` ⇒ 0
class ScoreCalculatorUseCase {
  /// @deprecated — conservé pour compatibilité ; voir [ScoringConstants].
  static const int latePoints = ScoringConstants.prayerLatePoints;

  /// @deprecated — conservé pour compatibilité ; voir [ScoringConstants].
  static const int prayerOnTimePoints = ScoringConstants.prayerOnTimePoints;

  const ScoreCalculatorUseCase();

  int forHabit(Habit habit, HabitLog log) {
    if (habit.target.hasValue && !_isTargetReached(habit.target, log)) {
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
      case HabitLogStatus.onTime:
        return habit.points.value;
      case HabitLogStatus.late:
        return ScoringConstants.habitLatePoints;
      case HabitLogStatus.missed:
        return ScoringConstants.habitMissedPoints;
    }
  }

  /// Source de vérité du domaine : on **recalcule** "atteint ?" depuis
  /// `habit.target` et `log.actualValue` plutôt que de faire confiance à
  /// `log.targetReached` (colonne SQL `GENERATED` qui peut ne pas être
  /// hydratée en lecture immédiate après écriture). `targetReached` reste
  /// utilisable comme cache d'optimisation côté requêtes analytiques.
  /// Cf. ADR-008 § "Scoring computation: domain truth, DB cache"
  /// (Copilot review #5).
  bool _isTargetReached(HabitTarget target, HabitLog log) {
    final actual = log.actualValue;
    if (actual == null) {
      // Si une valeur explicite a été cachée par le DB trigger, l'utiliser
      // en dernier recours (lecture batch sans fetch séparé).
      return log.targetReached == true;
    }
    return switch (target) {
      HabitTargetNone() => true,
      HabitTargetValue(:final value) => actual >= value.value,
      HabitTargetTimed(:final value) => actual >= value.value,
    };
  }

  int forPrayer(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.onTime:
        return ScoringConstants.prayerOnTimePoints;
      case PrayerStatus.late:
      case PrayerStatus.makeup:
        return ScoringConstants.prayerLatePoints;
      case PrayerStatus.missed:
      case PrayerStatus.pending:
        return ScoringConstants.prayerMissedPoints;
    }
  }
}
