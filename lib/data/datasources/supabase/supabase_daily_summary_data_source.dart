import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès Supabase à la table `daily_summaries`.
///
/// Les colonnes `completion_rate` et `streak_valid` sont GENERATED STORED —
/// on les lit directement sans les recalculer côté client.
class SupabaseDailySummaryDataSource {
  final SupabaseClient _client;

  const SupabaseDailySummaryDataSource(this._client);

  Future<Map<String, dynamic>?> getTodaySummary(String userId) async {
    final rows = await _client
        .from('daily_summaries')
        .select()
        .eq('user_id', userId)
        .eq('day', _todayIso())
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getRecentSummaries(
    String userId, {
    int days = 30,
  }) async {
    final from = DateTime.now().subtract(Duration(days: days));
    return _client
        .from('daily_summaries')
        .select()
        .eq('user_id', userId)
        .gte('day', _dateIso(from))
        .order('day', ascending: false);
  }

  String _todayIso() => _dateIso(DateTime.now());

  String _dateIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
