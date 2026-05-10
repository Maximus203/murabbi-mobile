// SEUL fichier autorisé à importer `package:adhan_dart/...` dans tout le code
// Murabbi mobile (cf. ADR-013 §Architecture, règle d'isolation). Si une autre
// couche a besoin d'horaires de prière, elle passe par cette interface — pas
// d'exception.
import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

/// Calcule les horaires de prière pour un jour donné selon les
/// [PrayerSettings] de l'utilisateur (cf. ADR-013 slice 3.C.2).
///
/// **Convention de fuseau** : le [PrayerTimes] retourné contient des
/// [DateTime] en UTC. La conversion vers le fuseau local est réalisée
/// par la couche presentation (slice 3.C.3) via `.toLocal()`.
abstract interface class PrayerTimesService {
  /// Calcule les six horaires (fajr, sunrise, dhuhr, asr, maghrib, isha)
  /// pour [day] aux coordonnées et selon la méthode définies dans [settings].
  ///
  /// La date civile [day] est interprétée en UTC (la lib adhan calcule en
  /// UTC puis on convertit). Pour un jour civil dans le fuseau de
  /// l'utilisateur, le caller doit construire `DateTime.utc(y, m, d)`
  /// correspondant à la journée locale visée — pour la grande majorité
  /// des fuseaux, cela donne le même résultat astronomique à la
  /// minute près.
  PrayerTimes computeForDay({
    required PrayerSettings settings,
    required DateTime day,
  });
}

/// Implémentation production basée sur `adhan_dart` v2.0.0 (port MIT direct
/// de `adhan-js`, cf. ADR-013 §Décision §1).
class AdhanPrayerTimesService implements PrayerTimesService {
  const AdhanPrayerTimesService();

  @override
  PrayerTimes computeForDay({
    required PrayerSettings settings,
    required DateTime day,
  }) {
    final coords = adhan.Coordinates(settings.latitude, settings.longitude);
    final params = _paramsFor(settings);

    final at = adhan.PrayerTimes(
      date: DateTime.utc(day.year, day.month, day.day),
      coordinates: coords,
      calculationParameters: params,
    );

    return PrayerTimes(
      fajr: at.fajr.toUtc(),
      sunrise: at.sunrise.toUtc(),
      dhuhr: at.dhuhr.toUtc(),
      asr: at.asr.toUtc(),
      maghrib: at.maghrib.toUtc(),
      isha: at.isha.toUtc(),
    );
  }

  /// Construit les `CalculationParameters` adhan_dart à partir des settings
  /// domain Murabbi. Toutes les méthodes du VO [CalculationMethod] sont
  /// natives `adhan_dart` 2.0.0 — pas de fallback "Other" en V1
  /// (cf. ADR-013 §Limites).
  adhan.CalculationParameters _paramsFor(PrayerSettings settings) {
    final params = switch (settings.method) {
      CalculationMethod.muslimWorldLeague =>
        adhan.CalculationMethodParameters.muslimWorldLeague(),
      CalculationMethod.isna =>
        adhan.CalculationMethodParameters.northAmerica(),
      CalculationMethod.egyptian =>
        adhan.CalculationMethodParameters.egyptian(),
      CalculationMethod.karachi => adhan.CalculationMethodParameters.karachi(),
      CalculationMethod.ummAlQura =>
        adhan.CalculationMethodParameters.ummAlQura(),
      CalculationMethod.diyanet => adhan.CalculationMethodParameters.turkiye(),
      CalculationMethod.tehran => adhan.CalculationMethodParameters.tehran(),
      CalculationMethod.moonsighting =>
        adhan.CalculationMethodParameters.moonsightingCommittee(),
      CalculationMethod.singapore =>
        adhan.CalculationMethodParameters.singapore(),
      CalculationMethod.dubai => adhan.CalculationMethodParameters.dubai(),
      CalculationMethod.qatar => adhan.CalculationMethodParameters.qatar(),
      CalculationMethod.kuwait => adhan.CalculationMethodParameters.kuwait(),
      CalculationMethod.uoif => adhan.CalculationMethodParameters.france(),
      CalculationMethod.morocco => adhan.CalculationMethodParameters.morocco(),
      CalculationMethod.algeria => adhan.CalculationMethodParameters.algerian(),
      CalculationMethod.tunisia => adhan.CalculationMethodParameters.tunisia(),
    };

    params
      ..madhab = _madhab(settings.madhab)
      ..highLatitudeRule = _highLatRule(settings.highLatitudeRule);

    return params;
  }

  adhan.Madhab _madhab(Madhab m) => switch (m) {
    Madhab.shafi => adhan.Madhab.shafi,
    Madhab.hanafi => adhan.Madhab.hanafi,
  };

  adhan.HighLatitudeRule _highLatRule(HighLatitudeRule r) => switch (r) {
    HighLatitudeRule.middleOfTheNight =>
      adhan.HighLatitudeRule.middleOfTheNight,
    HighLatitudeRule.seventhOfTheNight =>
      adhan.HighLatitudeRule.seventhOfTheNight,
    HighLatitudeRule.twilightAngle => adhan.HighLatitudeRule.twilightAngle,
  };
}
