import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès Supabase à la table `daily_niyyahs`.
class SupabaseNiyyahDataSource {
  final SupabaseClient _client;

  const SupabaseNiyyahDataSource(this._client);

  Future<Map<String, dynamic>?> getTodayNiyyah(String userId) async {
    final today = _todayIso();
    final rows = await _client
        .from('daily_niyyahs')
        .select()
        .eq('user_id', userId)
        .eq('day', today)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>> setTodayNiyyah(
    String userId,
    String text,
  ) async {
    final today = _todayIso();
    final rows = await _client
        .from('daily_niyyahs')
        .upsert(
          {'user_id': userId, 'day': today, 'text': text},
          onConflict: 'user_id,day',
        )
        .select();
    return (rows as List).first as Map<String, dynamic>;
  }

  String _todayIso() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
