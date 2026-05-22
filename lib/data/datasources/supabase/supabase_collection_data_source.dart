import 'package:murabbi_mobile/data/datasources/collection_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase de [CollectionDataSource]. Wrapper thin : aucune
/// logique métier, aucune traduction d'erreur — déléguées au repository
/// (cf. ADR-004 datasource pattern).
///
/// Tables consommées (cf. issue #6) :
///   `collections`       — id, name, description, is_system, created_by,
///                         cover_image_url, deleted_at, created_at
///   `collection_habits` — collection_id, habit_id (PK composite)
///   `user_collections`  — user_id, collection_id, activated_at
///
/// Non couvert par tests unitaires (pattern `SupabaseHabitDataSource` — la
/// fluent API Supabase est trop fragile à mocker, couverte par les
/// integration tests).
class SupabaseCollectionDataSource implements CollectionDataSource {
  static const _collections = 'collections';
  static const _collectionHabits = 'collection_habits';
  static const _userCollections = 'user_collections';

  final sb.SupabaseClient _client;

  const SupabaseCollectionDataSource(this._client);

  @override
  Future<List<Map<String, dynamic>>> getCollections(String userId) async {
    // Jointures imbriquées PostgREST : habitudes liées + activation user.
    // Jointure LEFT (sans `!inner`) sur `user_collections` filtrée sur
    // l'utilisateur → liste imbriquée non vide ⇔ collection active, vide
    // ⇔ inactive (CO-01 affiche les deux). `deleted_at IS NULL` : contrat
    // soft-delete.
    final rows = await _client
        .from(_collections)
        .select(
          'id, name, description, is_system, cover_image_url, created_at, '
          'primary_category_id, icon, '
          'collection_habits(habit_id), '
          'user_collections(user_id)',
        )
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    // Filtre applicatif du scoping user : on ne garde dans
    // `user_collections` que les rows de l'utilisateur courant pour que le
    // mapper dérive `isActive` correctement.
    return rows.map<Map<String, dynamic>>((r) {
      final map = Map<String, dynamic>.from(r);
      final uc = (map['user_collections'] as List<dynamic>?) ?? const [];
      map['user_collections'] = uc
          .where((e) => (e as Map)['user_id'] == userId)
          .toList();
      return map;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> createCollection(
    Map<String, dynamic> row,
  ) async {
    final created = await _client
        .from(_collections)
        .insert(row)
        .select()
        .single();
    return Map<String, dynamic>.from(created);
  }

  @override
  Future<void> linkHabits({
    required String collectionId,
    required List<String> habitIds,
  }) async {
    if (habitIds.isEmpty) return;
    final rows = habitIds
        .map((h) => {'collection_id': collectionId, 'habit_id': h})
        .toList();
    await _client.from(_collectionHabits).insert(rows);
  }

  @override
  Future<void> activateCollection({
    required String userId,
    required String collectionId,
  }) async {
    await _client.from(_userCollections).upsert({
      'user_id': userId,
      'collection_id': collectionId,
    }, onConflict: 'user_id,collection_id');
  }

  @override
  Future<void> deactivateCollection({
    required String userId,
    required String collectionId,
  }) async {
    await _client
        .from(_userCollections)
        .delete()
        .eq('user_id', userId)
        .eq('collection_id', collectionId);
  }
}
