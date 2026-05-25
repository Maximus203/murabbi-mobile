import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès Supabase à la table `niyyah_suggestions`.
class SupabaseNiyyahSuggestionDataSource {
  final SupabaseClient _client;

  const SupabaseNiyyahSuggestionDataSource(this._client);

  Future<List<Map<String, dynamic>>> getActiveSuggestions() async {
    return _client
        .from('niyyah_suggestions')
        .select()
        .eq('active', true)
        .order('sort_order');
  }
}
