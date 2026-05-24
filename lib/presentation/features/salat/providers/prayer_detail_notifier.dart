import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/extensions/ref_score_invalidation.dart';
import 'package:murabbi_mobile/data/repositories/prayer_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_history_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';

/// État du détail d'une prière sur 7 jours glissants (SL-DETAIL — issue #50).
class PrayerDetailState extends Equatable {
  /// Nom canonique de la prière (`fajr` / `dhuhr` / `asr` / `maghrib` / `isha`).
  final String prayerName;

  /// 7 derniers jours dans l'ordre chronologique (le plus ancien en
  /// premier, aujourd'hui en dernier). Les `PrayerDay` exposent tous les
  /// statuts du jour — l'UI projette uniquement [prayerName].
  final List<PrayerDay> weekDays;

  const PrayerDetailState({required this.prayerName, required this.weekDays});

  /// Projection : statut de [prayerName] pour chaque jour de la semaine.
  List<PrayerStatus> get weekStatuses {
    return weekDays.map((day) {
      switch (prayerName) {
        case 'fajr':
          return day.fajr;
        case 'dhuhr':
          return day.dhuhr;
        case 'asr':
          return day.asr;
        case 'maghrib':
          return day.maghrib;
        case 'isha':
          return day.isha;
      }
      return PrayerStatus.pending;
    }).toList();
  }

  @override
  List<Object?> get props => [prayerName, weekDays];
}

/// Provider du `GetPrayerHistoryUseCase` (manquait dans
/// `salat_use_case_providers.dart` — slice SL-DETAIL).
final getPrayerHistoryUseCaseProvider = Provider<GetPrayerHistoryUseCase>((
  ref,
) {
  return GetPrayerHistoryUseCase(ref.watch(prayerRepositoryProvider));
});

/// Charge l'historique 7 jours pour une prière donnée. Family `String`
/// = nom de la prière. Recharge sur navigation différente prière.
final prayerDetailNotifierProvider =
    AsyncNotifierProvider.family<
      PrayerDetailNotifier,
      PrayerDetailState,
      String
    >(PrayerDetailNotifier.new);

class PrayerDetailNotifier
    extends FamilyAsyncNotifier<PrayerDetailState, String> {
  @override
  Future<PrayerDetailState> build(String prayerName) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      throw StateError('PrayerDetailNotifier requires an authenticated user');
    }
    final now = ref.read(clockProvider)();
    final today = DateTime.utc(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 6));
    final useCase = ref.read(getPrayerHistoryUseCaseProvider);
    final days = await useCase(userId: user.id, from: from, to: today);
    // Garantit 7 entrées : si l'historique manque un jour, on injecte une
    // entrée `pending` (cas premier login / jours non loggués).
    final normalized = _padToSevenDays(days, from: from, userId: user.id);
    return PrayerDetailState(prayerName: prayerName, weekDays: normalized);
  }

  static List<PrayerDay> _padToSevenDays(
    List<PrayerDay> days, {
    required DateTime from,
    required UserId userId,
  }) {
    final byDate = {for (final d in days) _civilKey(d.date): d};
    final out = <PrayerDay>[];
    for (var i = 0; i < 7; i++) {
      final date = DateTime.utc(from.year, from.month, from.day + i);
      out.add(
        byDate[_civilKey(date)] ??
            PrayerDay(
              userId: userId,
              date: date,
              fajr: PrayerStatus.pending,
              dhuhr: PrayerStatus.pending,
              asr: PrayerStatus.pending,
              maghrib: PrayerStatus.pending,
              isha: PrayerStatus.pending,
            ),
      );
    }
    return out;
  }

  static String _civilKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Met à jour le statut d'un jour précis avec mise à jour optimiste (D-29).
  ///
  /// 1. Applique immédiatement le changement en local (pas de spinner).
  /// 2. Persiste via [MarkPrayerUseCase] en background.
  /// 3. Si l'écriture échoue, rollback vers l'état précédent.
  Future<void> markDay({
    required DateTime dayUtc,
    required PrayerStatus status,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // 1. Mise à jour optimiste — l'UI répond immédiatement.
    final optimistic = _updateLocalState(current, dayUtc, status);
    state = AsyncValue.data(optimistic);

    // 2. Persistence en background.
    try {
      final markUseCase = ref.read(markPrayerUseCaseProvider);
      await markUseCase(
        userId: user.id,
        date: dayUtc,
        prayerName: current.prayerName,
        status: status,
      );
      // Issue #196 (M6) : invalide le score dashboard après log de prière.
      ref.invalidateScoreCache();
    } catch (_) {
      // 3. Rollback si erreur réseau / serveur.
      state = AsyncValue.data(current);
    }
  }

  /// Applique le changement de [status] pour [dayUtc] localement, sans I/O.
  PrayerDetailState _updateLocalState(
    PrayerDetailState current,
    DateTime dayUtc,
    PrayerStatus status,
  ) {
    final key = _civilKey(dayUtc);
    final updatedDays = current.weekDays.map((day) {
      if (_civilKey(day.date) != key) return day;
      return _applyStatus(day, current.prayerName, status);
    }).toList();
    return PrayerDetailState(
      prayerName: current.prayerName,
      weekDays: updatedDays,
    );
  }

  /// Retourne un [PrayerDay] avec le statut [status] appliqué à [prayerName].
  static PrayerDay _applyStatus(
    PrayerDay day,
    String prayerName,
    PrayerStatus status,
  ) {
    switch (prayerName) {
      case 'fajr':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: status,
          dhuhr: day.dhuhr,
          asr: day.asr,
          maghrib: day.maghrib,
          isha: day.isha,
        );
      case 'dhuhr':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: status,
          asr: day.asr,
          maghrib: day.maghrib,
          isha: day.isha,
        );
      case 'asr':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: day.dhuhr,
          asr: status,
          maghrib: day.maghrib,
          isha: day.isha,
        );
      case 'maghrib':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: day.dhuhr,
          asr: day.asr,
          maghrib: status,
          isha: day.isha,
        );
      case 'isha':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: day.dhuhr,
          asr: day.asr,
          maghrib: day.maghrib,
          isha: status,
        );
      default:
        return day;
    }
  }
}
