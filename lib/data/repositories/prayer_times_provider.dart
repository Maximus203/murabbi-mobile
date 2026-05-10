import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/local/shared_prefs_prayer_settings_data_source.dart';
import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:murabbi_mobile/data/repositories/prayer_settings_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_times_use_case.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider Riverpod du `PrayerTimesService` (slice 3.C.2 — ADR-013).
///
/// Constant : `AdhanPrayerTimesService` n'a aucun état mutable. Utilisé par
/// la couche presentation slice 3.C.3 via `GetPrayerTimesUseCase`.
final prayerTimesServiceProvider = Provider<PrayerTimesService>((ref) {
  return const AdhanPrayerTimesService();
});

/// Provider asynchrone des `SharedPreferences` partagées par toute la couche
/// data locale (slice 3.C.2). Singleton — à factoriser dans un fichier
/// `core/providers/` si d'autres data sources locales en ont besoin.
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

/// Provider du `GetPrayerTimesUseCase` — entry point unique pour la couche
/// presentation slice 3.C.3.
final getPrayerTimesUseCaseProvider = FutureProvider<GetPrayerTimesUseCase>((
  ref,
) async {
  final repo = await ref.watch(prayerSettingsRepositoryProvider.future);
  return GetPrayerTimesUseCase(
    service: ref.watch(prayerTimesServiceProvider),
    repository: repo,
  );
});
