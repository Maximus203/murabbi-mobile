import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';

/// Stub RED — slice 3.C.1.
class PrayerSettingsRepositoryImpl implements PrayerSettingsRepository {
  // ignore: unused_field
  final PrayerSettingsDataSource _dataSource;

  const PrayerSettingsRepositoryImpl(this._dataSource);

  @override
  Future<PrayerSettings?> get() async {
    throw UnimplementedError('PrayerSettingsRepositoryImpl.get — RED stub');
  }

  @override
  Future<void> save(PrayerSettings settings) async {
    throw UnimplementedError('PrayerSettingsRepositoryImpl.save — RED stub');
  }
}
