import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:murabbi_mobile/data/mappers/user_score_mapper.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase du [ScoreRepository] — délègue à un
/// [ScoreDataSource] et passe par `UserScoreMapper`. Suit le pattern
/// `PrayerRepositoryImpl` (#149) : les exceptions natives sont traduites
/// en [ScoreFailure] typées, jamais laissées remonter brutes.
class ScoreRepositoryImpl implements ScoreRepository {
  final ScoreDataSource _ds;

  const ScoreRepositoryImpl(this._ds);

  @override
  Future<UserScore> getUserScore(UserId userId) => _guard(() async {
    final row = await _ds.getUserScore(userId.value);
    return UserScoreMapper.fromRow(row);
  });

  @override
  Future<List<UserScore>> getLeaderboard({required int limit}) =>
      _guard(() async {
        // Pagination obligatoire (#6) : on transmet toujours un `limit` borné.
        final rows = await _ds.getLeaderboard(limit: limit);
        return rows.map(UserScoreMapper.fromRow).toList(growable: false);
      });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ScoreFailure {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw ScoreFailure.database(message: '${e.code ?? ''} ${e.message}');
    } catch (e) {
      throw _translate(e);
    }
  }

  ScoreFailure _translate(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('rate_limit') ||
        msg.contains('rate limit')) {
      return ScoreFailure.network(message: error.toString());
    }
    return ScoreFailure.unknown(message: error.toString());
  }
}
