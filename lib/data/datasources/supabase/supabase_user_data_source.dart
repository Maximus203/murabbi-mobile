import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_auth_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_tables.dart';
import 'package:murabbi_mobile/data/datasources/user_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [UserDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — déléguées au repository.
///
/// Source consommée : table `public.users` (Q-18). Le SELECT de relecture
/// réutilise [SupabaseAuthDataSource.profileColumns] pour rester aligné sur
/// le contrat de colonnes anti-drift (PR #29).
class SupabaseUserDataSource implements UserDataSource {

  final sb.SupabaseClient _client;

  /// Wrapper JWT auto-refresh (BUG-001, #190).
  final SupabaseClientWrapper _wrapper;

  const SupabaseUserDataSource(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  @override
  Future<Map<String, dynamic>> updatePseudo({
    required String userId,
    required String pseudo,
  }) async {
    await _wrapper.ensureFreshSession();
    final row = await _client
        .from(SupabaseTables.users)
        .update({'pseudo': pseudo})
        .eq('id', userId)
        .select(SupabaseAuthDataSource.profileColumns)
        .single();
    return Map<String, dynamic>.from(row);
  }
}
