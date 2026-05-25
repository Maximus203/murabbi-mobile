import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';

/// Sévérité d'un jour pour la cellule CAL-01 (Q-08-cal verrouillé).
///
/// Ordre croissant de gravité : `success < late < missed`. La cellule prend
/// la couleur du **pire statut** rencontré sur l'ensemble des prières +
/// habitudes du jour, et l'opacité reflète le **% de complétion globale**.
enum DayStatusSeverity { empty, success, late, missed }

class DayColor extends Equatable {
  final DayStatusSeverity worst;

  /// % d'événements considérés validés ([0..1]).
  /// Validés = `onTime`/`late`/`makeup` côté prière, `onTime`/`late` côté habitude.
  /// `pending` et `missed` ne comptent pas comme validés.
  final double fillPercent;

  const DayColor({required this.worst, required this.fillPercent});

  @override
  List<Object?> get props => [worst, fillPercent];
}

/// Calcule la couleur (sévérité + opacité) d'une cellule jour de CAL-01.
///
/// Q-08-cal — verrouillée 2026-05-03 (`product_decisions_v1.md`).
class ComputeDayColorUseCase {
  const ComputeDayColorUseCase();

  DayColor call({
    required List<PrayerStatus> prayerStatuses,
    required List<HabitLogStatus> habitStatuses,
  }) {
    final total = prayerStatuses.length + habitStatuses.length;
    if (total == 0) {
      return const DayColor(worst: DayStatusSeverity.empty, fillPercent: 0);
    }

    var worst = DayStatusSeverity.success;
    var validated = 0;

    for (final p in prayerStatuses) {
      switch (p) {
        case PrayerStatus.onTime:
        case PrayerStatus.late:
        case PrayerStatus.makeup:
          validated++;
          if (p == PrayerStatus.late) {
            worst = _worse(worst, DayStatusSeverity.late);
          }
          break;
        case PrayerStatus.missed:
          worst = _worse(worst, DayStatusSeverity.missed);
          break;
        case PrayerStatus.pending:
          // ni validé, ni « pire » — neutre
          break;
      }
    }

    for (final h in habitStatuses) {
      switch (h) {
        case HabitLogStatus.onTime:
          validated++;
          break;
        case HabitLogStatus.late:
          validated++;
          worst = _worse(worst, DayStatusSeverity.late);
          break;
        case HabitLogStatus.missed:
          worst = _worse(worst, DayStatusSeverity.missed);
          break;
      }
    }

    return DayColor(worst: worst, fillPercent: validated / total);
  }

  DayStatusSeverity _worse(DayStatusSeverity a, DayStatusSeverity b) {
    return a.index >= b.index ? a : b;
  }
}
