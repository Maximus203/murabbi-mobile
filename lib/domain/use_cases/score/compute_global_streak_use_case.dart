import 'package:murabbi_mobile/domain/entities/daily_summary.dart';

/// Streak global = jours consécutifs à rebours depuis [referenceDate]
/// où `DailySummary.streakValid == true` (objectif 80% atteint, Q-23 Option A).
///
/// Règles :
/// - Aujourd'hui non encore terminé (`streakValid = false` ou absent) ne
///   pénalise pas le streak — on commence à compter à partir de J-1.
/// - Un trou d'un seul jour calendaire casse le streak.
/// - Si la liste est vide → 0.
class ComputeGlobalStreakUseCase {
  const ComputeGlobalStreakUseCase();

  int call({
    required List<DailySummary> history,
    required DateTime referenceDate,
  }) {
    if (history.isEmpty) return 0;

    final today = _normalize(referenceDate);

    // Indexer par date normalisée pour lookup O(1).
    final byDay = <DateTime, bool>{
      for (final s in history) _normalize(s.day): s.streakValid,
    };

    var streak = 0;

    // Si aujourd'hui n'est pas validé (absent ou false), on commence à J-1.
    var cursor = (byDay[today] == true) ? today : today.subtract(const Duration(days: 1));

    while (true) {
      final valid = byDay[cursor];
      if (valid != true) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
