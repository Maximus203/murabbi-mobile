import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Contrat du datasource Collections — facilite le mock dans les tests.
abstract interface class SupabaseCollectionDataSource {
  Future<List<Collection>> getCollections(UserId userId);

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
}

/// Implémentation Supabase de [SupabaseCollectionDataSource].
///
/// Table consommée : `collections`
/// Colonnes : id (uuid), name, description, habit_ids (text[]),
///            is_system, is_active, cover_image_url, user_id,
///            created_at, updated_at.
///
/// RLS : l'utilisateur voit ses collections + les collections système
/// (`is_system = true`). La vue Supabase (ou policy RLS) gère le filtre
/// `deleted_at IS NULL` — le domain ne voit jamais les soft-deleted.
class SupabaseCollectionDataSourceImpl implements SupabaseCollectionDataSource {
  static const _table = 'collections';
  static const _columns =
      'id, name, description, habit_ids, is_system, is_active, cover_image_url';

  final sb.SupabaseClient _client;

  const SupabaseCollectionDataSourceImpl(this._client);

  @override
  Future<List<Collection>> getCollections(UserId userId) async {
    // Charge les collections de l'utilisateur + les collections système.
    // La policy RLS Supabase filtre `deleted_at IS NULL` côté serveur.
    final rows = await _client
        .from(_table)
        .select(_columns)
        .or('user_id.eq.${userId.value},is_system.eq.true')
        .order('created_at');

    return rows
        .map<Collection>((r) => _mapRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<void> activateCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    await _client
        .from(_table)
        .update({'is_active': true})
        .eq('id', collectionId.value)
        .eq('user_id', userId.value);
  }

  @override
  Future<void> deactivateCollection({
    required CollectionId collectionId,
    required UserId userId,
  }) async {
    await _client
        .from(_table)
        .update({'is_active': false})
        .eq('id', collectionId.value)
        .eq('user_id', userId.value);
  }

  @override
  Future<Collection> createCollection({
    required Collection collection,
    required UserId userId,
  }) async {
    final row = await _client
        .from(_table)
        .insert(_toRow(collection, userId))
        .select(_columns)
        .single();

    return _mapRow(Map<String, dynamic>.from(row));
  }

  /// Mappe une row Supabase vers [Collection].
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
      'user_id': userId.value,
    };
  }
}
