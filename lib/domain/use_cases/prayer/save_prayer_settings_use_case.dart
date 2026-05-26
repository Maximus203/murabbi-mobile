import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';

/// Persiste l'intégralité des [PrayerSettings] (pas de PATCH partiel).
/// L'invariant de validité (lat / lng dans les bornes) est garanti par le
/// constructeur de [PrayerSettings] côté entité.
class SavePrayerSettingsUseCase {
  final PrayerSettingsRepository _repository;
  const SavePrayerSettingsUseCase(this._repository);

  Future<void> call(PrayerSettings settings) => _repository.save(settings);
}
