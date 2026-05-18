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
/// Table consommée : `user_scores`
/// Colonnes réelles (migration 20260426000000_initial_mobile_schema.sql) :
///   user_id uuid, total_score int, weekly_score int, level int (1-6).
///
/// Note : `weekly_rank` n'existe pas dans le schéma DB. La position dans
/// le leaderboard est dérivée de l'index de la row dans le résultat ordonné.
/// Pour un accès par user_id unique (`getUserScore`), weeklyRank = 9999
/// (sentinelle "inconnu"). Sera affiné par un RPC de ranking si le besoin
/// s'en fait sentir (cf. Q-26).
///
/// Note : non couvert par tests unitaires (la fluent API Supabase est trop
/// fragile à mocker — pattern aligné sur `SupabaseSalatDataSource`).
/// Sera couvert par les integration tests Slice 5.B+.
class SupabaseScoreDataSourceImpl implements SupabaseScoreDataSource {
  static const _table = 'user_scores';
  static const _columns = 'user_id, total_score, weekly_score, level';

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

    // weeklyRank inconnu pour un accès unitaire — sentinelle 9999.
    return _mapRow(row, rank: 9999);
  }

  @override
  Future<List<UserScore>> getLeaderboard({required int limit}) async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .order('total_score', ascending: false)
        .limit(limit);

    // Le rang hebdomadaire est dérivé de la position dans le résultat
    // (ordonné par total_score desc) faute de colonne weekly_rank en DB.
    return rows
        .asMap()
        .entries
        .map<UserScore>(
          (e) => _mapRow(Map<String, dynamic>.from(e.value), rank: e.key + 1),
        )
        .toList();
  }

  /// Mappe une row Supabase (Map) vers [UserScore].
  ///
  /// [rank] : position dans le leaderboard (1-based) ou 9999 si inconnu.
  UserScore _mapRow(Map<String, dynamic> row, {required int rank}) {
    return UserScore(
      userId: UserId(row['user_id'] as String),
      totalPoints: row['total_score'] as int,
      weeklyPoints: row['weekly_score'] as int? ?? 0,
      currentLevel: Level.fromInt(row['level'] as int),
      weeklyRank: rank,
    );
  }
}
