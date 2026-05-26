import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Mapper pur — convertit les rows Supabase de score en [UserScore] domain
/// (issue #6, Phase 5).
///
/// Sources consommées :
///   - `users` : `id`, `total_points`.
///   - vue `weekly_leaderboard` : `user_id`, `weekly_score`, `rank`.
///   - `user_scores` : `previous_week_rank` (Q-F, v1.2.1).
///
/// Le datasource jointe ces sources et fournit une row plate ; les colonnes
/// absentes retombent sur des défauts sûrs.
class UserScoreMapper {
  const UserScoreMapper._();

  static UserScore fromRow(Map<String, dynamic> row) {
    final totalPoints = (row['total_points'] as int?) ?? 0;
    final rawRank = (row['rank'] as int?) ?? 1;

    return UserScore(
      userId: UserId((row['user_id'] ?? row['id']) as String),
      totalPoints: totalPoints,
      weeklyPoints: (row['weekly_score'] as int?) ?? 0,
      currentLevel: Level.fromPoints(totalPoints),
      weeklyRank: rawRank < 1 ? 1 : rawRank,
      previousWeekRank: row['previous_week_rank'] as int?,
      pseudo: row['pseudo'] as String?,
    );
  }
}
