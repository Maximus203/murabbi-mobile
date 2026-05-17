import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';

/// Statistiques agrégées d'une habitude, calculées de façon pure par
/// [GetHabitStatsUseCase] à partir de l'historique de [HabitLog].
///
/// - [currentStreak] : nombre de jours consécutifs `onTime`/`late` se
///   terminant à la date de référence.
/// - [recordStreak] : meilleur streak observé sur l'historique fourni.
/// - [rate30Days] : taux de réussite sur les 30 derniers jours (0.0–1.0),
///   `nb jours onTime+late / 30`.
/// - [heatmapData] : 30 entrées exactement, clé = date à minuit UTC,
///   valeur = statut du log du jour, `null` si aucun log.
class HabitStats extends Equatable {
  final int currentStreak;
  final int recordStreak;
  final double rate30Days;
  final Map<DateTime, HabitLogStatus?> heatmapData;

  HabitStats({
    required this.currentStreak,
    required this.recordStreak,
    required this.rate30Days,
    required this.heatmapData,
  }) {
    if (currentStreak < 0) {
      throw ArgumentError.value(
        currentStreak,
        'currentStreak',
        'HabitStats.currentStreak must be >= 0',
      );
    }
    if (recordStreak < currentStreak) {
      throw ArgumentError.value(
        recordStreak,
        'recordStreak',
        'HabitStats.recordStreak must be >= currentStreak',
      );
    }
    if (rate30Days < 0.0 || rate30Days > 1.0) {
      throw ArgumentError.value(
        rate30Days,
        'rate30Days',
        'HabitStats.rate30Days must be between 0.0 and 1.0',
      );
    }
    if (heatmapData.length != 30) {
      throw ArgumentError.value(
        heatmapData.length,
        'heatmapData.length',
        'HabitStats.heatmapData must contain exactly 30 entries',
      );
    }
  }

  @override
  List<Object?> get props => [
    currentStreak,
    recordStreak,
    rate30Days,
    heatmapData,
  ];
}
