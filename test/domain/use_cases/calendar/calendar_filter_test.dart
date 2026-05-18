import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/calendar_filter.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/compute_day_color_use_case.dart';

void main() {
  // Prières : 4 onTime + 1 missed. Habitudes : 2 onTime.
  const prayers = [
    PrayerStatus.onTime,
    PrayerStatus.onTime,
    PrayerStatus.onTime,
    PrayerStatus.onTime,
    PrayerStatus.missed,
  ];
  const habits = [HabitLogStatus.onTime, HabitLogStatus.onTime];

  test('filtre "all" agrège prières + habitudes', () {
    final color = dayColorForFilter(
      filter: CalendarFilter.all,
      prayerStatuses: prayers,
      habitStatuses: habits,
    );
    // 6 validés / 7 total, pire = missed.
    expect(color.worst, DayStatusSeverity.missed);
    expect(color.fillPercent, closeTo(6 / 7, 0.001));
  });

  test('filtre "salat" ignore les habitudes', () {
    final color = dayColorForFilter(
      filter: CalendarFilter.salat,
      prayerStatuses: prayers,
      habitStatuses: habits,
    );
    // 4 validés / 5 prières.
    expect(color.fillPercent, closeTo(4 / 5, 0.001));
    expect(color.worst, DayStatusSeverity.missed);
  });

  test('filtre "habits" ignore les prières', () {
    final color = dayColorForFilter(
      filter: CalendarFilter.habits,
      prayerStatuses: prayers,
      habitStatuses: habits,
    );
    // 2 validés / 2 habitudes, aucun missed.
    expect(color.fillPercent, 1.0);
    expect(color.worst, DayStatusSeverity.success);
  });

  test('filtre "habits" sans habitude → cellule vide', () {
    final color = dayColorForFilter(
      filter: CalendarFilter.habits,
      prayerStatuses: prayers,
      habitStatuses: const [],
    );
    expect(color.worst, DayStatusSeverity.empty);
  });
}
