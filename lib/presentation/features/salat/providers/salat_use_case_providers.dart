import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/prayer_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/prayer_times_provider.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/derive_default_method_from_country_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_today_prayers_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/mark_prayer_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/save_prayer_settings_use_case.dart';

/// Re-export du provider `getPrayerTimesUseCaseProvider` défini en slice
/// 3.C.2 — les consumers presentation slice 3.C.3 importent un unique fichier.
export 'package:murabbi_mobile/data/repositories/prayer_times_provider.dart'
    show getPrayerTimesUseCaseProvider;

/// Use case providers de la feature Salat (slice 3.C.3).
///
/// Chacun de ces providers est conçu pour être surchargé en test
/// (`overrideWithValue`) — la couche presentation ne dépend que d'eux, jamais
/// des repositories ni des datasources directement.

final getTodayPrayersUseCaseProvider = Provider<GetTodayPrayersUseCase>((ref) {
  return GetTodayPrayersUseCase(ref.watch(prayerRepositoryProvider));
});

final markPrayerUseCaseProvider = Provider<MarkPrayerUseCase>((ref) {
  return MarkPrayerUseCase(ref.watch(prayerRepositoryProvider));
});

final getPrayerSettingsUseCaseProvider =
    FutureProvider<GetPrayerSettingsUseCase>((ref) async {
      final repo = await ref.watch(prayerSettingsRepositoryProvider.future);
      return GetPrayerSettingsUseCase(repo);
    });

final savePrayerSettingsUseCaseProvider =
    FutureProvider<SavePrayerSettingsUseCase>((ref) async {
      final repo = await ref.watch(prayerSettingsRepositoryProvider.future);
      return SavePrayerSettingsUseCase(repo);
    });

final deriveDefaultMethodFromCountryUseCaseProvider =
    Provider<DeriveDefaultMethodFromCountryUseCase>((ref) {
      return const DeriveDefaultMethodFromCountryUseCase();
    });

/// Source d'horloge injectable — l'override permet aux tests de figer
/// `DateTime.now().toUtc()` pour vérifier le calcul du jour civil.
final clockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});
