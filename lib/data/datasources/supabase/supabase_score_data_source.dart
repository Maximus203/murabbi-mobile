import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [ScoreDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — déléguées au repository.
///
/// Sources consommées (cf. issue #6) :
///   `users`              — id, total_points (via RPC `get_user_score`)
///   `weekly_leaderboard` — vue : user_id, weekly_score, rank
///
/// Lecture atomique du score utilisateur via RPC `get_user_score(p_user_id)`
/// (issue #199, M10) — un seul aller-retour réseau dans une transaction
/// Postgres, élimine la fenêtre de lecture incohérente entre `users` et
/// `weekly_leaderboard`. La migration SQL vit dans `murabbi-admin/supabase/`.
///
/// Non couvert par tests unitaires (pattern `SupabaseHabitDataSource` — la
/// fluent API Supabase est trop fragile à mocker). Garanties par :
///   - `UserScoreMapper` : correctness du mapping (tests unitaires complets).
///   - `*_jwt_test.dart` : ordering `ensureFreshSession()` first (#190).
class SupabaseScoreDataSource implements ScoreDataSource {
  static const _leaderboard = 'weekly_leaderboard';
  static const _rpcGetUserScore = 'get_user_score';

  final sb.SupabaseClient _client;

  /// Wrapper JWT auto-refresh (BUG-001, #190).
  final SupabaseClientWrapper _wrapper;

  const SupabaseScoreDataSource(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  @override
  Future<Map<String, dynamic>> getUserScore(String userId) async {
    await _wrapper.ensureFreshSession();
    // RPC atomique #199 — single round-trip, lecture cohérente users +
    // weekly_leaderboard dans une même transaction Postgres.
    // `.single()` retourne PostgrestMap (= Map<String, dynamic>) — on copie
    // pour produire une map mutable, conforme au contrat du datasource.
    final row = await _client
        .rpc<dynamic>(_rpcGetUserScore, params: {'p_user_id': userId})
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard({
    required int limit,
    int offset = 0,
  }) async {
    await _wrapper.ensureFreshSession();
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
