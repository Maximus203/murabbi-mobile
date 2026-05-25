/// Constantes centralisées des noms de tables et de fonctions RPC Supabase.
///
/// Source de vérité unique côté client — tout renommage de table ou de
/// fonction RPC côté base se répercute ici, sans chasse aux strings dans
/// les 11 datasources.
///
/// Convention de nommage :
///   [SupabaseTables]  — tables et vues PostgreSQL
///   [SupabaseRpc]     — fonctions RPC appelées via `.rpc()`
abstract final class SupabaseTables {
  /// Table des profils utilisateurs (`public.users`).
  static const users = 'users';

  /// Table des habitudes.
  static const habits = 'habits';

  /// Table des logs d'habitudes (une entrée par jour validé).
  static const habitLogs = 'habit_logs';

  /// Table de liaison habitudes ↔ collections.
  static const collectionHabits = 'collection_habits';

  /// Table des heures de prière par jour (`prayer_days`).
  static const prayerDays = 'prayer_days';

  /// Table des catégories (système + utilisateur).
  static const categories = 'categories';

  /// Vue du classement hebdomadaire.
  static const weeklyLeaderboard = 'weekly_leaderboard';

  /// Table des collections d'habitudes.
  static const collections = 'collections';

  /// Vue remplaçant `collection_habits` après migration #162 (RLS révoquée).
  ///
  /// Colonnes : `collection_id, habit_id, position, collection_name,
  /// collection_description, cover_image_url, icon, primary_category_id,
  /// category_name, category_color`.
  static const publishedCatalog = 'published_catalog';

  /// Table des résumés journaliers (colonnes GENERATED STORED).
  static const dailySummaries = 'daily_summaries';

  /// Table des niyyahs du jour (une entrée par utilisateur par jour).
  static const dailyNiyyahs = 'daily_niyyahs';

  /// Table des suggestions de niyyah affichées à l'utilisateur.
  static const niyyahSuggestions = 'niyyah_suggestions';
}

abstract final class SupabaseRpc {
  /// RPC atomique créant ou mettant à jour un log d'habitude (#164).
  ///
  /// Paramètres : `p_habit_id`, `p_day` (ISO-8601), `p_status`.
  /// Lève `FUTURE_LOG_NOT_ALLOWED` ou `BACKDATE_TOO_OLD` si règles
  /// temporelles violées.
  static const toggleHabitLog = 'toggle_habit_log';

  /// RPC atomique lisant le score utilisateur + classement (#199).
  ///
  /// Paramètre : `p_user_id`. Retourne `total_score` et `weekly_rank`
  /// en un seul aller-retour, sans fenêtre de lecture incohérente.
  static const getUserScore = 'get_user_score';
}
