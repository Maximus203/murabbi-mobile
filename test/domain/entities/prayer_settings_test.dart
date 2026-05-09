import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

void main() {
  PrayerSettings sample({
    CalculationMethod method = CalculationMethod.uoif,
    Madhab madhab = Madhab.shafi,
    double latitude = 48.8566,
    double longitude = 2.3522,
    HighLatitudeRule rule = HighLatitudeRule.middleOfTheNight,
  }) => PrayerSettings(
    method: method,
    madhab: madhab,
    latitude: latitude,
    longitude: longitude,
    highLatitudeRule: rule,
  );

  group('PrayerSettings — construction', () {
    test('keeps the values it is given', () {
      final s = sample();
      expect(s.method, CalculationMethod.uoif);
      expect(s.madhab, Madhab.shafi);
      expect(s.latitude, 48.8566);
      expect(s.longitude, 2.3522);
      expect(s.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
    });

    test('defaults highLatitudeRule to middleOfTheNight', () {
      final s = PrayerSettings(
        method: CalculationMethod.muslimWorldLeague,
        madhab: Madhab.shafi,
        latitude: 0,
        longitude: 0,
      );
      expect(s.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
    });

    test('throws on out-of-range latitude (< -90)', () {
      expect(() => sample(latitude: -91), throwsArgumentError);
    });

    test('throws on out-of-range latitude (> 90)', () {
      expect(() => sample(latitude: 91), throwsArgumentError);
    });

    test('throws on out-of-range longitude (< -180)', () {
      expect(() => sample(longitude: -181), throwsArgumentError);
    });

    test('throws on out-of-range longitude (> 180)', () {
      expect(() => sample(longitude: 181), throwsArgumentError);
    });
  });

  group('PrayerSettings — copyWith', () {
    test('returns a new instance with the updated method only', () {
      final s = sample();
      final updated = s.copyWith(method: CalculationMethod.morocco);
      expect(updated.method, CalculationMethod.morocco);
      expect(updated.madhab, s.madhab);
      expect(updated.latitude, s.latitude);
      expect(updated.longitude, s.longitude);
      expect(updated.highLatitudeRule, s.highLatitudeRule);
    });

    test('updates several fields at once', () {
      final s = sample();
      final updated = s.copyWith(
        madhab: Madhab.hanafi,
        latitude: 33.5731,
        longitude: -7.5898,
      );
      expect(updated.madhab, Madhab.hanafi);
      expect(updated.latitude, 33.5731);
      expect(updated.longitude, -7.5898);
      expect(updated.method, s.method);
    });

    test('returning identical values produces an equal instance', () {
      final s = sample();
      expect(s.copyWith(), s);
    });
  });

  group('PrayerSettings — equality', () {
    test('two instances with the same values are equal', () {
      expect(sample(), sample());
    });

    test('different lat → not equal', () {
      expect(sample(latitude: 48.8), isNot(sample(latitude: 48.85)));
    });
  });
}
