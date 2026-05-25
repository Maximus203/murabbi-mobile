import 'package:equatable/equatable.dart';

/// Résumé de complétion journalier — source de vérité pour l'objectif
/// quotidien (80%) et le streak (Q-A / Q-23).
///
/// Mappé depuis la table `daily_summaries` Supabase.
/// Les colonnes `completion_rate` et `streak_valid` sont GENERATED STORED
/// côté base — on les lit directement, jamais recalculées côté client.
class DailySummary extends Equatable {
  /// Identifiant Supabase de l'utilisateur.
  final String userId;

  /// Date calendaire locale (heure = 00:00).
  final DateTime day;

  /// Prières attendues ce jour + habitudes `user_habits.active = true`.
  final int totalItems;

  /// Occurrences `validated` + prières non-missed/non-pending ce jour.
  final int doneItems;

  /// `doneItems / totalItems * 100` — 0 si `totalItems == 0`. Calculé en base.
  final double completionRate;

  /// `true` si `completionRate >= 80.0`. Calculé en base.
  final bool streakValid;

  const DailySummary({
    required this.userId,
    required this.day,
    required this.totalItems,
    required this.doneItems,
    required this.completionRate,
    required this.streakValid,
  });

  @override
  List<Object?> get props => [userId, day, totalItems, doneItems, completionRate, streakValid];
}
