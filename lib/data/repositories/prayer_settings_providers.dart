import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/local/shared_prefs_prayer_settings_data_source.dart';
import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:murabbi_mobile/data/repositories/prayer_settings_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider asynchrone des [SharedPreferences] partagées par la couche data
/// locale. Singleton — partagé avec [rememberedAccountsStorageProvider]
/// (cf. `remembered_accounts_notifier.dart`).
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Provider du datasource local des [PrayerSettings].
final prayerSettingsDataSourceProvider =
    FutureProvider<PrayerSettingsDataSource>((ref) async {
      final prefs = await ref.watch(sharedPreferencesProvider.future);
      return SharedPrefsPrayerSettingsDataSource(prefs);
    });

/// Provider du repository des [PrayerSettings].
final prayerSettingsRepositoryProvider =
    FutureProvider<PrayerSettingsRepository>((ref) async {
      final ds = await ref.watch(prayerSettingsDataSourceProvider.future);
      return PrayerSettingsRepositoryImpl(ds);
    });
