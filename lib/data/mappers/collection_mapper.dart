import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

/// Mapper pur — convertit les rows `collections` Supabase en [Collection]
/// domain et inversement (issue #6, Phase 5).
///
/// Schéma `collections` consommé (cf. issue #6) :
///   `id, name, description, is_system, created_by, created_at`.
///
/// Les `habitIds` proviennent de la jointure imbriquée `collection_habits`
/// (`collection_habits(habit_id)`). Le statut `isActive` est dérivé de la
/// présence d'une row dans `user_collections` filtrée sur l'utilisateur
/// courant (`user_collections(user_id)`).
///
/// Le contrat de soft-delete (`deleted_at IS NULL`) est appliqué côté
/// requête datasource — voir [CollectionRepository].
class CollectionMapper {
  const CollectionMapper._();

  /// SQL row (avec jointures imbriquées) → entité domain.
  static Collection fromRow(Map<String, dynamic> row) {
    final habitsRaw = (row['collection_habits'] as List<dynamic>?) ?? const [];
    final habitIds = habitsRaw
        .map((e) => HabitId((e as Map)['habit_id'] as String))
        .toList(growable: false);

    final userCollections =
        (row['user_collections'] as List<dynamic>?) ?? const [];

    // `description` est nullable côté SQL ; le domaine exige une chaîne non
    // vide → fallback explicite si la colonne est absente / vide.
    final descRaw = (row['description'] as String?)?.trim();
    final description = (descRaw == null || descRaw.isEmpty)
        ? 'Sans description'
        : descRaw;

    return Collection(
      id: CollectionId(row['id'] as String),
      name: NonEmptyString(row['name'] as String),
      description: NonEmptyString(description),
      habitIds: habitIds,
      isSystem: (row['is_system'] as bool?) ?? false,
      isActive: userCollections.isNotEmpty,
      coverImageUrl: row['cover_image_url'] as String?,
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
    };
  }
}
