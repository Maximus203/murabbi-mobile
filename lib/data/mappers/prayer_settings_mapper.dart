import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

/// Mapper pur — convertit un blob JSON persisté (clé / valeur) en
/// [PrayerSettings] et inversement. Source de vérité pour les noms de
/// méthode / madhab / high-latitude rule sur le wire.
///
/// Toute valeur inconnue dans le JSON entrant lève une [ArgumentError]
/// plutôt que de retomber silencieusement sur un défaut — le défaut métier
/// est de la responsabilité du repository (qui retourne `null` puis le use
/// case applique le fallback intelligent par pays).
class PrayerSettingsMapper {
  const PrayerSettingsMapper._();

  static PrayerSettings fromJson(Map<String, dynamic> json) {
    final method = _methodFromString(json['method']);
    final madhab = _madhabFromString(json['madhab']);
    final lat = _asDouble(json['latitude'], 'latitude');
    final lng = _asDouble(json['longitude'], 'longitude');
    final rule = json.containsKey('highLatitudeRule')
        ? _ruleFromString(json['highLatitudeRule'])
        : HighLatitudeRule.middleOfTheNight;

    return PrayerSettings(
      method: method,
      madhab: madhab,
      latitude: lat,
      longitude: lng,
      highLatitudeRule: rule,
    );
  }

  static Map<String, dynamic> toJson(PrayerSettings s) {
    return {
      'method': _methodToString(s.method),
      'madhab': _madhabToString(s.madhab),
      'latitude': s.latitude,
      'longitude': s.longitude,
      'highLatitudeRule': _ruleToString(s.highLatitudeRule),
    };
  }

  // -- CalculationMethod -----------------------------------------------------

  static CalculationMethod _methodFromString(Object? raw) {
    if (raw is! String) {
      throw ArgumentError.value(raw, 'method', 'must be a non-null String');
    }
    switch (raw) {
      case 'muslim_world_league':
        return CalculationMethod.muslimWorldLeague;
      case 'isna':
        return CalculationMethod.isna;
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.ummAlQura;
      case 'diyanet':
        return CalculationMethod.diyanet;
      case 'tehran':
        return CalculationMethod.tehran;
      case 'moonsighting':
        return CalculationMethod.moonsighting;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'uoif':
        return CalculationMethod.uoif;
      case 'morocco':
        return CalculationMethod.morocco;
      case 'algeria':
        return CalculationMethod.algeria;
      case 'tunisia':
        return CalculationMethod.tunisia;
    }
    throw ArgumentError.value(raw, 'method', 'unknown calculation method');
  }

  static String _methodToString(CalculationMethod m) {
    switch (m) {
      case CalculationMethod.muslimWorldLeague:
        return 'muslim_world_league';
      case CalculationMethod.isna:
        return 'isna';
      case CalculationMethod.egyptian:
        return 'egyptian';
      case CalculationMethod.karachi:
        return 'karachi';
      case CalculationMethod.ummAlQura:
        return 'umm_al_qura';
      case CalculationMethod.diyanet:
        return 'diyanet';
      case CalculationMethod.tehran:
        return 'tehran';
      case CalculationMethod.moonsighting:
        return 'moonsighting';
      case CalculationMethod.singapore:
        return 'singapore';
      case CalculationMethod.dubai:
        return 'dubai';
      case CalculationMethod.qatar:
        return 'qatar';
      case CalculationMethod.kuwait:
        return 'kuwait';
      case CalculationMethod.uoif:
        return 'uoif';
      case CalculationMethod.morocco:
        return 'morocco';
      case CalculationMethod.algeria:
        return 'algeria';
      case CalculationMethod.tunisia:
        return 'tunisia';
    }
  }

  // -- Madhab ----------------------------------------------------------------

  static Madhab _madhabFromString(Object? raw) {
    if (raw is! String) {
      throw ArgumentError.value(raw, 'madhab', 'must be a non-null String');
    }
    switch (raw) {
      case 'shafi':
        return Madhab.shafi;
      case 'hanafi':
        return Madhab.hanafi;
    }
    throw ArgumentError.value(raw, 'madhab', 'unknown madhab');
  }

  static String _madhabToString(Madhab m) {
    switch (m) {
      case Madhab.shafi:
        return 'shafi';
      case Madhab.hanafi:
        return 'hanafi';
    }
  }

  // -- HighLatitudeRule ------------------------------------------------------

  static HighLatitudeRule _ruleFromString(Object? raw) {
    if (raw is! String) {
      throw ArgumentError.value(
        raw,
        'highLatitudeRule',
        'must be a non-null String',
      );
    }
    switch (raw) {
      case 'middle_of_the_night':
        return HighLatitudeRule.middleOfTheNight;
      case 'seventh_of_the_night':
        return HighLatitudeRule.seventhOfTheNight;
      case 'twilight_angle':
        return HighLatitudeRule.twilightAngle;
    }
    throw ArgumentError.value(
      raw,
      'highLatitudeRule',
      'unknown high latitude rule',
    );
  }

  static String _ruleToString(HighLatitudeRule r) {
    switch (r) {
      case HighLatitudeRule.middleOfTheNight:
        return 'middle_of_the_night';
      case HighLatitudeRule.seventhOfTheNight:
        return 'seventh_of_the_night';
      case HighLatitudeRule.twilightAngle:
        return 'twilight_angle';
    }
  }

  // -- Helpers ---------------------------------------------------------------

  static double _asDouble(Object? raw, String field) {
    if (raw is num) return raw.toDouble();
    throw ArgumentError.value(raw, field, 'must be a number');
  }
}
