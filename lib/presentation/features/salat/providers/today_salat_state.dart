import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';

/// État de l'écran SA-01 "Aujourd'hui" (slice 3.C.3).
///
/// Snapshot immutable agrégeant le jour civil UTC, les statuts des cinq
/// prières (`PrayerDay`) et leurs horaires calculés (`PrayerTimes`).
class TodaySalatState extends Equatable {
  /// Jour civil UTC affiché (00:00 UTC).
  final DateTime date;

  /// Statuts des cinq prières pour [date].
  final PrayerDay prayerDay;

  /// Horaires calculés des prières pour [date] (UTC — conversion locale
  /// déléguée à la couche présentation).
  final PrayerTimes prayerTimes;

  const TodaySalatState({
    required this.date,
    required this.prayerDay,
    required this.prayerTimes,
  });

  TodaySalatState copyWith({
    DateTime? date,
    PrayerDay? prayerDay,
    PrayerTimes? prayerTimes,
  }) {
    return TodaySalatState(
      date: date ?? this.date,
      prayerDay: prayerDay ?? this.prayerDay,
      prayerTimes: prayerTimes ?? this.prayerTimes,
    );
  }

  @override
  List<Object?> get props => [date, prayerDay, prayerTimes];
}
