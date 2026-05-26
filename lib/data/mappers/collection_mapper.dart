import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Mapper pur — convertit les rows `collections` Supabase en [Collection]
/// domain et inversement (issue #6, Phase 5 ; migré issue #162).
///
/// ## Schéma `collections` consommé (post-migration #162)
///
/// Colonnes directes : `id, name, description, is_system, cover_image_url`.
///
/// Les `habitIds` proviennent désormais de la view `published_catalog` via la
/// clé `habit_ids` (liste de strings) injectée par le datasource — et NON plus
/// de la jointure imbriquée `collection_habits` (révoquée par RLS, cf. #162).
///
/// Le statut `isActive` est dérivé de la présence d'une row dans
/// `user_collections` filtrée sur l'utilisateur courant (`user_collections`
/// liste non vide).
///
/// Le contrat de soft-delete (`deleted_at IS NULL`) est appliqué côté
/// requête datasource — voir [SupabaseCollectionDataSourceImpl].
class CollectionMapper {
  const CollectionMapper._();

  /// SQL row (avec `habit_ids` et `user_collections`) → entité domain.
  ///
  /// Attend la structure suivante dans [row] :
  /// - `id` (String) — uuid de la collection
  /// - `name` (String) — nom non vide
  /// - `description` (String?) — description, fallback si null/vide
  /// - `is_system` (bool?) — défaut false
  /// - `cover_image_url` (String?) — nullable
  /// - `habit_ids` (List of dynamic) — liste de strings (uuids), peut être
  ///   null ou vide pour les collections corrompues côté admin
  /// - `user_collections` (List of dynamic) — liste de rows ; non vide ⇒
  ///   collection activée pour l'utilisateur
  ///
  /// **Clé `collection_habits` supprimée (migration #162)** — ne pas la
  /// référencer. La view `published_catalog` fournit les habit_ids.
  static Collection fromRow(Map<String, dynamic> row) {
    // habit_ids est maintenant une liste de strings directe (post-#162).
    // L'ancienne clé `collection_habits` (objets imbriqués) est révoquée.
    final rawIds = row['habit_ids'];
    List<HabitId> habitIds;
    if (rawIds is List && rawIds.isNotEmpty) {
      habitIds = rawIds
          .map((id) => HabitId(id.toString()))
          .toList(growable: false);
    } else {
      // Données corrompues ou collection vide : placeholder pour ne pas
      // crasher — le datasource devrait filtrer en amont.
      habitIds = [];
    }

    final userCollections =
        (row['user_collections'] as List<dynamic>?) ?? const [];

    // `description` est nullable côté SQL ; le domaine exige une chaîne non
    // vide → fallback explicite si la colonne est absente / vide.
    final descRaw = (row['description'] as String?)?.trim();
    final description = (descRaw == null || descRaw.isEmpty)
        ? 'Sans description'
        : descRaw;

    final rawCatId = row['primary_category_id'] as String?;

    return Collection(
      id: CollectionId(row['id'] as String),
      name: NonEmptyString(row['name'] as String),
      description: NonEmptyString(description),
      habitIds: habitIds.isEmpty ? [HabitId('placeholder')] : habitIds,
      isSystem: (row['is_system'] as bool?) ?? false,
      isActive: userCollections.isNotEmpty,
      coverImageUrl: row['cover_image_url'] as String?,
      primaryCategoryId: rawCatId != null ? CategoryId(rawCatId) : null,
      icon: row['icon'] as String?,
    );
  }

  /// Entité domain → SQL row `collections` (sans les habitIds joints ni le
  /// statut `isActive`, persistés dans des tables séparées).
  static Map<String, dynamic> toRow(Collection collection) {
    return {
      'id': collection.id.value,
      'name': collection.name.value,
      'description': collection.description.value,
      'is_system': collection.isSystem,
      if (collection.coverImageUrl != null)
        'cover_image_url': collection.coverImageUrl,
      if (collection.primaryCategoryId != null)
        'primary_category_id': collection.primaryCategoryId!.value,
      if (collection.icon != null) 'icon': collection.icon,
    };
  }

  /// Extrait les [HabitId] depuis les rows `published_catalog`.
  ///
  /// Les rows doivent être triées par `position ASC` (ordre garanti par le
  /// datasource — `.order('position')`).
  ///
  /// Schéma `published_catalog` attendu par colonne :
  /// `collection_id, habit_id, position, collection_name, ...`
  ///
  /// Seul `habit_id` est extrait ici.
  static List<HabitId> habitIdsFromCatalogRows(
    List<Map<String, dynamic>> rows,
  ) {
    return rows
        .map((r) => HabitId(r['habit_id'] as String))
        .toList(growable: false);
  }
}
