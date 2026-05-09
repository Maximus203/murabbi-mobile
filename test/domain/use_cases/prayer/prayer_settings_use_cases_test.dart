import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/derive_default_method_from_country_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/save_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';

class MockRepo extends Mock implements PrayerSettingsRepository {}

class FakePrayerSettings extends Fake implements PrayerSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePrayerSettings());
  });

  late MockRepo repo;
  setUp(() => repo = MockRepo());

  final sample = PrayerSettings(
    method: CalculationMethod.uoif,
    madhab: Madhab.shafi,
    latitude: 48.85,
    longitude: 2.35,
  );

  group('GetPrayerSettingsUseCase', () {
    test('delegates to repository.get and forwards the value', () async {
      when(() => repo.get()).thenAnswer((_) async => sample);
      final useCase = GetPrayerSettingsUseCase(repo);
      expect(await useCase(), sample);
      verify(() => repo.get()).called(1);
    });

    test('forwards null when no settings persisted', () async {
      when(() => repo.get()).thenAnswer((_) async => null);
      final useCase = GetPrayerSettingsUseCase(repo);
      expect(await useCase(), isNull);
    });
  });

  group('SavePrayerSettingsUseCase', () {
    test('delegates to repository.save', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});
      final useCase = SavePrayerSettingsUseCase(repo);
      await useCase(sample);
      verify(() => repo.save(sample)).called(1);
    });
  });

  group('DeriveDefaultMethodFromCountryUseCase (ADR-013 §2.1)', () {
    const useCase = DeriveDefaultMethodFromCountryUseCase();

    test('FR → UOIF', () {
      expect(useCase('FR'), CalculationMethod.uoif);
    });

    test('MA → Morocco', () {
      expect(useCase('MA'), CalculationMethod.morocco);
    });

    test('DZ → Algeria', () {
      expect(useCase('DZ'), CalculationMethod.algeria);
    });

    test('TN → Tunisia', () {
      expect(useCase('TN'), CalculationMethod.tunisia);
    });

    test('EG → Egyptian', () {
      expect(useCase('EG'), CalculationMethod.egyptian);
    });

    test('SA → Umm al-Qura', () {
      expect(useCase('SA'), CalculationMethod.ummAlQura);
    });

    test('AE → Dubai', () {
      expect(useCase('AE'), CalculationMethod.dubai);
    });

    test('KW → Kuwait', () {
      expect(useCase('KW'), CalculationMethod.kuwait);
    });

    test('QA → Qatar', () {
      expect(useCase('QA'), CalculationMethod.qatar);
    });

    test('TR → Diyanet', () {
      expect(useCase('TR'), CalculationMethod.diyanet);
    });

    test('IR → Tehran', () {
      expect(useCase('IR'), CalculationMethod.tehran);
    });

    test('PK / IN / BD → Karachi', () {
      expect(useCase('PK'), CalculationMethod.karachi);
      expect(useCase('IN'), CalculationMethod.karachi);
      expect(useCase('BD'), CalculationMethod.karachi);
    });

    test('SG / MY / ID → Singapore', () {
      expect(useCase('SG'), CalculationMethod.singapore);
      expect(useCase('MY'), CalculationMethod.singapore);
      expect(useCase('ID'), CalculationMethod.singapore);
    });

    test('US / CA → ISNA', () {
      expect(useCase('US'), CalculationMethod.isna);
      expect(useCase('CA'), CalculationMethod.isna);
    });

    test('unknown code → MWL fallback', () {
      expect(useCase('XX'), CalculationMethod.muslimWorldLeague);
      expect(useCase('JP'), CalculationMethod.muslimWorldLeague);
    });

    test('null → MWL fallback', () {
      expect(useCase(null), CalculationMethod.muslimWorldLeague);
    });

    test('empty string → MWL fallback', () {
      expect(useCase(''), CalculationMethod.muslimWorldLeague);
      expect(useCase('   '), CalculationMethod.muslimWorldLeague);
    });

    test('lower-case code is normalised → UOIF', () {
      expect(useCase('fr'), CalculationMethod.uoif);
    });

    test('whitespace around code is trimmed', () {
      expect(useCase(' fr '), CalculationMethod.uoif);
    });
  });
}
