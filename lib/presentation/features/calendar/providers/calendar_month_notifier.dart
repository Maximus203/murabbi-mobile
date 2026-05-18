import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/prayer_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Données agrégées d'un jour pour CAL-01 : statuts de prière et d'habitude.
class CalendarDayData {
  final List<PrayerStatus> prayerStatuses;
  final List<HabitLogStatus> habitStatuses;

  const CalendarDayData({
    this.prayerStatuses = const [],
    this.habitStatuses = const [],
  });
}

/// Mois actuellement visible (année + mois 1..12) — état de navigation
/// CAL-01. Indépendant du fetch des données pour que la navigation soit
/// instantanée.
class CalendarMonthCursor extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  /// Positionne le curseur sur un mois donné (normalisé au 1er jour).
  void goToMonth(int year, int month) {
    state = DateTime(year, month);
  }
}

final calendarMonthCursorProvider =
    NotifierProvider<CalendarMonthCursor, DateTime>(CalendarMonthCursor.new);

/// Données du mois visible, indexées par jour (clé = `DateTime` à minuit).
///
/// Agrège l'historique des prières (`getPrayerHistory`) et les logs de
/// toutes les habitudes de l'utilisateur sur le mois courant.
final calendarMonthDataProvider =
    FutureProvider<Map<DateTime, CalendarDayData>>((ref) async {
      final user = ref.watch(authNotifierProvider).valueOrNull;
      if (user == null) return {};

      final cursor = ref.watch(calendarMonthCursorProvider);
      final from = DateTime(cursor.year, cursor.month);
      final to = DateTime(cursor.year, cursor.month + 1, 0);

      final prayerRepo = ref.watch(prayerRepositoryProvider);
      final habitRepo = ref.watch(habitRepositoryProvider);

      final prayerDays = await prayerRepo.getPrayerHistory(
        userId: user.id,
        from: from,
        to: to,
      );

      final result = <DateTime, CalendarDayData>{};
      for (final pd in prayerDays) {
        final key = DateTime(pd.date.year, pd.date.month, pd.date.day);
        result[key] = CalendarDayData(
          prayerStatuses: [pd.fajr, pd.dhuhr, pd.asr, pd.maghrib, pd.isha],
        );
      }

      // Logs d'habitudes : agrégés par jour sur l'ensemble des habitudes.
      final habits = await habitRepo.getHabits(user.id);
      final habitStatusesByDay = <DateTime, List<HabitLogStatus>>{};
      for (final habit in habits) {
        final logs = await habitRepo.getLogsForHabit(
          habitId: habit.id,
          from: from,
          to: to,
        );
        for (final log in logs) {
          final key = DateTime(log.date.year, log.date.month, log.date.day);
          habitStatusesByDay.putIfAbsent(key, () => []).add(log.status);
        }
      }
      for (final entry in habitStatusesByDay.entries) {
        final existing = result[entry.key];
        result[entry.key] = CalendarDayData(
          prayerStatuses: existing?.prayerStatuses ?? const [],
          habitStatuses: entry.value,
        );
      }

      return result;
    });
