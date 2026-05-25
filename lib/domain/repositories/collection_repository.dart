import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Domain contract for reading and mutating collections.
///
/// ## Soft-delete contract (admin Phase 3.A — migration `20260504100000`)
///
/// The admin back-office switched [Collection] deletion from a hard `DELETE`
/// to a `deleted_at TIMESTAMPTZ` stamp. The domain layer must NEVER see
/// soft-deleted collections — every read method below MUST be implemented
/// with a `WHERE deleted_at IS NULL` filter at the data layer (Supabase
/// query, REST view, or RPC).
///
/// This is enforced **by contract**, not by the type system: a [Collection]
/// has no `deletedAt` field on purpose. If you ever need to surface tombstones
/// (admin UI?), introduce a separate read method (e.g. `getDeletedCollections`)
/// rather than leaking `deletedAt` into the domain entity.
///
/// Source: `product_decisions_v1.md` (admin) — soft-delete decision.
abstract interface class CollectionRepository {
  /// Returns the collections visible to [userId].
  ///
  /// Implementations MUST filter `deleted_at IS NULL` upstream.
  Future<List<Collection>> getCollections(UserId userId);

  /// Marks an existing system collection as activated for [userId].
  ///
  /// Implementations MUST :
  /// - refuse activation when the collection is soft-deleted
  ///   (`deleted_at IS NOT NULL`) and surface a domain error ;
  /// - duplicate the system habits into the user's space
  ///   (their own `habits` rows with `user_id = userId`) ;
  /// - duplicate the associated `habit_subtasks` rows so the user owns a
  ///   modifiable copy (spec v1.5 § 3.3 — "activation d'une collection
  ///   système").
  Future<void> activateCollection({
    required UserId userId,
    required CollectionId collectionId,
  });

  /// Persists a new user collection.
  Future<Collection> createCollection({
    required UserId userId,
    required Collection collection,
  });

  /// Marque une collection comme désactivée pour [userId].
  ///
  /// Implémentations : mettre `is_active = false` pour la ligne
  /// `(user_id, collection_id)` — ne supprime pas les habitudes dupliquées
  /// (l'utilisateur peut réactiver la collection plus tard).
  Future<void> deactivateCollection({
    required UserId userId,
    required CollectionId collectionId,
  });

  /// Retourne les rows de habits pour une collection depuis `published_catalog`.
  ///
  /// Chaque row contient au minimum `habit_id` (String) et `position` (int).
  /// Les rows sont triées par `position ASC`.
  ///
  /// Remplace tout accès direct à `collection_habits` — révoqué suite à la
  /// migration RLS issue #162. La view `published_catalog` est la seule
  /// source de vérité pour les associations collection ↔ habit côté mobile.
  Future<List<Map<String, dynamic>>> getHabitsForCollection({
    required CollectionId collectionId,
  });
}
