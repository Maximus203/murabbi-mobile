/// Interface fine au-dessus de la table Supabase `categories`.
///
/// Suit le pattern [SalatDataSource] : méthodes minimales retournant des
/// `Map<String, dynamic>` bruts, aucune logique métier, aucune traduction
/// d'erreur — déléguée au repository.
abstract interface class CategoryDataSource {
  /// Renvoie les rows `categories` visibles par l'utilisateur : catégories
  /// système (`is_system = true`, `user_id` NULL) + catégories de
  /// l'utilisateur. Triées par `name`.
  Future<List<Map<String, dynamic>>> getCategories(String userId);

  /// Insère une row `categories` et renvoie la row persistée (avec `id`).
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> row);

  /// Met à jour une row `categories` (clé `id`) et renvoie la row persistée.
  Future<Map<String, dynamic>> updateCategory(Map<String, dynamic> row);

  /// Supprime la row `categories` identifiée par [categoryId].
  Future<void> deleteCategory(String categoryId);
}
