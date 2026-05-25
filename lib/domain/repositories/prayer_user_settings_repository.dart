import 'package:murabbi_mobile/domain/entities/prayer_user_settings.dart';

/// Contrat de persistance des [PrayerUserSettings] avec double couche
/// (local sécurisé + Supabase remote).
///
/// Cf. MOB-004 — remplace [PrayerSettingsRepository] (V1 SharedPreferences)
/// pour la sync Supabase bidirectionnelle.
///
/// **Stratégie de conflit** : `remote wins` basé sur [PrayerUserSettings.updatedAt].
/// **TTL local** : 1 heure (vérifié dans [PrayerSettingsSyncService]).
abstract interface class PrayerUserSettingsRepository {
  /// Charge les settings depuis le stockage local sécurisé.
  /// Retourne `null` si aucun settings n'a encore été persisté.
  Future<PrayerUserSettings?> loadLocal(String userId);

  /// Persiste les settings localement (flutter_secure_storage).
  /// Écriture synchrone du point de vue métier.
  Future<void> saveLocal(PrayerUserSettings settings);

  /// Récupère les settings depuis Supabase (table `prayer_user_settings`).
  /// Retourne `null` si aucune ligne n'existe pour cet utilisateur.
  /// Lève une [Exception] en cas d'erreur réseau.
  Future<PrayerUserSettings?> fetchRemote(String userId);

  /// Upsert des settings vers Supabase.
  /// Utilise la stratégie ON CONFLICT (user_id) DO UPDATE.
  Future<void> upsertRemote(PrayerUserSettings settings);
}
