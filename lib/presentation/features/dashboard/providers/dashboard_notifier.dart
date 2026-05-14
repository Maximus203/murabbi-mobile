import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/prayer_times_provider.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/next_prayer.dart';

/// Agrégateur de l'écran HM-01 — slice 3.A.
///
/// Charge les horaires de prière du jour et calcule la prochaine prière.
/// Les autres sections du dashboard (habitudes, niyyah, streak) sont des
/// placeholders en V1 — leurs data layers (slices 3.D / 3.E / scoring)
/// arrivent dans les prochaines slices Phase 3.
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final clock = ref.read(dashboardClockProvider);
    final now = clock();
    final civilDay = DateTime.utc(now.year, now.month, now.day);

    try {
      final getPrayerTimes = await ref.read(
        getPrayerTimesUseCaseProvider.future,
      );
      final times = await getPrayerTimes(day: civilDay);
      return DashboardState(
        nowUtc: now,
        nextPrayer: NextPrayer.from(times: times, now: now),
        settingsNotConfigured: false,
      );
    } on PrayerSettingsNotConfiguredFailure {
      // L'utilisateur n'a pas encore configuré ses prières → on bascule
      // le Dashboard sur l'état "configurer" (CTA visible) au lieu de
      // crasher l'écran.
      return DashboardState(
        nowUtc: now,
        nextPrayer: null,
        settingsNotConfigured: true,
      );
    }
  }
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
    );
