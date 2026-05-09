import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';

/// Contrat de persistance des [PrayerSettings] côté domain. L'implémentation
/// V1 (SharedPreferences) vit dans `data/repositories/`, ADR-013 §Architecture.
abstract interface class PrayerSettingsRepository {
  /// Retourne les settings persistés ou `null` si l'utilisateur n'a encore
  /// jamais configuré ses prières.
  Future<PrayerSettings?> get();

  /// Persiste l'intégralité des settings — pas de PATCH partiel en V1.
  Future<void> save(PrayerSettings settings);
}
