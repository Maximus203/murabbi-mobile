import 'package:murabbi_mobile/data/datasources/supabase/supabase_score_data_source.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation du [ScoreRepository] adossée à un [SupabaseScoreDataSource].
///
/// Responsabilités :
/// 1. Déléguer les opérations au datasource.
/// 2. Traduire les exceptions natives Supabase en [ScoreFailure] typées
///    (pattern aligné sur [PrayerRepositoryImpl._guard]).
class ScoreRepositoryImpl implements ScoreRepository {
  final SupabaseScoreDataSource _ds;

  const ScoreRepositoryImpl(this._ds);

  @override
  Future<UserScore> getUserScore(UserId userId) =>
      _guard(() => _ds.getUserScore(userId));

  @override
  Future<List<UserScore>> getLeaderboard({required int limit}) =>
      _guard(() => _ds.getLeaderboard(limit: limit));

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
