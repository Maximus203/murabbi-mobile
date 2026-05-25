import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';

/// Lit les [PrayerSettings] persistés. Renvoie `null` si l'utilisateur n'a
/// jamais configuré ses prières — la couche présentation (slice 3.C.3)
/// utilisera ce signal pour proposer le pré-remplissage par pays
/// ([DeriveDefaultMethodFromCountryUseCase]).
class GetPrayerSettingsUseCase {
  final PrayerSettingsRepository _repository;
  const GetPrayerSettingsUseCase(this._repository);

  Future<PrayerSettings?> call() => _repository.get();
}
