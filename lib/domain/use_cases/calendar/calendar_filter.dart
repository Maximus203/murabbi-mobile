import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/compute_day_color_use_case.dart';

/// Onglet de filtre de CAL-01 (issue #7).
enum CalendarFilter {
  /// Prières + habitudes confondues.
  all,

  /// Prières uniquement.
  salat,

  /// Habitudes uniquement.
  habits,
}

/// Calcule la couleur d'une cellule jour CAL-01 en tenant compte du filtre
/// actif : `salat` ignore les habitudes, `habits` ignore les prières, `all`
/// agrège les deux.
///
/// Pure function — délègue à [ComputeDayColorUseCase] avec les listes
/// filtrées.
DayColor dayColorForFilter({
  required CalendarFilter filter,
  required List<PrayerStatus> prayerStatuses,
  required List<HabitLogStatus> habitStatuses,
  ComputeDayColorUseCase compute = const ComputeDayColorUseCase(),
}) {
  switch (filter) {
    case CalendarFilter.all:
      return compute(
        prayerStatuses: prayerStatuses,
        habitStatuses: habitStatuses,
      );
    case CalendarFilter.salat:
      return compute(prayerStatuses: prayerStatuses, habitStatuses: const []);
    case CalendarFilter.habits:
      return compute(prayerStatuses: const [], habitStatuses: habitStatuses);
  }
}
