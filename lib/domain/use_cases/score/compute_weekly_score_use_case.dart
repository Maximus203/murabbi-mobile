import 'package:murabbi_mobile/domain/constants/scoring_constants.dart';
import 'package:murabbi_mobile/domain/entities/daily_score.dart';

/// Calcule le score hebdomadaire (logique pure) — issue #6, Phase 5.
///
/// Règle métier : score hebdo = somme des points quotidiens sur la fenêtre
/// glissante de [ScoringConstants.weekLengthDays] jours se terminant à
/// `referenceDate` (incluse).
///
/// Les jours hors fenêtre (trop anciens ou futurs) sont ignorés. Les dates
/// de l'historique sont normalisées (composante horaire écrasée) pour un
/// regroupement journalier robuste.
class ComputeWeeklyScoreUseCase {
  const ComputeWeeklyScoreUseCase();

  int call({
    required List<DailyScore> history,
    required DateTime referenceDate,
  }) {
    if (history.isEmpty) return 0;

    final end = _normalize(referenceDate);
    final start = end.subtract(
      const Duration(days: ScoringConstants.weekLengthDays - 1),
    );

    var total = 0;
    for (final entry in history) {
      final day = _normalize(entry.date);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      total += entry.points;
    }
    return total;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
