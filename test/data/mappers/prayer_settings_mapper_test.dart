import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/prayer_settings_mapper.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

void main() {
  group('PrayerSettingsMapper.toJson', () {
    test('serializes all 5 fields with snake_case method/madhab/rule', () {
      final s = PrayerSettings(
        method: CalculationMethod.uoif,
        madhab: Madhab.shafi,
        latitude: 48.8566,
        longitude: 2.3522,
        highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      );
      final json = PrayerSettingsMapper.toJson(s);
      expect(json['method'], 'uoif');
      expect(json['madhab'], 'shafi');
      expect(json['latitude'], 48.8566);
      expect(json['longitude'], 2.3522);
      expect(json['highLatitudeRule'], 'middle_of_the_night');
    });

    test('serializes Hanafi madhab', () {
      final s = PrayerSettings(
        method: CalculationMethod.karachi,
        madhab: Madhab.hanafi,
        latitude: 33.6844,
        longitude: 73.0479,
      );
      final json = PrayerSettingsMapper.toJson(s);
      expect(json['madhab'], 'hanafi');
      expect(json['method'], 'karachi');
    });

    test('serializes umm_al_qura snake-case', () {
      final s = PrayerSettings(
        method: CalculationMethod.ummAlQura,
        madhab: Madhab.shafi,
        latitude: 21.42,
        longitude: 39.82,
      );
      expect(PrayerSettingsMapper.toJson(s)['method'], 'umm_al_qura');
    });

    test('serializes muslim_world_league snake-case', () {
      final s = PrayerSettings(
        method: CalculationMethod.muslimWorldLeague,
        madhab: Madhab.shafi,
        latitude: 0,
        longitude: 0,
      );
      expect(PrayerSettingsMapper.toJson(s)['method'], 'muslim_world_league');
    });
  });

  group('PrayerSettingsMapper.fromJson', () {
    test('round-trip: toJson → fromJson preserves equality', () {
      final original = PrayerSettings(
        method: CalculationMethod.morocco,
        madhab: Madhab.shafi,
        latitude: 33.5731,
        longitude: -7.5898,
        highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
      );
      final back = PrayerSettingsMapper.fromJson(
        PrayerSettingsMapper.toJson(original),
      );
      expect(back, original);
    });

    test('parses int latitude/longitude (e.g. JSON 0)', () {
      final json = {
        'method': 'isna',
        'madhab': 'shafi',
        'latitude': 0,
        'longitude': 0,
        'highLatitudeRule': 'middle_of_the_night',
      };
      final s = PrayerSettingsMapper.fromJson(json);
      expect(s.latitude, 0.0);
      expect(s.longitude, 0.0);
    });

    test('defaults highLatitudeRule when key missing (legacy blob)', () {
      final json = {
        'method': 'uoif',
        'madhab': 'shafi',
        'latitude': 48.85,
        'longitude': 2.35,
      };
      final s = PrayerSettingsMapper.fromJson(json);
      expect(s.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
    });

    test('throws on unknown method string', () {
      final json = {
        'method': 'xtra_method_does_not_exist',
        'madhab': 'shafi',
        'latitude': 0,
        'longitude': 0,
      };
      expect(() => PrayerSettingsMapper.fromJson(json), throwsArgumentError);
    });

    test('throws on unknown madhab string', () {
      final json = {
        'method': 'uoif',
        'madhab': 'jafari',
        'latitude': 0,
        'longitude': 0,
      };
      expect(() => PrayerSettingsMapper.fromJson(json), throwsArgumentError);
    });

    test('throws on unknown highLatitudeRule', () {
      final json = {
        'method': 'uoif',
        'madhab': 'shafi',
        'latitude': 0,
        'longitude': 0,
        'highLatitudeRule': 'wrong',
      };
      expect(() => PrayerSettingsMapper.fromJson(json), throwsArgumentError);
    });

    test('throws on non-numeric latitude', () {
      final json = {
        'method': 'uoif',
        'madhab': 'shafi',
        'latitude': 'NaN',
        'longitude': 0,
      };
      expect(() => PrayerSettingsMapper.fromJson(json), throwsArgumentError);
    });
  });

  group('PrayerSettingsMapper — exhaustivité méthodes', () {
    test('toJson covers all 16 CalculationMethod values', () {
      // Si une méthode est ajoutée à l'enum sans mapping ici, le switch dans
      // _methodToString explosera à compile time grâce à Dart 3 exhaustiveness.
      // Ce test verrouille le contrat à runtime aussi.
      for (final m in CalculationMethod.values) {
        final s = PrayerSettings(
          method: m,
          madhab: Madhab.shafi,
          latitude: 0,
          longitude: 0,
        );
        final json = PrayerSettingsMapper.toJson(s);
        expect(json['method'], isA<String>());
        // Round-trip
        expect(PrayerSettingsMapper.fromJson(json).method, m);
      }
    });
  });
}
