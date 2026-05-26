import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès Supabase à la table `niyyah_suggestions`.
class SupabaseNiyyahSuggestionDataSource {
  final SupabaseClient _client;
  final SupabaseClientWrapper _wrapper;

  const SupabaseNiyyahSuggestionDataSource(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  Future<List<Map<String, dynamic>>> getActiveSuggestions() async {
    await _wrapper.ensureFreshSession();
    return _client
        .from(SupabaseTables.niyyahSuggestions)
        .select()
        .eq('active', true)
        .order('sort_order');
  }
}
