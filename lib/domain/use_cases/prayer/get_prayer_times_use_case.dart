import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

/// Calcule les horaires de prière pour [day] (par défaut aujourd'hui en UTC)
/// à partir des [PrayerSettings] persistés.
///
/// Lève [PrayerFailure.settingsNotConfigured] si l'utilisateur n'a jamais
/// configuré ses prières — la couche presentation (slice 3.C.3) doit alors
/// rediriger vers `prayer_settings_screen.dart`.
class GetPrayerTimesUseCase {
  final PrayerTimesService _service;
  final PrayerSettingsRepository _repository;

  const GetPrayerTimesUseCase({
    required PrayerTimesService service,
    required PrayerSettingsRepository repository,
  }) : _service = service,
       _repository = repository;

  /// [day] est interprété comme un jour civil UTC ; passer `null` retourne
  /// les horaires du jour courant UTC.
  Future<PrayerTimes> call({DateTime? day}) async {
    final settings = await _repository.get();
    if (settings == null) {
      throw const PrayerFailure.settingsNotConfigured();
    }
    final now = day ?? DateTime.now().toUtc();
    final civilDay = DateTime.utc(now.year, now.month, now.day);
    return _service.computeForDay(settings: settings, day: civilDay);
  }
}
