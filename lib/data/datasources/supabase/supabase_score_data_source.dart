import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [ScoreDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — déléguées au repository.
///
/// Sources consommées (cf. issue #6) :
///   `users`              — id, total_points
///   `weekly_leaderboard` — vue : user_id, weekly_score, rank
///
/// Non couvert par tests unitaires (pattern `SupabaseHabitDataSource` — la
/// fluent API Supabase est trop fragile à mocker).
class SupabaseScoreDataSource implements ScoreDataSource {
  static const _users = 'users';
  static const _leaderboard = 'weekly_leaderboard';

  final sb.SupabaseClient _client;

  const SupabaseScoreDataSource(this._client);

  @override
  Future<Map<String, dynamic>> getUserScore(String userId) async {
    final userRow = await _client
        .from(_users)
        .select('id, total_points')
        .eq('id', userId)
        .single();

    // La row de classement peut être absente (utilisateur sans événement
    // cette semaine) → on retombe sur des défauts côté mapper.
    final lbRows = await _client
        .from(_leaderboard)
        .select('user_id, weekly_score, rank')
        .eq('user_id', userId)
        .limit(1);

    final merged = Map<String, dynamic>.from(userRow);
    if (lbRows.isNotEmpty) {
      merged.addAll(Map<String, dynamic>.from(lbRows.first));
    }
    return merged;
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard({
    required int limit,
    int offset = 0,
  }) async {
    // Pagination obligatoire (#6) : `range` borne toujours la requête.
    final rows = await _client
        .from(_leaderboard)
        .select('user_id, weekly_score, rank')
        .order('rank', ascending: true)
        .range(offset, offset + limit - 1);
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }
}
