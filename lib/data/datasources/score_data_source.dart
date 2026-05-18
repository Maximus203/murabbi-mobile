/// Interface fine au-dessus des sources de score Supabase : table `users`
/// (points totaux) et vue `weekly_leaderboard` (issue #6, Phase 5).
///
/// Suit le pattern [HabitDataSource] : méthodes minimales retournant des
/// `Map<String, dynamic>` bruts, aucune logique métier. Le mapping est
/// délégué à `UserScoreMapper`.
abstract interface class ScoreDataSource {
  /// Renvoie la row de score agrégée d'un utilisateur (points totaux +
  /// score hebdo + rang issus de la vue `weekly_leaderboard`).
  Future<Map<String, dynamic>> getUserScore(String userId);

  /// Renvoie les [limit] meilleures rows de la vue `weekly_leaderboard`,
  /// triées par rang croissant.
  ///
  /// Règle non négociable (#6) : pagination obligatoire — la requête
  /// applique toujours un `LIMIT`/`offset`, jamais de SELECT non borné.
  Future<List<Map<String, dynamic>>> getLeaderboard({
    required int limit,
    int offset,
  });
}
