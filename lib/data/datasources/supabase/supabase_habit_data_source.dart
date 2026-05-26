import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_tables.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [HabitDataSource].
///
/// Wrapper thin : les erreurs RPC sémantiques (`FUTURE_LOG_NOT_ALLOWED`,
/// `BACKDATE_TOO_OLD`) sont traduites en [HabitFailure] dans [toggleHabitLog]
/// car le datasource est le seul niveau à accéder à [sb.PostgrestException].
/// Toutes les autres méthodes laissent remonter les exceptions brutes vers
/// [HabitRepositoryImpl] (cf. ADR-004).
///
/// Schémas consommés (cf. `murabbi-admin/supabase/migrations/`) :
///   `habits`     — id, user_id, name, category_id, frequency_type,
///                  frequency, monthly_day, range_start, range_end,
///                  active_days, points, is_system, target_value,
///                  target_unit, target_unit_custom, has_timer,
///                  subtasks_required, created_at
///   `habit_logs` — habit_id, date, status, actual_value, target_reached,
///                  subtasks_completed, duration_seconds, opened_at,
///                  logged_at
///
/// RPC consommée (#164) :
///   `toggle_habit_log(p_habit_id, p_day, p_status)` — crée ou met à jour
///   un log. Lance `FUTURE_LOG_NOT_ALLOWED` ou `BACKDATE_TOO_OLD` si les
///   règles temporelles sont violées.
///
/// Non couvert par tests unitaires (pattern `SupabaseSalatDataSource` — la
/// fluent API Supabase est trop fragile à mocker, couverte par les
/// integration tests).
class SupabaseHabitDataSource implements HabitDataSource {
  final sb.SupabaseClient _client;

  /// Wrapper JWT auto-refresh (BUG-001, #190) — appelé en tête de chaque
  /// méthode publique pour garantir un token frais avant toute requête.
  final SupabaseClientWrapper _wrapper;

  const SupabaseHabitDataSource(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  @override
  Future<List<Map<String, dynamic>>> getHabits(String userId) async {
    await _wrapper.ensureFreshSession();
    final rows = await _client
        .from(SupabaseTables.habits)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createHabit(Map<String, dynamic> row) async {
    await _wrapper.ensureFreshSession();
    final created = await _client
        .from(SupabaseTables.habits)
        .insert(row)
        .select()
        .single();
    return Map<String, dynamic>.from(created);
  }

  @override
  Future<Map<String, dynamic>> updateHabit(Map<String, dynamic> row) async {
    await _wrapper.ensureFreshSession();
    final updated = await _client
        .from(SupabaseTables.habits)
        .update(row)
        .eq('id', row['id'] as Object)
        .select()
        .single();
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _wrapper.ensureFreshSession();
    await _client.from(SupabaseTables.habits).delete().eq('id', habitId);
  }

  @override
  Future<void> upsertHabitLog(Map<String, dynamic> row) async {
    await _wrapper.ensureFreshSession();
    try {
      await _client
          .from(SupabaseTables.habitLogs)
          .upsert(row, onConflict: 'habit_id,date');
    } on sb.PostgrestException catch (e) {
      // Issue #198 (M4) : la contrainte UNIQUE (habit_id, logged_date)
      // côté Supabase peut lever code 23505 sur double-tap concurrent.
      throw mapHabitPostgrestException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLogsForHabit({
    required String habitId,
    required String from,
    required String to,
  }) async {
    await _wrapper.ensureFreshSession();
    final rows = await _client
        .from(SupabaseTables.habitLogs)
        .select()
        .eq('habit_id', habitId)
        .gte('date', from)
        .lte('date', to)
        .order('date');
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  /// #164 — Appelle la RPC `toggle_habit_log`.
  ///
  /// Traduit les erreurs RPC sémantiques en [HabitFailure] typées :
  /// - `FUTURE_LOG_NOT_ALLOWED` → [HabitFutureLogNotAllowedFailure]
  /// - `BACKDATE_TOO_OLD` → [HabitBackdateTooOldFailure]
  /// - Autres [sb.PostgrestException] → [HabitDatabaseFailure]
  @override
  Future<Map<String, dynamic>> toggleHabitLog({
    required String habitId,
    required DateTime date,
    required String status,
  }) async {
    await _wrapper.ensureFreshSession();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    try {
      final result = await _client.rpc<Map<String, dynamic>>(
        SupabaseRpc.toggleHabitLog,
        params: {
          'p_habit_id': habitId,
          'p_day': '$y-$m-$d',
          'p_status': status,
        },
      );
      return Map<String, dynamic>.from(result);
    } on sb.PostgrestException catch (e) {
      throw mapHabitPostgrestException(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitsForCollection(
    String collectionId,
  ) async {
    await _wrapper.ensureFreshSession();
    final rows = await _client
        .from(SupabaseTables.collectionHabits)
        .select('habits(*)')
        .eq('collection_id', collectionId);
    return rows
        .map<Map<String, dynamic>>(
          (r) => Map<String, dynamic>.from(r['habits'] as Map),
        )
        .toList();
  }
}

/// Traduit une [sb.PostgrestException] en [HabitFailure] typée.
///
/// Codes Postgres natifs reconnus :
/// - `23505` (unique_violation) → [HabitFailure.duplicate] (#198 / M4)
///
/// Codes sémantiques RPC `toggle_habit_log` (migration 20260523000001).
/// Utilise `==` et non `.contains()` — PostgreSQL pose le code exactement
/// dans `message` via `RAISE EXCEPTION 'CODE' USING HINT = '...'` :
/// - `FUTURE_LOG_NOT_ALLOWED` → [HabitFailure.futureLogNotAllowed]
/// - `BACKDATE_TOO_OLD`       → [HabitFailure.backdateTooOld]
/// - `HABIT_NOT_FOUND`        → [HabitFailure.unauthorized] (ownership raté)
/// - `AUTH_REQUIRED`          → [HabitFailure.unauthorized]
///
/// Sinon → [HabitFailure.database] (message + code transportés pour debug).
HabitFailure mapHabitPostgrestException(sb.PostgrestException e) {
  if (e.code == '23505') {
    return HabitFailure.duplicate(message: '${e.message} (${e.code})');
  }
  return switch (e.message) {
    'FUTURE_LOG_NOT_ALLOWED' => const HabitFailure.futureLogNotAllowed(
      message: 'Impossible de logger une date future',
    ),
    'BACKDATE_TOO_OLD' => const HabitFailure.backdateTooOld(
      message: 'Rétrodatation limitée à 8 jours',
    ),
    'HABIT_NOT_FOUND' ||
    'AUTH_REQUIRED' => HabitFailure.unauthorized(message: e.message),
    _ => HabitFailure.database(message: '${e.message} (${e.code})'),
  };
}
