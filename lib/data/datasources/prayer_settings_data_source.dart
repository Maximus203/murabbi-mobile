/// Source de données brute pour les [PrayerSettings] — JSON in/out.
///
/// V1 : implémentation locale `SharedPreferences`. V1.5 : possible
/// implémentation Supabase pour sync multi-device (ADR-013 décision §V1.5).
abstract interface class PrayerSettingsDataSource {
  /// Retourne le JSON sérialisé persisté ou `null` si jamais sauvegardé.
  Future<Map<String, dynamic>?> read();

  /// Écrase le JSON existant (pas de PATCH partiel).
  Future<void> write(Map<String, dynamic> json);
}
