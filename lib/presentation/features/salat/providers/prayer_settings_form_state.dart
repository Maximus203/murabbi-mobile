import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

/// Erreurs typées exposées par le formulaire SA-02 (slice 3.C.3).
enum PrayerSettingsFormError {
  /// Latitude et/ou longitude n'ont pas été fournies (champs vides).
  missingCoordinates,

  /// Latitude hors des bornes [-90, 90].
  invalidLatitude,

  /// Longitude hors des bornes [-180, 180].
  invalidLongitude,

  /// La persistance a échoué côté repository (disque plein, encodage…).
  saveFailed,
}

/// État éditable du formulaire SA-02.
///
/// Distinguer cet état de [PrayerSettings] (entité domain) — ici lat/lng
/// sont nullables tant que l'utilisateur n'a pas saisi ses coordonnées.
class PrayerSettingsFormState extends Equatable {
  final CalculationMethod method;
  final Madhab madhab;
  final double? latitude;
  final double? longitude;
  final HighLatitudeRule highLatitudeRule;
  final bool isSaving;
  final PrayerSettingsFormError? error;

  const PrayerSettingsFormState({
    required this.method,
    required this.madhab,
    required this.latitude,
    required this.longitude,
    required this.highLatitudeRule,
    required this.isSaving,
    required this.error,
  });

  /// Défauts ADR-013 : MWL + Shafi + middleOfTheNight, coords vides.
  const PrayerSettingsFormState.initial()
    : method = CalculationMethod.muslimWorldLeague,
      madhab = Madhab.shafi,
      latitude = null,
      longitude = null,
      highLatitudeRule = HighLatitudeRule.middleOfTheNight,
      isSaving = false,
      error = null;

  /// Latitude et longitude présentes et dans les bornes acceptées par
  /// [PrayerSettings].
  bool get isValid {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

  /// Au-delà de ~48° de latitude (en valeur absolue), la règle hautes
  /// latitudes devient pertinente — ADR-013 §Limites.
  bool get needsHighLatitudeRule {
    final lat = latitude;
    return lat != null && lat.abs() > 48;
  }

  PrayerSettingsFormState copyWith({
    CalculationMethod? method,
    Madhab? madhab,
    double? latitude,
    double? longitude,
    HighLatitudeRule? highLatitudeRule,
    bool? isSaving,
    PrayerSettingsFormError? error,
    bool clearError = false,
    bool clearLatitude = false,
    bool clearLongitude = false,
  }) {
    return PrayerSettingsFormState(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    method,
    madhab,
    latitude,
    longitude,
    highLatitudeRule,
    isSaving,
    error,
  ];
}
