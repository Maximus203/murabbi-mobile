import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

/// Stub RED — slice 3.C.1.
class PrayerSettings extends Equatable {
  final CalculationMethod method;
  final Madhab madhab;
  final double latitude;
  final double longitude;
  final HighLatitudeRule highLatitudeRule;

  // ignore: prefer_const_constructors_in_immutables
  PrayerSettings({
    required this.method,
    required this.madhab,
    required this.latitude,
    required this.longitude,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
  });

  PrayerSettings copyWith({
    CalculationMethod? method,
    Madhab? madhab,
    double? latitude,
    double? longitude,
    HighLatitudeRule? highLatitudeRule,
  }) {
    throw UnimplementedError('PrayerSettings.copyWith — RED stub');
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
