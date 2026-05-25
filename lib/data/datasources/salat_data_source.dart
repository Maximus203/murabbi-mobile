/// Interface fine au-dessus de la table Supabase `prayer_days`.
///
/// Suit le pattern `AuthDataSource` (cf. `auth_data_source.dart`) :
///   - méthodes minimales, retournant `Map<String, dynamic>` bruts ou null
///   - aucune logique métier
///   - aucune traduction d'erreur — déléguée au repository
///
/// Le mapping vers les entités domain est délégué à `PrayerDayMapper` dans
/// `PrayerRepositoryImpl`.
abstract interface class SalatDataSource {
  /// Renvoie la row `prayer_days` d'un utilisateur pour un jour donné, ou
  /// `null` si aucun enregistrement n'existe.
  ///
  /// [day] est attendu au format ISO `YYYY-MM-DD` (colonne SQL `date`).
  Future<Map<String, dynamic>?> getPrayerDay({
    required String userId,
    required String day,
  });

  /// Insert ou update une row `prayer_days`, conflit résolu sur la contrainte
  /// `unique (user_id, day)`. La row passée doit déjà être au format
  /// SQL (clés `user_id`, `day`, `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`).
  Future<void> upsertPrayerDay(Map<String, dynamic> row);

  /// Renvoie toutes les rows entre [from] et [to] inclus, triées par jour.
  /// [from] et [to] sont au format ISO `YYYY-MM-DD`.
  Future<List<Map<String, dynamic>>> getPrayerDaysRange({
    required String userId,
    required String from,
    required String to,
  });
}
