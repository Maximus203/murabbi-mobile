import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/salat_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [SalatDataSource]. Wrapper thin :
/// aucune logique métier, aucune traduction d'erreur — celles-ci sont faites
/// dans `PrayerRepositoryImpl` (cf. ADR-004 datasource pattern).
///
/// Schéma `prayer_days` consommé (cf. `murabbi-admin/supabase/migrations/`) :
///   id, user_id, date, fajr, dhuhr, asr, maghrib, isha, created_at, updated_at
///   contrainte unique (user_id, date) — utilisée pour l'upsert.
///
/// Note : non couvert par tests unitaires (pattern auth — la fluent API
/// Supabase est trop fragile à mocker, sera couverte par integration tests
/// en slice 3.C+).
class SupabaseSalatDataSource implements SalatDataSource {
  static const _columns = 'user_id, date, fajr, dhuhr, asr, maghrib, isha';

  final sb.SupabaseClient _client;

  /// Wrapper JWT auto-refresh (BUG-001, #190).
  final SupabaseClientWrapper _wrapper;

  const SupabaseSalatDataSource(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  @override
  Future<Map<String, dynamic>?> getPrayerDay({
    required String userId,
    required String day,
  }) async {
    await _wrapper.ensureFreshSession();
    final row = await _client
        .from(SupabaseTables.prayerDays)
        .select(_columns)
        .eq('user_id', userId)
        .eq('date', day)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> upsertPrayerDay(Map<String, dynamic> row) async {
    await _wrapper.ensureFreshSession();
    await _client.from(SupabaseTables.prayerDays).upsert(row, onConflict: 'user_id,date');
  }

  @override
  Future<List<Map<String, dynamic>>> getPrayerDaysRange({
    required String userId,
    required String from,
    required String to,
  }) async {
    await _wrapper.ensureFreshSession();
    final rows = await _client
        .from(SupabaseTables.prayerDays)
        .select(_columns)
        .eq('user_id', userId)
        .gte('date', from)
        .lte('date', to)
        .order('date');
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }
}
