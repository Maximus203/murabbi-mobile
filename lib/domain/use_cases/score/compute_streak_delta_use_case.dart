import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_global_streak_use_case.dart';

/// Delta de streak entre aujourd'hui et il y a 7 jours (issue #6, Phase 5).
///
/// Δstreak = streak(referenceDate) − streak(referenceDate − 7 jours).
///
/// - Positif → la série a progressé cette semaine.
/// - Négatif → régression.
/// - Zéro    → stable.
///
/// La règle "aujourd'hui non encore validé ne pénalise pas" est héritée de
/// [ComputeGlobalStreakUseCase] qui commence à J-1 quand today n'est pas valide.
class ComputeStreakDeltaUseCase {
  const ComputeStreakDeltaUseCase();

  /// Calcule le delta en appliquant [ComputeGlobalStreakUseCase] deux fois
  /// sur le même [history] : une fois à [referenceDate], une fois à
  /// [referenceDate] − 7 jours.
  int call({
    required List<DailySummary> history,
    required DateTime referenceDate,
  }) {
    const streak = ComputeGlobalStreakUseCase();
    final now = streak(history: history, referenceDate: referenceDate);
    final before = streak(
      history: history,
      referenceDate: referenceDate.subtract(const Duration(days: 7)),
    );
    return now - before;
  }
}
