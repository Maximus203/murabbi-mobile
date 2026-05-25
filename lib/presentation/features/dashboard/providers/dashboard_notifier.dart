import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/repositories/daily_summary_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_suggestion_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_display_item.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/resolve_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_daily_completion_rate_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/next_prayer.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_providers.dart';

/// Agrégateur de l'écran HM-01 — slices 3.A + 5.F.
///
/// Charge en parallèle :
/// - Les horaires de prière du jour (calcul prochaine prière)
/// - Le score hebdomadaire de l'utilisateur (niveau, points, rang)
///
/// Le streak global est calculé via [ComputeGlobalStreakUseCase] (réservé V2
/// quand l'historique complet est disponible en temps réel) — en 5.F on
/// expose le `currentStreak` stocké directement dans le profil utilisateur.
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    final clock = ref.read(dashboardClockProvider);
    final now = clock();
    final civilDay = DateTime.utc(now.year, now.month, now.day);
    final user = ref.read(currentUserProvider);

    // Charge en parallèle : horaires, score, taux journalier, niyyah.
    final prayerFuture = _loadPrayer(civilDay, now);
    final scoreFuture = _loadScore(user?.id);
    final completionFuture = _loadDailyCompletion(user?.id);
    final niyyahFuture = _loadNiyyah(user?.id, now);

    final results = await Future.wait([
      prayerFuture,
      scoreFuture,
      completionFuture,
      niyyahFuture,
    ]);

    final prayerState = results[0] as _PrayerResult;
    final score = results[1] as UserScore?;
    final completionRate = results[2] as double;
    final niyyah = results[3] as NiyyahDisplayItem?;

    return DashboardState(
      nowUtc: now,
      nextPrayer: prayerState.nextPrayer,
      settingsNotConfigured: prayerState.settingsNotConfigured,
      userScore: score,
      globalStreak: user?.currentStreak ?? 0,
      dailyCompletionRate: completionRate,
      niyyahToday: niyyah,
    );
  }

  Future<_PrayerResult> _loadPrayer(DateTime civilDay, DateTime now) async {
    try {
      final getPrayerTimes = await ref.read(
        getPrayerTimesUseCaseProvider.future,
      );
      final times = await getPrayerTimes(day: civilDay);
      return _PrayerResult(
        nextPrayer: NextPrayer.from(times: times, now: now),
        settingsNotConfigured: false,
      );
    } on PrayerSettingsNotConfiguredFailure {
      return const _PrayerResult(nextPrayer: null, settingsNotConfigured: true);
    }
  }

  Future<UserScore?> _loadScore(UserId? userId) async {
    if (userId == null) return null;
    try {
      return await ref.read(scoreRepositoryProvider).getUserScore(userId);
    } catch (e, st) {
      appLog.w('DashboardNotifier: score non disponible', error: e, stackTrace: st);
      return null;
    }
  }

  Future<double> _loadDailyCompletion(UserId? userId) async {
    if (userId == null) return 0.0;
    try {
      final repo = ref.read(dailySummaryRepositoryProvider);
      return await ComputeDailyCompletionRateUseCase(repo)(userId.value);
    } catch (e, st) {
      appLog.w('DashboardNotifier: completion rate non disponible', error: e, stackTrace: st);
      return 0.0;
    }
  }

  Future<NiyyahDisplayItem?> _loadNiyyah(UserId? userId, DateTime now) async {
    if (userId == null) return null;
    try {
      final niyyahRepo = ref.read(niyyahRepositoryProvider);
      final suggestionRepo = ref.read(niyyahSuggestionRepositoryProvider);
      return await ResolveTodayNiyyahUseCase(
        niyyahRepository: niyyahRepo,
        suggestionRepository: suggestionRepo,
      )(userId, referenceDate: now);
    } catch (e, st) {
      appLog.w('DashboardNotifier: niyyah non disponible', error: e, stackTrace: st);
      return null;
    }
  }
}

/// Résultat intermédiaire du chargement des horaires de prière.
class _PrayerResult {
  final NextPrayer? nextPrayer;
  final bool settingsNotConfigured;

  const _PrayerResult({
    required this.nextPrayer,
    required this.settingsNotConfigured,
  });
}

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
    );
