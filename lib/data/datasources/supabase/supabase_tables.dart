/// Noms canoniques des tables Supabase — évite les magic strings dispersés
/// dans les datasources.
///
/// Toute nouvelle table doit être référencée ici avant d'être utilisée dans
/// un datasource (règle de nommage S-3 — cf. CLAUDE.md §11).
abstract final class SupabaseTables {
  SupabaseTables._();

  static const String users = 'users';
  static const String habits = 'habits';
  static const String habitLogs = 'habit_logs';
  static const String prayers = 'prayer_logs';
  static const String prayerDays = 'prayer_days';
  static const String categories = 'categories';
  static const String collections = 'collections';
  static const String collectionItems = 'collection_items';
  static const String userScores = 'user_scores';
  static const String dailySummaries = 'daily_summaries';
  static const String niyyahs = 'niyyahs';
  static const String niyyahSuggestions = 'niyyah_suggestions';
}
