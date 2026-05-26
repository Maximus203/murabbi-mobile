/// Interface fine au-dessus des tables Supabase `habits` et `habit_logs`.
///
/// Suit le pattern [SalatDataSource] : méthodes minimales retournant des
/// `Map<String, dynamic>` bruts, aucune logique métier, aucune traduction
/// d'erreur — déléguée au repository.
///
/// Le mapping vers les entités domain est délégué aux mappers
/// (`HabitMapper`, `HabitLogMapper`) dans `HabitRepositoryImpl`.
abstract interface class HabitDataSource {
  /// Renvoie toutes les rows `habits` d'un utilisateur, triées par
  /// `created_at` décroissant.
  Future<List<Map<String, dynamic>>> getHabits(String userId);

  /// Insère une row `habits` et renvoie la row persistée (avec `id`).
  Future<Map<String, dynamic>> createHabit(Map<String, dynamic> row);

  /// Met à jour une row `habits` (clé `id`) et renvoie la row persistée.
  Future<Map<String, dynamic>> updateHabit(Map<String, dynamic> row);

  /// Supprime la row `habits` identifiée par [habitId].
  Future<void> deleteHabit(String habitId);

  /// Insert ou update une row `habit_logs`, conflit résolu sur la contrainte
  /// `unique (habit_id, date)`.
  ///
  /// @deprecated Remplacé par [toggleHabitLog] (RPC — #164). Conservé pour
  /// [logHabit] (logging v1.5 avec champs étendus).
  Future<void> upsertHabitLog(Map<String, dynamic> row);

  /// Appelle la RPC Supabase `toggle_habit_log` pour créer/mettre à jour un
  /// log d'habitude (#164).
  ///
  /// La RPC impose deux règles de validation :
  /// - Date future → lance [HabitFutureLogNotAllowedFailure]
  /// - Rétrodatation > 8 jours → lance [HabitBackdateTooOldFailure]
  ///
  /// Retourne la row persistée sous forme de map brute.
  Future<Map<String, dynamic>> toggleHabitLog({
    required String habitId,
    required DateTime date,
    required String status,
  });

  /// Renvoie les rows `habit_logs` d'une habitude entre [from] et [to]
  /// inclus (format ISO `YYYY-MM-DD`), triées par `date`.
  Future<List<Map<String, dynamic>>> getLogsForHabit({
    required String habitId,
    required String from,
    required String to,
  });

  /// Renvoie les rows `habits` liées à une collection via `collection_habits`.
  Future<List<Map<String, dynamic>>> getHabitsForCollection(
    String collectionId,
  );
}
