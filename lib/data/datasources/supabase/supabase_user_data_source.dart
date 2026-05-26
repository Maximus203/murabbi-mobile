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

  /// Q-26 Option A — met à jour `display_name`.
  ///
  /// ⚠ Nécessite la migration `ALTER TABLE users ADD COLUMN display_name TEXT;`
  /// côté murabbi-admin avant d'être activé en production. Jusqu'à
  /// l'application de la migration, tout appel à cette méthode lèvera une
  /// erreur Supabase (colonne inconnue).
  ///
  /// [displayName] vide → stocké null (effacement du nom complet).
  @override
  Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    await _wrapper.ensureFreshSession();
    final row = await _client
        .from(SupabaseTables.users)
        .update({'display_name': displayName.isEmpty ? null : displayName})
        .eq('id', userId)
        .select('display_name')
        .single();
    return Map<String, dynamic>.from(row);
  }
}
