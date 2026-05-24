import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/extensions/ref_score_invalidation.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_state.dart';

/// Notifier de l'écran SA-01 "Aujourd'hui" (slice 3.C.3).
///
/// `AsyncValue<TodaySalatState>` :
/// - `data(state)` → cinq prières + horaires UTC chargés
/// - `loading()` → bootstrap ou refresh post-`markPrayer`
/// - `error(PrayerFailure.settingsNotConfigured)` → l'UI doit rediriger vers SA-02
/// - `error(...)` → autre erreur réseau / database
class TodaySalatNotifier extends AsyncNotifier<TodaySalatState> {
  @override
  Future<TodaySalatState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      throw StateError(
        'TodaySalatNotifier requires an authenticated user '
        '(currentUserProvider returned null)',
      );
    }
    final getTodayPrayers = ref.read(getTodayPrayersUseCaseProvider);
    final getPrayerTimes = await ref.read(getPrayerTimesUseCaseProvider.future);
    final now = ref.read(clockProvider)();
    final civilDay = DateTime.utc(now.year, now.month, now.day);

    final results = await Future.wait<Object>([
      getTodayPrayers(user.id),
      getPrayerTimes(day: civilDay),
    ]);

    return TodaySalatState(
      date: civilDay,
      prayerDay: results[0] as PrayerDay,
      prayerTimes: results[1] as PrayerTimes,
    );
  }

  /// Met à jour le statut d'une prière puis recharge le `PrayerDay`.
  ///
  /// Ne recalcule pas `PrayerTimes` — ces horaires ne dépendent que des
  /// `PrayerSettings` et du jour civil, jamais des logs.
  Future<void> markPrayer({
    required String prayerName,
    required PrayerStatus status,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final markUseCase = ref.read(markPrayerUseCaseProvider);
    final getTodayPrayers = ref.read(getTodayPrayersUseCaseProvider);

    state = const AsyncValue<TodaySalatState>.loading();
    state = await AsyncValue.guard(() async {
      await markUseCase(
        userId: user.id,
        date: current.date,
        prayerName: prayerName,
        status: status,
      );
      final fresh = await getTodayPrayers(user.id);
      return current.copyWith(prayerDay: fresh);
    });
    // Issue #196 (M6) : invalide le score dashboard après log de prière.
    if (state.hasValue) {
      ref.invalidateScoreCache();
    }
  }
}

final todaySalatNotifierProvider =
    AsyncNotifierProvider<TodaySalatNotifier, TodaySalatState>(
      TodaySalatNotifier.new,
    );
