import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Contrat du datasource Score — facilite le mock dans les tests.
abstract interface class SupabaseScoreDataSource {
  /// Charge le score de l'utilisateur depuis la vue `user_scores`.
  Future<UserScore> getUserScore(UserId userId);

  /// Charge le classement global (top [limit] utilisateurs).
  Future<List<UserScore>> getLeaderboard({required int limit});
}

/// Implémentation Supabase de [SupabaseScoreDataSource].
///
/// Table/vue consommée : `user_scores`
/// Colonnes attendues : user_id, total_points, weekly_points, level (string),
/// weekly_rank.
///
/// Note : non couvert par tests unitaires (la fluent API Supabase est trop
/// fragile à mocker — pattern aligné sur `SupabaseSalatDataSource`).
/// Sera couvert par les integration tests Slice 5.B+.
class SupabaseScoreDataSourceImpl implements SupabaseScoreDataSource {
  static const _table = 'user_scores';
  static const _columns =
      'user_id, total_points, weekly_points, level, weekly_rank';

  final sb.SupabaseClient _client;

  const SupabaseScoreDataSourceImpl(this._client);

  @override
  Future<UserScore> getUserScore(UserId userId) async {
    final row = await _client
        .from(_table)
        .select(_columns)
        .eq('user_id', userId.value)
        .maybeSingle();

    if (row == null) {
      throw const ScoreFailure.notFound(message: 'user_scores row absent');
    }

    return _mapRow(row);
  }

  @override
  Future<List<UserScore>> getLeaderboard({required int limit}) async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .order('total_points', ascending: false)
        .limit(limit);

    return rows
        .map<UserScore>((r) => _mapRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Mappe une row Supabase (Map) vers [UserScore].
  UserScore _mapRow(Map<String, dynamic> row) {
    return UserScore(
      userId: UserId(row['user_id'] as String),
      totalPoints: row['total_points'] as int,
      weeklyPoints: row['weekly_points'] as int? ?? 0,
      currentLevel: Level.fromString(row['level'] as String),
      weeklyRank: row['weekly_rank'] as int? ?? 9999,
    );
  }
}
