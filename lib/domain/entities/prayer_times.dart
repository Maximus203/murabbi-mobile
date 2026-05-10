import 'package:equatable/equatable.dart';

/// Horaires des cinq prières quotidiennes plus le lever du soleil pour une
/// journée donnée (cf. ADR-013 slice 3.C.2).
///
/// **Convention** : les six [DateTime] sont en **UTC**. La conversion vers le
/// fuseau local est de la responsabilité de la couche presentation. Travailler
/// en UTC en interne évite toute ambiguïté autour du DST (cf. ADR-013
/// §Limites — Changement d'heure été/hiver).
///
/// Invariant : les six timestamps doivent être strictement croissants dans
/// l'ordre `fajr < sunrise < dhuhr < asr < maghrib < isha`. Le constructeur
/// rejette toute violation par [ArgumentError] — protège contre une dérive
/// accidentelle de la lib `adhan_dart` (slice 3.C.2) ou un mauvais mock.
class PrayerTimes extends Equatable {
  /// Aube — l'heure de la prière du Fajr.
  final DateTime fajr;

  /// Lever du soleil — fin de la fenêtre Fajr (n'est pas une prière, mais
  /// utile pour qualifier le statut `late` dans le tracker slice 3.B).
  final DateTime sunrise;

  /// Midi solaire — l'heure de la prière du Dhuhr.
  final DateTime dhuhr;

  /// Après-midi — l'heure de la prière du Asr (différe entre madhabs Shafi
  /// et Hanafi, cf. ADR-013 §3).
  final DateTime asr;

  /// Coucher du soleil — l'heure de la prière du Maghrib.
  final DateTime maghrib;

  /// Soir — l'heure de la prière du Isha.
  final DateTime isha;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  }) {
    final ordered = [fajr, sunrise, dhuhr, asr, maghrib, isha];
    for (var i = 1; i < ordered.length; i++) {
      if (!ordered[i].isAfter(ordered[i - 1])) {
        throw ArgumentError(
          'PrayerTimes timestamps must be strictly increasing '
          '(fajr < sunrise < dhuhr < asr < maghrib < isha). '
          'Got fajr=$fajr, sunrise=$sunrise, dhuhr=$dhuhr, asr=$asr, '
          'maghrib=$maghrib, isha=$isha.',
        );
      }
    }
  }

  /// Copie immutable.
  PrayerTimes copyWith({
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
  }) {
    return PrayerTimes(
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  @override
  List<Object?> get props => [fajr, sunrise, dhuhr, asr, maghrib, isha];
}
