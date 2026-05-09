import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub RED — slice 3.C.1.
class SharedPrefsPrayerSettingsDataSource implements PrayerSettingsDataSource {
  static const String storageKey = 'murabbi_prayer_settings_v1';

  // ignore: unused_field
  final SharedPreferences _prefs;

  const SharedPrefsPrayerSettingsDataSource(this._prefs);

  @override
  Future<Map<String, dynamic>?> read() async {
    throw UnimplementedError(
      'SharedPrefsPrayerSettingsDataSource.read — RED stub',
    );
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    throw UnimplementedError(
      'SharedPrefsPrayerSettingsDataSource.write — RED stub',
    );
  }
}
