import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
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
  /// Sélection PostgREST avec relations imbriquées — aligne sur le schéma v1.3.
  ///
  /// - `collection_habits(habit_id)` : habit IDs via junction table.
  /// - `user_collections(*)` : RLS `user_id = auth.uid()` — ne retourne
  ///   que les lignes de l'utilisateur courant, sans passer userId.
  static const _select =
      'id, name, description, cover_image_url, '
      'collection_habits(habit_id), '
      'user_collections(*)';

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
    // Lecture des collections publiées avec leurs habitudes et l'état
    // d'activation de l'utilisateur courant (filtrée par RLS).
    final rows = await _client
        .from('collections')
        .select(_select)
        .eq('status', 'published')
        .isFilter('deleted_at', null)
        .order('name');

    return (rows as List)
        .map<Collection>((r) => _mapRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getHabitsForCollection(
    String collectionId,
  ) async {
    await _wrapper.ensureFreshSession();
    // Lit depuis `collection_habits` — RLS open (SELECT true pour tout
    // utilisateur authentifié selon le schéma v1.3).
    final data = await _client
        .from('collection_habits')
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
    // UPSERT : INSERT si première activation, UPDATE (deactivated_at → null)
    // si l'utilisateur réactive une collection précédemment désactivée.
    await _client.from('user_collections').upsert(
      {
        'user_id': userId.value,
        'collection_id': collectionId.value,
        'deactivated_at': null,
      },
      onConflict: 'user_id,collection_id',
    );
  }

  @override
  Future<void> deactivateCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    await _wrapper.ensureFreshSession();
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from('user_collections')
        .update({'deactivated_at': now})
        .eq('user_id', userId.value)
        .eq('collection_id', collectionId.value)
        .isFilter('deactivated_at', null);
  }

  @override
  Future<Collection> createCollection({
    required Collection collection,
    required UserId userId,
  }) async {
    // La table `collections` est admin-only en INSERT (schéma v1.3).
    // Une migration DB est requise avant d'implémenter les collections
    // personnalisées utilisateur — lève une erreur attrapée par le repo.
    throw UnsupportedError(
      'User-created collections require a Supabase migration not yet deployed.',
    );
  }

  @override
  Future<void> deleteCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    // Collections système non supprimables — requires admin migration.
    // Les collections personnalisées ne sont pas encore déployées (cf. createCollection).
    throw UnsupportedError(
      'deleteCollection requires a Supabase migration not yet deployed.',
    );
  }

  /// Mappe une row PostgREST (avec relations imbriquées) vers [Collection].
  ///
  /// - `collection_habits` → liste des [HabitId]
  /// - `user_collections` (filtrée par RLS) → isActive si présence d'une ligne
  Collection _mapRow(Map<String, dynamic> row) {
    // Relation collection_habits → habit IDs
    final rawHabits = row['collection_habits'] as List<dynamic>? ?? [];
    final habitIds = rawHabits
        .map(
          (ch) => HabitId(
            (ch as Map<String, dynamic>)['habit_id'] as String,
          ),
        )
        .toList();

    // Relation user_collections (RLS → user_id = auth.uid()).
    // isActive : au moins une ligne présente (toute ligne = collection activée).
    final rawUserCols = row['user_collections'] as List<dynamic>? ?? [];
    final isActive = rawUserCols.isNotEmpty;

    return Collection(
      id: CollectionId(row['id'] as String),
      name: NonEmptyString(row['name'] as String),
      description: NonEmptyString(
        (row['description'] as String?)?.trim().isNotEmpty == true
            ? (row['description'] as String).trim()
            : '—',
      ),
      habitIds: habitIds,
      // Toutes les collections du catalogue sont admin-créées (système).
      isSystem: true,
      isActive: isActive,
      coverImageUrl: row['cover_image_url'] as String?,
    );
  }
}
