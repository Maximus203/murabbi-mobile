/// Interface fine au-dessus des tables Supabase `collections`,
/// `collection_habits` et `user_collections` (issue #6, Phase 5).
///
/// Suit le pattern [HabitDataSource] : méthodes minimales retournant des
/// `Map<String, dynamic>` bruts, aucune logique métier, aucune traduction
/// d'erreur — déléguée au repository. Le mapping vers les entités domain est
/// délégué à `CollectionMapper`.
abstract interface class CollectionDataSource {
  /// Renvoie les rows `collections` visibles par [userId], jointes aux
  /// `collection_habits` et `user_collections` (scoping `isActive`).
  ///
  /// Le contrat de soft-delete est appliqué ici (`deleted_at IS NULL`).
  Future<List<Map<String, dynamic>>> getCollections(String userId);

  /// Insère une row `collections` et renvoie la row persistée (avec `id`).
  Future<Map<String, dynamic>> createCollection(Map<String, dynamic> row);

  /// Lie une liste d'habitudes à une collection (table `collection_habits`).
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
}
