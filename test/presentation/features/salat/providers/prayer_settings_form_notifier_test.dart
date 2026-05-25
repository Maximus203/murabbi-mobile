import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/save_prayer_settings_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_settings_form_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_settings_form_state.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';

class _MockPrayerSettingsRepository extends Mock
    implements PrayerSettingsRepository {}

class _FakePrayerSettings extends Fake implements PrayerSettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrayerSettings());
  });

  late _MockPrayerSettingsRepository repo;

  setUp(() {
    repo = _MockPrayerSettingsRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        getPrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => GetPrayerSettingsUseCase(repo),
        ),
        savePrayerSettingsUseCaseProvider.overrideWith(
          (ref) async => SavePrayerSettingsUseCase(repo),
        ),
      ],
    );
  }

  group('PrayerSettingsFormState — derived', () {
    test('isValid = false quand lat/lng manquent', () {
      const state = PrayerSettingsFormState.initial();
      expect(state.isValid, isFalse);
    });

    test('isValid = true avec lat/lng dans les bornes', () {
      final state = const PrayerSettingsFormState.initial().copyWith(
        latitude: 48.8566,
        longitude: 2.3522,
      );
      expect(state.isValid, isTrue);
    });

    test('isValid = false avec latitude hors bornes', () {
      final state = const PrayerSettingsFormState.initial().copyWith(
        latitude: 95.0,
        longitude: 2.0,
      );
      expect(state.isValid, isFalse);
    });

    test('needsHighLatitudeRule = false quand |lat| <= 48', () {
      final state = const PrayerSettingsFormState.initial().copyWith(
        latitude: 48.0,
      );
      expect(state.needsHighLatitudeRule, isFalse);
    });

    test('needsHighLatitudeRule = true quand |lat| > 48', () {
      final state = const PrayerSettingsFormState.initial().copyWith(
        latitude: 60.0,
      );
      expect(state.needsHighLatitudeRule, isTrue);
    });
  });

  group('PrayerSettingsFormNotifier — bootstrap', () {
    test('initial state expose les défauts ADR-013', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(prayerSettingsFormNotifierProvider);
      expect(state.method, CalculationMethod.muslimWorldLeague);
      expect(state.madhab, Madhab.shafi);
      expect(state.latitude, isNull);
      expect(state.longitude, isNull);
      expect(state.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
    });
  });

  group('PrayerSettingsFormNotifier — loadInitial()', () {
    test('hydrate les settings existants quand persistés', () async {
      final persisted = PrayerSettings(
        method: CalculationMethod.morocco,
        madhab: Madhab.hanafi,
        latitude: 33.5731,
        longitude: -7.5898,
        highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
      );
      when(() => repo.get()).thenAnswer((_) async => persisted);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(prayerSettingsFormNotifierProvider.notifier)
          .loadInitial();
      final state = container.read(prayerSettingsFormNotifierProvider);

      expect(state.method, CalculationMethod.morocco);
      expect(state.madhab, Madhab.hanafi);
      expect(state.latitude, 33.5731);
      expect(state.longitude, -7.5898);
      expect(state.highLatitudeRule, HighLatitudeRule.seventhOfTheNight);
    });

    test(
      'sans settings persistés + countryCode dérive la méthode par défaut',
      () async {
        when(() => repo.get()).thenAnswer((_) async => null);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(prayerSettingsFormNotifierProvider.notifier)
            .loadInitial(countryCode: 'FR');
        final state = container.read(prayerSettingsFormNotifierProvider);

        expect(state.method, CalculationMethod.uoif);
        expect(state.latitude, isNull);
        expect(state.longitude, isNull);
      },
    );

    test(
      'sans settings persistés sans countryCode garde MWL par défaut',
      () async {
        when(() => repo.get()).thenAnswer((_) async => null);

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(prayerSettingsFormNotifierProvider.notifier)
            .loadInitial();
        final state = container.read(prayerSettingsFormNotifierProvider);

        expect(state.method, CalculationMethod.muslimWorldLeague);
      },
    );
  });

  group('PrayerSettingsFormNotifier — setters', () {
    test('setMethod, setMadhab, setLatitude, setLongitude mutent l\'état', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        prayerSettingsFormNotifierProvider.notifier,
      );
      notifier
        ..setMethod(CalculationMethod.isna)
        ..setMadhab(Madhab.hanafi)
        ..setLatitude(40.7128)
        ..setLongitude(-74.0060)
        ..setHighLatitudeRule(HighLatitudeRule.twilightAngle);

      final state = container.read(prayerSettingsFormNotifierProvider);
      expect(state.method, CalculationMethod.isna);
      expect(state.madhab, Madhab.hanafi);
      expect(state.latitude, 40.7128);
      expect(state.longitude, -74.0060);
      expect(state.highLatitudeRule, HighLatitudeRule.twilightAngle);
    });

    test(
      'setLatitude(null) efface bien la valeur (regression Copilot review)',
      () {
        final container = makeContainer();
        addTearDown(container.dispose);

        container.read(prayerSettingsFormNotifierProvider.notifier)
          ..setLatitude(48.8566)
          ..setLatitude(null);

        expect(
          container.read(prayerSettingsFormNotifierProvider).latitude,
          isNull,
        );
      },
    );

    test('setLongitude(null) efface bien la valeur', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(prayerSettingsFormNotifierProvider.notifier)
        ..setLongitude(2.3522)
        ..setLongitude(null);

      expect(
        container.read(prayerSettingsFormNotifierProvider).longitude,
        isNull,
      );
    });
  });

  group('PrayerSettingsFormNotifier — save()', () {
    test(
      'refuse de sauver si lat/lng manquent (error.missingCoordinates)',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        final ok = await container
            .read(prayerSettingsFormNotifierProvider.notifier)
            .save();

        expect(ok, isFalse);
        verifyNever(() => repo.save(any()));
        final state = container.read(prayerSettingsFormNotifierProvider);
        expect(state.error, PrayerSettingsFormError.missingCoordinates);
        expect(state.isSaving, isFalse);
      },
    );

    test('persiste les settings valides et retourne true', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(
        prayerSettingsFormNotifierProvider.notifier,
      );
      notifier
        ..setMethod(CalculationMethod.uoif)
        ..setMadhab(Madhab.shafi)
        ..setLatitude(48.8566)
        ..setLongitude(2.3522);

      final ok = await notifier.save();

      expect(ok, isTrue);
      final state = container.read(prayerSettingsFormNotifierProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
      final captured =
          verify(() => repo.save(captureAny())).captured.single
              as PrayerSettings;
      expect(captured.method, CalculationMethod.uoif);
      expect(captured.latitude, 48.8566);
      expect(captured.longitude, 2.3522);
    });

    test(
      'latitude hors bornes -> error.invalidLatitude (regression Copilot)',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        final notifier =
            container.read(prayerSettingsFormNotifierProvider.notifier)
              ..setLatitude(95.0)
              ..setLongitude(2.0);

        final ok = await notifier.save();
        expect(ok, isFalse);
        verifyNever(() => repo.save(any()));
        expect(
          container.read(prayerSettingsFormNotifierProvider).error,
          PrayerSettingsFormError.invalidLatitude,
        );
      },
    );

    test(
      'longitude hors bornes -> error.invalidLongitude (regression Copilot)',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        final notifier =
            container.read(prayerSettingsFormNotifierProvider.notifier)
              ..setLatitude(48.0)
              ..setLongitude(200.0);

        final ok = await notifier.save();
        expect(ok, isFalse);
        verifyNever(() => repo.save(any()));
        expect(
          container.read(prayerSettingsFormNotifierProvider).error,
          PrayerSettingsFormError.invalidLongitude,
        );
      },
    );

    test('expose l\'erreur si le repository échoue', () async {
      when(() => repo.save(any())).thenThrow(Exception('disk full'));

      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(prayerSettingsFormNotifierProvider.notifier)
            ..setLatitude(48.0)
            ..setLongitude(2.0);

      final ok = await notifier.save();

      expect(ok, isFalse);
      final state = container.read(prayerSettingsFormNotifierProvider);
      expect(state.error, PrayerSettingsFormError.saveFailed);
      expect(state.isSaving, isFalse);
    });
  });
}
