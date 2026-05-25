import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [CategoryDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — celles-ci sont faites dans
/// `CategoryRepositoryImpl` (cf. ADR-004 datasource pattern).
///
/// Schéma `categories` consommé : `id, user_id, name, color, icon,
/// is_system, slug`. Les catégories système ont `user_id` NULL et `is_system`
/// true ; `getCategories` les ramène en plus de celles de l'utilisateur via
/// un filtre `or(user_id.eq.<id>, is_system.eq.true)`.
///
/// Non couvert par tests unitaires (pattern `SupabaseSalatDataSource`).
class SupabaseCategoryDataSource implements CategoryDataSource {

  final sb.SupabaseClient _client;

  /// Wrapper JWT auto-refresh (BUG-001, #190).
  final SupabaseClientWrapper _wrapper;

  const SupabaseCategoryDataSource(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  @override
  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    await _wrapper.ensureFreshSession();
    final rows = await _client
        .from(SupabaseTables.categories)
        .select()
        .or('user_id.eq.$userId,is_system.eq.true')
        .order('name');
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getCategoryBySlug(
    String userId,
    String slug,
  ) async {
    await _wrapper.ensureFreshSession();
    final row = await _client
        .from(SupabaseTables.categories)
        .select()
        .or('user_id.eq.$userId,is_system.eq.true')
        .eq('slug', slug)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> row) async {
    await _wrapper.ensureFreshSession();
    final created = await _client.from(SupabaseTables.categories).insert(row).select().single();
    return Map<String, dynamic>.from(created);
  }

  @override
  Future<Map<String, dynamic>> updateCategory(Map<String, dynamic> row) async {
    await _wrapper.ensureFreshSession();
    final updated = await _client
        .from(SupabaseTables.categories)
        .update(row)
        .eq('id', row['id'] as Object)
        .select()
        .single();
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _wrapper.ensureFreshSession();
    await _client.from(SupabaseTables.categories).delete().eq('id', categoryId);
  }
}
