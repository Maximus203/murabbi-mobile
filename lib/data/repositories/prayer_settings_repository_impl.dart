import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:murabbi_mobile/data/mappers/prayer_settings_mapper.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';

/// Implémentation production — délègue à un [PrayerSettingsDataSource]
/// (V1 = SharedPreferences) et passe par [PrayerSettingsMapper] pour la
/// sérialisation. Si le blob persisté est corrompu (`fromJson` lève), on
/// retourne `null` plutôt que de crasher l'app : la couche use case
/// retombera sur les defaults intelligents.
class PrayerSettingsRepositoryImpl implements PrayerSettingsRepository {
  final PrayerSettingsDataSource _dataSource;

  const PrayerSettingsRepositoryImpl(this._dataSource);

  @override
  Future<PrayerSettings?> get() async {
    final json = await _dataSource.read();
    if (json == null) return null;
    try {
      return PrayerSettingsMapper.fromJson(json);
    } on ArgumentError {
      return null;
    }
  }

  @override
  Future<void> save(PrayerSettings settings) async {
    await _dataSource.write(PrayerSettingsMapper.toJson(settings));
  }
}
