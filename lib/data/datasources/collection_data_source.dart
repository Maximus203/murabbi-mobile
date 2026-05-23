/// Interface fine au-dessus des tables Supabase `collections`
/// et `user_collections` (issue #6, Phase 5 ; migré issue #162).
///
/// Suit le pattern [HabitDataSource] : méthodes minimales retournant des
/// `Map<String, dynamic>` bruts, aucune logique métier, aucune traduction
/// d'erreur — déléguée au repository. Le mapping vers les entités domain est
/// délégué à `CollectionMapper`.
///
/// ## Migration issue #162
///
/// Suite à la révocation de la policy RLS `collection_habits_select_all`,
/// la table `collection_habits` n'est plus accessible depuis le mobile.
/// Les lectures des habits d'une collection passent désormais par la view
/// `published_catalog`. L'accès via [SupabaseCollectionDataSource] est
/// la référence — cette interface [CollectionDataSource] est conservée
/// pour rétrocompatibilité documentaire uniquement.
abstract interface class CollectionDataSource {
  /// Renvoie les rows `collections` visibles par [userId], jointes aux
  /// `user_collections` (scoping `isActive`).
  ///
  /// Les `habitIds` sont fournis via la colonne `habit_ids` (text[]) de
  /// la table `collections` — et NON plus via `collection_habits` (accès
  /// révoqué, migration issue #162).
  ///
  /// Le contrat de soft-delete est appliqué ici (`deleted_at IS NULL`).
  Future<List<Map<String, dynamic>>> getCollections(String userId);

  /// Insère une row `collections` et renvoie la row persistée (avec `id`).
  Future<Map<String, dynamic>> createCollection(Map<String, dynamic> row);

  /// Lie une liste d'habitudes à une collection.
  ///
  /// **Attention (migration #162)** : cette méthode ne doit PAS écrire
  /// directement dans `collection_habits` depuis le mobile — la policy
  /// d'écriture sur cette table est gérée exclusivement côté admin.
  /// Utiliser une RPC Supabase si nécessaire.
  Future<void> linkHabits({
    required String collectionId,
    required List<String> habitIds,
  });

  /// Marque une collection comme activée pour [userId] (table
  /// `user_collections`, upsert idempotent).
  Future<void> activateCollection({
    required String userId,
    required String collectionId,
  });

  /// Désactive une collection pour [userId] — supprime la row
  /// `user_collections(user_id, collection_id)` (pattern symétrique à
  /// `activateCollection`).
  Future<void> deactivateCollection({
    required String userId,
    required String collectionId,
  });
}
