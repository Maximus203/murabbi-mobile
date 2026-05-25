import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Mapper pur — convertit les rows Supabase de score en [UserScore] domain
/// (issue #6, Phase 5).
///
/// Sources consommées :
///   - RPC `get_user_score`    : user_id, total_points, weekly_score, rank, pseudo.
///   - Vue `weekly_leaderboard`: user_id, weekly_score, rank, pseudo.
///
/// Le datasource jointe ces sources et fournit une row plate ; les colonnes
/// absentes retombent sur des défauts sûrs (0 point, rang 1) pour ne jamais
/// violer les invariants de [UserScore] (`weeklyRank > 0`).
///
/// Le niveau est **dérivé** de [totalPoints] via [Level.fromPoints] —
/// jamais lu d'une colonne (source de vérité domaine).
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
      pseudo: row['pseudo'] as String?,
    );
  }
}
