import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Résumé journalier de complétion — lu depuis `daily_summaries` Supabase.
///
/// `completion_rate` et `streak_valid` sont des colonnes GENERATED STORED :
/// jamais recalculées côté client. `habit_points_today` est mis à jour par
/// le trigger `trg_update_daily_summary_on_occurrence`.
class DailySummary extends Equatable {
  final UserId userId;

  /// Date calendaire locale (heure = 00:00, fuseau de l'utilisateur).
  final DateTime day;

  /// Taux de complétion : 0.0 à 100.0 (numeric(5,2) Supabase).
  /// Exemple : 70.0 = 70% des items du jour réalisés.
  final double completionRate;

  /// true si completionRate >= 80.0 (seuil streak journalier).
  final bool streakValid;

  /// Points d'habitudes gagnés aujourd'hui : SUM(habit_occurrences.points_earned).
  final int habitPointsToday;

  DailySummary({
    required this.userId,
    required this.day,
    required this.completionRate,
    required this.streakValid,
    required this.habitPointsToday,
  }) {
    if (completionRate < 0 || completionRate > 100) {
      throw ArgumentError.value(
        completionRate,
        'completionRate',
        'completionRate must be in [0, 100]',
      );
    }
    if (habitPointsToday < 0) {
      throw ArgumentError.value(
        habitPointsToday,
        'habitPointsToday',
        'habitPointsToday cannot be negative',
      );
    }
  }

  @override
  List<Object?> get props => [
    userId,
    day,
    completionRate,
    streakValid,
    habitPointsToday,
  ];
}
