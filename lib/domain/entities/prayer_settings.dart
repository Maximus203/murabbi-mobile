import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

/// Paramètres de calcul des horaires de prière persistés côté utilisateur.
///
/// Cf. ADR-013 — slice 3.C.1. V1 : persistance locale via SharedPreferences,
/// pas de sync Supabase (V1.5).
///
/// Les coordonnées sont stockées en degrés décimaux. La règle haute latitude
/// est conservée en V1 même si l'utilisateur n'est pas concerné — simplifie
/// le mapping vers `adhan_dart` en slice 3.C.2 (toujours une valeur).
class PrayerSettings extends Equatable {
  /// Méthode de calcul (par défaut MWL si pays inconnu — cf. ADR-013 §2.1).
  final CalculationMethod method;

  /// École juridique pour Asr (par défaut Shafi — cf. ADR-013 §3).
  final Madhab madhab;

  /// Latitude en degrés décimaux ([-90, 90]).
  final double latitude;

  /// Longitude en degrés décimaux ([-180, 180]).
  final double longitude;

  /// Stratégie hautes latitudes (défaut [HighLatitudeRule.middleOfTheNight]
  /// — neutre tant que la lat n'excède pas ~48°).
  final HighLatitudeRule highLatitudeRule;

  PrayerSettings({
    required this.method,
    required this.madhab,
    required this.latitude,
    required this.longitude,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'must be in [-90, 90] degrees',
      );
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be in [-180, 180] degrees',
      );
    }
  }

  /// Copie immutable — usage type-safe pour les use cases d'update.
  PrayerSettings copyWith({
    CalculationMethod? method,
    Madhab? madhab,
    double? latitude,
    double? longitude,
    HighLatitudeRule? highLatitudeRule,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    );
  }

  @override
  List<Object?> get props => [
    method,
    madhab,
    latitude,
    longitude,
    highLatitudeRule,
  ];
}
