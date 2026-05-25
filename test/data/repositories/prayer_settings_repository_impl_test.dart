import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/prayer_settings_data_source.dart';
import 'package:murabbi_mobile/data/repositories/prayer_settings_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

class MockDataSource extends Mock implements PrayerSettingsDataSource {}

void main() {
  late MockDataSource ds;
  late PrayerSettingsRepositoryImpl repo;

  setUp(() {
    ds = MockDataSource();
    repo = PrayerSettingsRepositoryImpl(ds);
  });

  final sample = PrayerSettings(
    method: CalculationMethod.uoif,
    madhab: Madhab.shafi,
    latitude: 48.85,
    longitude: 2.35,
  );

  group('PrayerSettingsRepositoryImpl.get', () {
    test('returns null when datasource has nothing', () async {
      when(() => ds.read()).thenAnswer((_) async => null);
      expect(await repo.get(), isNull);
      verify(() => ds.read()).called(1);
    });

    test('parses the JSON via the mapper', () async {
      when(() => ds.read()).thenAnswer(
        (_) async => {
          'method': 'uoif',
          'madhab': 'shafi',
          'latitude': 48.85,
          'longitude': 2.35,
          'highLatitudeRule': 'middle_of_the_night',
        },
      );
      final result = await repo.get();
      expect(result, sample);
    });

    test(
      'returns null when the persisted blob is corrupted (mapper throws)',
      () async {
        when(() => ds.read()).thenAnswer(
          (_) async => {
            'method': 'unknown_method',
            'madhab': 'shafi',
            'latitude': 0,
            'longitude': 0,
          },
        );
        // L'implémentation doit absorber l'ArgumentError du mapper et
        // retomber sur null pour ne pas planter l'app.
        expect(await repo.get(), isNull);
      },
    );
  });

  group('PrayerSettingsRepositoryImpl.save', () {
    test('serializes via the mapper and writes to the datasource', () async {
      when(() => ds.write(any())).thenAnswer((_) async {});
      await repo.save(sample);
      final captured =
          verify(() => ds.write(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['method'], 'uoif');
      expect(captured['latitude'], 48.85);
    });
  });
}
