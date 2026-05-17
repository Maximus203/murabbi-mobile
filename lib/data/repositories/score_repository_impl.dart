import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:murabbi_mobile/data/mappers/user_score_mapper.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Implémentation Supabase du [ScoreRepository] — délègue à un
/// [ScoreDataSource] et passe par `UserScoreMapper`. Suit le pattern
/// `HabitRepositoryImpl` (#149).
class ScoreRepositoryImpl implements ScoreRepository {
  final ScoreDataSource _ds;

  const ScoreRepositoryImpl(this._ds);

  @override
  Future<UserScore> getUserScore(UserId userId) async {
    final row = await _ds.getUserScore(userId.value);
    return UserScoreMapper.fromRow(row);
  }

  @override
  Future<List<UserScore>> getLeaderboard({required int limit}) async {
    // Pagination obligatoire (#6) : on transmet toujours un `limit` borné
    // au datasource — aucun SELECT non borné.
    final rows = await _ds.getLeaderboard(limit: limit);
    return rows.map(UserScoreMapper.fromRow).toList(growable: false);
  }
}
