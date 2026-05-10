import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_times_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

class _MockRepo extends Mock implements PrayerSettingsRepository {}

class _MockService extends Mock implements PrayerTimesService {}

class _FakeSettings extends Fake implements PrayerSettings {}

PrayerTimes _buildTimes(DateTime base) => PrayerTimes(
  fajr: base.add(const Duration(hours: 4, minutes: 30)),
  sunrise: base.add(const Duration(hours: 6, minutes: 15)),
  dhuhr: base.add(const Duration(hours: 13, minutes: 45)),
  asr: base.add(const Duration(hours: 17)),
  maghrib: base.add(const Duration(hours: 21)),
  isha: base.add(const Duration(hours: 22, minutes: 30)),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSettings());
    registerFallbackValue(DateTime.utc(2024));
  });

  late _MockRepo repo;
  late _MockService service;
  late GetPrayerTimesUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    service = _MockService();
    useCase = GetPrayerTimesUseCase(service: service, repository: repo);
  });

  test('when settings exist and no day is provided -> uses today UTC and '
      'delegates to service', () async {
    final settings = PrayerSettings(
      method: CalculationMethod.uoif,
      madhab: Madhab.shafi,
      latitude: 48.8566,
      longitude: 2.3522,
    );
    when(repo.get).thenAnswer((_) async => settings);
    final today = DateTime.now().toUtc();
    final expectedTimes = _buildTimes(
      DateTime.utc(today.year, today.month, today.day),
    );
    when(
      () => service.computeForDay(
        settings: any(named: 'settings'),
        day: any(named: 'day'),
      ),
    ).thenReturn(expectedTimes);

    final result = await useCase();

    expect(result, expectedTimes);
    final captured = verify(
      () => service.computeForDay(
        settings: captureAny(named: 'settings'),
        day: captureAny(named: 'day'),
      ),
    ).captured;
    expect(captured[0], settings);
    final passedDay = captured[1] as DateTime;
    expect(passedDay.year, today.year);
    expect(passedDay.month, today.month);
    expect(passedDay.day, today.day);
  });

  test(
    'when settings exist and a day is provided -> service receives that day',
    () async {
      final settings = PrayerSettings(
        method: CalculationMethod.morocco,
        madhab: Madhab.shafi,
        latitude: 33.5731,
        longitude: -7.5898,
      );
      final day = DateTime.utc(2025, 3, 1);
      final expected = _buildTimes(day);
      when(repo.get).thenAnswer((_) async => settings);
      when(
        () => service.computeForDay(
          settings: any(named: 'settings'),
          day: any(named: 'day'),
        ),
      ).thenReturn(expected);

      final result = await useCase(day: day);

      expect(result, expected);
      verify(
        () => service.computeForDay(settings: settings, day: day),
      ).called(1);
    },
  );

  test(
    'when settings are absent -> throws PrayerFailure.settingsNotConfigured',
    () async {
      when(repo.get).thenAnswer((_) async => null);

      await expectLater(
        useCase(),
        throwsA(isA<PrayerSettingsNotConfiguredFailure>()),
      );
      verifyNever(
        () => service.computeForDay(
          settings: any(named: 'settings'),
          day: any(named: 'day'),
        ),
      );
    },
  );
}
