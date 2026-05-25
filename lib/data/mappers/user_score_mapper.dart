import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Mapper pur — convertit les rows Supabase de score en [UserScore] domain
/// (issue #6, Phase 5).
///
/// Sources consommées :
///   - `users` : `id`, `total_points`.
///   - vue `weekly_leaderboard` : `user_id`, `weekly_score`, `rank`.
///
/// Le datasource jointe ces sources et fournit une row plate ; les colonnes
/// absentes retombent sur des défauts sûrs (0 point, rang 1) pour ne jamais
/// violer les invariants de [UserScore] (`weeklyRank > 0`).
class UserScoreMapper {
  const UserScoreMapper._();

  /// SQL row → entité domain. Le niveau est **dérivé** des points totaux via
  /// [Level.fromPoints] — jamais lu d'une colonne (source de vérité domaine).
  static UserScore fromRow(Map<String, dynamic> row) {
    final totalPoints = (row['total_points'] as int?) ?? 0;
    final rawRank = (row['rank'] as int?) ?? 1;

    return UserScore(
      userId: UserId((row['user_id'] ?? row['id']) as String),
      totalPoints: totalPoints,
      weeklyPoints: (row['weekly_score'] as int?) ?? 0,
      currentLevel: Level.fromPoints(totalPoints),
      weeklyRank: rawRank < 1 ? 1 : rawRank,
    );
  }
}
