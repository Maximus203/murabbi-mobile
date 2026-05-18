import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [CategoryDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — celles-ci sont faites dans
/// `CategoryRepositoryImpl` (cf. ADR-004 datasource pattern).
///
/// Schéma `categories` consommé : `id, user_id, name, color, icon,
/// is_system`. Les catégories système ont `user_id` NULL et `is_system`
/// true ; `getCategories` les ramène en plus de celles de l'utilisateur via
/// un filtre `or(user_id.eq.<id>, is_system.eq.true)`.
///
/// Non couvert par tests unitaires (pattern `SupabaseSalatDataSource`).
class SupabaseCategoryDataSource implements CategoryDataSource {
  static const _table = 'categories';

  final sb.SupabaseClient _client;

  const SupabaseCategoryDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    final rows = await _client
        .from(_table)
        .select()
        .or('user_id.eq.$userId,is_system.eq.true')
        .order('name');
    return rows
        .map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> row) async {
    final created = await _client.from(_table).insert(row).select().single();
    return Map<String, dynamic>.from(created);
  }

  @override
  Future<Map<String, dynamic>> updateCategory(Map<String, dynamic> row) async {
    final updated = await _client
        .from(_table)
        .update(row)
        .eq('id', row['id'] as Object)
        .select()
        .single();
    return Map<String, dynamic>.from(updated);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from(_table).delete().eq('id', categoryId);
  }
}
