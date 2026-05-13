import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';

/// Identifie la prochaine prière à venir aujourd'hui (ou Fajr du lendemain
/// si toutes sont passées). Pure function — testable sans Flutter.
class NextPrayer extends Equatable {
  final String name;
  final DateTime timeUtc;
  final bool isTomorrow;

  const NextPrayer({
    required this.name,
    required this.timeUtc,
    required this.isTomorrow,
  });

  /// Cherche la prochaine prière strictement après [now] (UTC).
  ///
  /// Si toutes les prières du jour sont passées, retourne `isTomorrow=true`
  /// avec le Fajr du lendemain calculé naïvement (timeUtc + 24h). Pour la
  /// vraie précision multi-jour il faudra recalculer les `PrayerTimes` du
  /// jour suivant — V2.
  static NextPrayer? from({required PrayerTimes times, required DateTime now}) {
    final candidates = <(String, DateTime)>[
      ('fajr', times.fajr),
      ('dhuhr', times.dhuhr),
      ('asr', times.asr),
      ('maghrib', times.maghrib),
      ('isha', times.isha),
    ];

    for (final (name, t) in candidates) {
      if (t.isAfter(now)) {
        return NextPrayer(name: name, timeUtc: t, isTomorrow: false);
      }
    }

    // Toutes passées — fallback Fajr+24h (approximation V1).
    return NextPrayer(
      name: 'fajr',
      timeUtc: times.fajr.add(const Duration(days: 1)),
      isTomorrow: true,
    );
  }

  @override
  List<Object?> get props => [name, timeUtc, isTomorrow];
}
