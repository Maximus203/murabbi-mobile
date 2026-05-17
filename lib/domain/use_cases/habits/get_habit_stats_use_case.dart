import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_stats.dart';

/// Calcule les statistiques d'une habitude de façon **pure** : aucune
/// dépendance repository, data ou presentation. Toute la logique opère sur
/// la liste de [HabitLog] fournie en parametre.
///
/// Conventions :
/// - Un jour est considere « reussi » si son statut est `onTime` ou `late`
///   (le statut `missed` rompt le streak et ne compte pas dans le taux).
/// - Les dates sont normalisees a minuit UTC pour eviter les decalages
///   d'heure / fuseau.
class GetHabitStatsUseCase {
  const GetHabitStatsUseCase();

  static const int _windowDays = 30;

  HabitStats call({
    required HabitId habitId,
    required List<HabitLog> logs,
    required DateTime referenceDate,
  }) {
    final reference = _normalize(referenceDate);

    // Index statut par jour normalise. En cas de doublon, le dernier gagne.
    final byDay = <DateTime, HabitLogStatus>{
      for (final log in logs) _normalize(log.date): log.status,
    };

    final currentStreak = _currentStreak(byDay, reference);
    final recordStreak = _recordStreak(byDay, currentStreak);
    final heatmap = _heatmap(byDay, reference);
    final rate30Days = _rate30Days(heatmap);

    return HabitStats(
      currentStreak: currentStreak,
      recordStreak: recordStreak < currentStreak ? currentStreak : recordStreak,
      rate30Days: rate30Days,
      heatmapData: heatmap,
    );
  }

  /// Jours consecutifs reussis se terminant a [reference] (inclus).
  int _currentStreak(Map<DateTime, HabitLogStatus> byDay, DateTime reference) {
    var streak = 0;
    var cursor = reference;
    while (true) {
      final status = byDay[cursor];
      if (status == null || !_isSuccess(status)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Meilleur streak observe sur l'ensemble de l'historique fourni.
  int _recordStreak(Map<DateTime, HabitLogStatus> byDay, int currentStreak) {
    if (byDay.isEmpty) return 0;

    final days = byDay.keys.toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      final status = byDay[day]!;
      final consecutive =
          previous != null && day.difference(previous).inDays == 1;
      if (_isSuccess(status)) {
        run = consecutive ? run + 1 : 1;
      } else {
        run = 0;
      }
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  /// 30 entrees : chaque jour de la fenetre [reference-29 .. reference].
  Map<DateTime, HabitLogStatus?> _heatmap(
    Map<DateTime, HabitLogStatus> byDay,
    DateTime reference,
  ) {
    final heatmap = <DateTime, HabitLogStatus?>{};
    for (var i = _windowDays - 1; i >= 0; i--) {
      final day = reference.subtract(Duration(days: i));
      heatmap[day] = byDay[day];
    }
    return heatmap;
  }

  /// Taux de reussite = jours reussis / 30.
  double _rate30Days(Map<DateTime, HabitLogStatus?> heatmap) {
    final success = heatmap.values
        .where((status) => status != null && _isSuccess(status))
        .length;
    return success / _windowDays;
  }

  bool _isSuccess(HabitLogStatus status) =>
      status == HabitLogStatus.onTime || status == HabitLogStatus.late;

  DateTime _normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);
}
