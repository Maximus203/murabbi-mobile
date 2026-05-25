import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Convertit une row `daily_summaries` en [DailySummary].
///
/// Colonnes attendues : `user_id`, `day`, `completion_rate`,
/// `streak_valid`, `habit_points_today`.
/// `completion_rate` et `streak_valid` sont GENERATED STORED — jamais
/// recalculées côté client.
class DailySummaryMapper {
  const DailySummaryMapper._();

  static DailySummary fromRow(Map<String, dynamic> row) {
    return DailySummary(
      userId: UserId(row['user_id'] as String),
      day: DateTime.parse(row['day'] as String),
      completionRate: (row['completion_rate'] as num).toDouble(),
      streakValid: row['streak_valid'] as bool,
      habitPointsToday: (row['habit_points_today'] as int?) ?? 0,
    );
  }
}
