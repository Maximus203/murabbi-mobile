import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_tables.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Contrat du datasource Collections — facilite le mock dans les tests.
///
/// ## Migration issue #162 — published_catalog
///
/// Suite à la révocation de la policy RLS `collection_habits_select_all`,
/// tout accès direct à la table `collection_habits` lève une erreur RLS.
/// Les lecture des habits d'une collection passent désormais par la view
/// `published_catalog` (colonnes : `collection_id, habit_id, position,
/// collection_name, collection_description, cover_image_url, icon,
/// primary_category_id, category_name, category_color`).
abstract interface class SupabaseCollectionDataSource {
  Future<List<Collection>> getCollections(UserId userId);

  /// Retourne les rows `published_catalog` pour la collection [collectionId].
  ///
  /// Chaque row contient au moins `habit_id` et `position`.
  /// Les rows sont triées par `position ASC`.
  ///
  /// Remplace tout accès direct à `collection_habits` (révoqué — issue #162).
  Future<List<Map<String, dynamic>>> getHabitsForCollection(
    String collectionId,
  );

  Future<void> activateCollection({
    required CollectionId collectionId,
    required UserId userId,
  });

  Future<void> deactivateCollection({
    required CollectionId collectionId,
    required UserId userId,
  });

  Future<Collection> createCollection({
    required Collection collection,
    required UserId userId,
  });

  /// Supprime une collection utilisateur (`is_system = false`).
  ///
  /// Le filtre `user_id + is_system = false` garantit qu'on ne supprime
  /// jamais une collection système, même en cas d'appel incorrect.
  Future<void> deleteCollection({
    required CollectionId collectionId,
    required UserId userId,
  });
}

/// Implémentation Supabase de [SupabaseCollectionDataSource].
///
/// ## Tables/views consommées
///
/// - `collections` : lecture principale des métadonnées (id, name, …).
/// - `published_catalog` (view) : lecture des habit_ids par collection
///   (remplace les accès directs à `collection_habits` — migration #162).
/// - `user_collections` : statut d'activation (`is_active`) par utilisateur.
///
/// ## RLS
///
/// L'utilisateur voit ses collections + les collections système
/// (`is_system = true`). La view `published_catalog` filtre les habits
/// publiés côté Supabase — le domaine ne voit jamais les soft-deleted.
class SupabaseCollectionDataSourceImpl implements SupabaseCollectionDataSource {
  /// Colonnes sélectionnées sur la table `collections`.
  ///
  /// `primary_category_id` et `icon` dépendent de la migration admin AR-04
  /// (Q-23 verrouillée). Nullable dans le mapping — si la colonne n'existe
  /// pas encore, Supabase retourne `null` pour ces champs.
  static const _columns =
      'id, name, description, habit_ids, is_system, is_active, '
      'cover_image_url, primary_category_id, icon';

  final sb.SupabaseClient _client;

  /// Wrapper JWT auto-refresh (BUG-001, #190).
  final SupabaseClientWrapper _wrapper;

  const SupabaseCollectionDataSourceImpl(
    this._client, {
    required SupabaseClientWrapper wrapper,
  }) : _wrapper = wrapper;

  @override
  Future<List<Collection>> getCollections(UserId userId) async {
    await _wrapper.ensureFreshSession();
    // Charge les collections de l'utilisateur + les collections système.
    // La policy RLS Supabase filtre `deleted_at IS NULL` côté serveur.
    final rows = await _client
        .from(SupabaseTables.collections)
        .select(_columns)
        .or('user_id.eq.${userId.value},is_system.eq.true')
        .order('created_at');

    return rows
        .map<Collection>((r) => _mapRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitsForCollection(
    String collectionId,
  ) async {
    await _wrapper.ensureFreshSession();
    // Lit depuis `published_catalog` — remplace l'accès direct à
    // `collection_habits` révoqué par RLS (migration issue #162).
    final data = await _client
        .from(SupabaseTables.publishedCatalog)
        .select('habit_id, position')
        .eq('collection_id', collectionId)
        .order('position');
    return List<Map<String, dynamic>>.from(data as List);
  }

  @override
  Future<void> activateCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    await _wrapper.ensureFreshSession();
    await _client
        .from(SupabaseTables.collections)
        .update({'is_active': true})
        .eq('id', collectionId.value)
        .eq('user_id', userId.value);
  }

  @override
  Future<void> deactivateCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    await _wrapper.ensureFreshSession();
    await _client
        .from(SupabaseTables.collections)
        .update({'is_active': false})
        .eq('id', collectionId.value)
        .eq('user_id', userId.value);
  }

  @override
  Future<Collection> createCollection({
    required Collection collection,
    required UserId userId,
  }) async {
    await _wrapper.ensureFreshSession();
    final row = await _client
        .from(SupabaseTables.collections)
        .insert(_toRow(collection, userId))
        .select(_columns)
        .single();

    return _mapRow(Map<String, dynamic>.from(row));
  }

  /// Mappe une row Supabase vers [Collection].
  ///
  /// Lit `habit_ids` (colonne text[] sur `collections`) — et non plus
  /// `collection_habits` (accès révoqué par RLS, migration issue #162).
  Collection _mapRow(Map<String, dynamic> row) {
    // habit_ids est stocké en JSON array côté Supabase
    final rawIds = row['habit_ids'];
    List<HabitId> habitIds;
    if (rawIds is List) {
      habitIds = rawIds.map((id) => HabitId(id.toString())).toList();
    } else {
      habitIds = [];
    }

    // Une collection doit avoir au moins 1 habitude — si vide (données
    // corrompues), on insère un placeholder plutôt que de crasher.
    if (habitIds.isEmpty) {
      habitIds = [HabitId('placeholder')];
    }

    final rawCategoryId = row['primary_category_id'] as String?;

    return Collection(
      id: CollectionId(row['id'] as String),
      name: NonEmptyString(row['name'] as String),
      description: NonEmptyString(
        (row['description'] as String?) ?? 'Collection sans description',
      ),
      habitIds: habitIds,
      isSystem: row['is_system'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? false,
      coverImageUrl: row['cover_image_url'] as String?,
      primaryCategoryId:
          rawCategoryId != null ? CategoryId(rawCategoryId) : null,
      icon: row['icon'] as String?,
    );
  }

  /// Sérialise une [Collection] vers une row Supabase.
  Map<String, dynamic> _toRow(Collection c, UserId userId) {
    return {
      'id': c.id.value,
      'name': c.name.value,
      'description': c.description.value,
      'habit_ids': c.habitIds.map((id) => id.value).toList(),
      'is_system': c.isSystem,
      'is_active': c.isActive,
      'cover_image_url': c.coverImageUrl,
      'primary_category_id': c.primaryCategoryId?.value,
      'icon': c.icon,
      'user_id': userId.value,
    };
  }

  @override
  Future<void> deleteCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    await _wrapper.ensureFreshSession();
    // Filtre triple : id + user_id + is_system = false.
    // Empêche toute suppression accidentelle d'une collection système.
    await _client
        .from(SupabaseTables.collections)
        .delete()
        .eq('id', collectionId.value)
        .eq('user_id', userId.value)
        .eq('is_system', false);
  }
}
