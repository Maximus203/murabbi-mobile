import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [HabitDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — celles-ci sont faites dans
/// `HabitRepositoryImpl` (cf. ADR-004 datasource pattern).
///
/// Schémas consommés (cf. `murabbi-admin/supabase/migrations/`) :
///   `habits`     — id, user_id, name, category_id, frequency_type,
///                  frequency, monthly_day, range_start, range_end,
///                  active_days, points, is_system, target_value,
///                  target_unit, target_unit_custom, has_timer,
///                  subtasks_required, created_at
///   `habit_logs` — habit_id, date, status, actual_value, target_reached,
///                  subtasks_completed, duration_seconds, opened_at,
///                  logged_at — contrainte unique (habit_id, date)
///
/// Non couvert par tests unitaires (pattern `SupabaseSalatDataSource` — la
/// fluent API Supabase est trop fragile à mocker, couverte par les
/// integration tests).
class SupabaseHabitDataSource implements HabitDataSource {
  static const _habits = 'habits';
  static const _habitLogs = 'habit_logs';

  final sb.SupabaseClient _client;

  const SupabaseHabitDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getHabits(String userId) async {
    final rows = await _client
        .from(_habits)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createHabit(Map<String, dynamic> row) async {
    final created = await _client.from(_habits).insert(row).select().single();
    return Map<String, dynamic>.from(created);
  }

  @override
  Future<Map<String, dynamic>> updateHabit(Map<String, dynamic> row) async {
    final updated = await _client
        .from(_habits)
        .update(row)
        .eq('id', row['id'] as Object)
        .select()
        .single();
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _client.from(_habits).delete().eq('id', habitId);
  }

  @override
  Future<void> upsertHabitLog(Map<String, dynamic> row) async {
    await _client.from(_habitLogs).upsert(row, onConflict: 'habit_id,date');
  }

  @override
  Future<List<Map<String, dynamic>>> getLogsForHabit({
    required String habitId,
    required String from,
    required String to,
  }) async {
    final rows = await _client
        .from(_habitLogs)
        .select()
        .eq('habit_id', habitId)
        .gte('date', from)
        .lte('date', to)
        .order('date');
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }
}
