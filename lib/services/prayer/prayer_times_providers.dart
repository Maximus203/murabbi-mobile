import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/prayer_settings_providers.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_times_use_case.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

/// Provider du [PrayerTimesService] — constant, sans état mutable (ADR-013).
final prayerTimesServiceProvider = Provider<PrayerTimesService>((ref) {
  return const AdhanPrayerTimesService();
});

/// Provider du [GetPrayerTimesUseCase] — entry point unique pour la couche
/// presentation (slice 3.C.3).
final getPrayerTimesUseCaseProvider = FutureProvider<GetPrayerTimesUseCase>((
  ref,
) async {
  final repo = await ref.watch(prayerSettingsRepositoryProvider.future);
  return GetPrayerTimesUseCase(
    service: ref.watch(prayerTimesServiceProvider),
    repository: repo,
  );
});
