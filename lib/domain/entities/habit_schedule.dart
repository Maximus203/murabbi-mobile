import 'package:murabbi_mobile/domain/entities/habit.dart';

/// Logique de planification d'une habitude — détermine si une habitude est
/// « due » un jour donné.
///
/// Introduit pour corriger l'issue #145 : une habitude `daily` créée le jour
/// même doit apparaître dans la section « Habitudes du jour » du dashboard
/// (HM-01). La règle d'éligibilité est ici, isolée et testable, plutôt que
/// noyée dans le widget.
extension HabitSchedule on Habit {
  /// Retourne `true` si l'habitude doit être effectuée le [date] donné.
  ///
  /// - `daily` / `perDay` : due tous les jours.
  /// - `weekly` / `perWeek` : due si le `weekday` (1 = lundi … 7 = dimanche)
  ///   appartient à [activeDays].
  /// - `monthly` : due si le jour du mois correspond à `monthlyDay`.
  /// - `custom` : règle libre non modélisée en V1 — considérée due chaque jour
  ///   pour ne pas masquer l'habitude (cf. ADR-006, suite Phase 4).
  bool isDueOn(DateTime date) {
    switch (frequencyType) {
      case HabitFrequencyType.daily:
      case HabitFrequencyType.perDay:
      case HabitFrequencyType.custom:
        return true;
      case HabitFrequencyType.weekly:
      case HabitFrequencyType.perWeek:
        return activeDays.contains(date.weekday);
      case HabitFrequencyType.monthly:
        return monthlyDay == date.day;
    }
  }
}

/// Filtre une liste d'habitudes pour ne garder que celles dues le [date] donné.
///
/// Préserve l'ordre d'origine. Cf. issue #145.
List<Habit> habitsDueOn(List<Habit> habits, DateTime date) {
  return habits.where((h) => h.isDueOn(date)).toList();
}
