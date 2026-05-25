import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_times_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_today_prayers_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/mark_prayer_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

class _MockPrayerRepository extends Mock implements PrayerRepository {}

class _MockPrayerSettingsRepository extends Mock
    implements PrayerSettingsRepository {}

class _FakePrayerTimesService implements PrayerTimesService {
  PrayerTimes? response;
  Object? error;
  int callCount = 0;

  @override
  PrayerTimes computeForDay({
    required PrayerSettings settings,
    required DateTime day,
  }) {
    callCount++;
    if (error != null) {
      // ignore: only_throw_errors
      throw error!;
    }
    return response!;
  }
}

PrayerTimes _times(DateTime civilDayUtc) {
  // Six horaires UTC strictement croissants — valeurs arbitraires mais
  // ordonnées (cf. invariant PrayerTimes).
  return PrayerTimes(
    fajr: civilDayUtc.add(const Duration(hours: 5)),
    sunrise: civilDayUtc.add(const Duration(hours: 6, minutes: 30)),
    dhuhr: civilDayUtc.add(const Duration(hours: 13)),
    asr: civilDayUtc.add(const Duration(hours: 16, minutes: 15)),
    maghrib: civilDayUtc.add(const Duration(hours: 19, minutes: 30)),
    isha: civilDayUtc.add(const Duration(hours: 21)),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(PrayerStatus.pending);
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(UserId('fallback-user'));
  });

  late _MockPrayerRepository prayerRepo;
  late _MockPrayerSettingsRepository settingsRepo;
  late _FakePrayerTimesService timesService;

  final testUser = User(
    id: UserId('user-uuid-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  final settings = PrayerSettings(
    method: CalculationMethod.uoif,
    madhab: Madhab.shafi,
    latitude: 48.8566,
    longitude: 2.3522,
    highLatitudeRule: HighLatitudeRule.middleOfTheNight,
  );

  final clockNow = DateTime.utc(2026, 5, 12, 14, 30);
  final civilDay = DateTime.utc(2026, 5, 12);

  final emptyPrayerDay = PrayerDay(
    userId: testUser.id,
    date: civilDay,
    fajr: PrayerStatus.pending,
    dhuhr: PrayerStatus.pending,
    asr: PrayerStatus.pending,
    maghrib: PrayerStatus.pending,
    isha: PrayerStatus.pending,
  );

  final freshTimes = _times(civilDay);

  setUp(() {
    prayerRepo = _MockPrayerRepository();
    settingsRepo = _MockPrayerSettingsRepository();
    timesService = _FakePrayerTimesService()..response = freshTimes;
  });

  ProviderContainer makeContainer({bool authenticated = true}) {
    return ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(authenticated ? testUser : null),
        clockProvider.overrideWithValue(() => clockNow),
        getTodayPrayersUseCaseProvider.overrideWithValue(
          GetTodayPrayersUseCase(prayerRepo),
        ),
        markPrayerUseCaseProvider.overrideWithValue(
          MarkPrayerUseCase(prayerRepo),
        ),
        getPrayerTimesUseCaseProvider.overrideWith(
          (ref) async => GetPrayerTimesUseCase(
            service: timesService,
            repository: settingsRepo,
          ),
        ),
      ],
    );
  }

  group('TodaySalatNotifier — build()', () {
    test('charge en parallèle PrayerDay du jour + PrayerTimes UTC', () async {
      when(
        () => prayerRepo.getTodayPrayers(testUser.id),
      ).thenAnswer((_) async => emptyPrayerDay);
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(todaySalatNotifierProvider.future);

      expect(state.date, equals(civilDay));
      expect(state.prayerDay, equals(emptyPrayerDay));
      expect(state.prayerTimes, equals(freshTimes));
      verify(() => prayerRepo.getTodayPrayers(testUser.id)).called(1);
      expect(timesService.callCount, 1);
    });

    test(
      'propage PrayerFailure.settingsNotConfigured quand aucune config',
      () async {
        when(
          () => prayerRepo.getTodayPrayers(testUser.id),
        ).thenAnswer((_) async => emptyPrayerDay);
        when(() => settingsRepo.get()).thenAnswer((_) async => null);

        final container = makeContainer();
        addTearDown(container.dispose);

        await expectLater(
          container.read(todaySalatNotifierProvider.future),
          throwsA(isA<PrayerSettingsNotConfiguredFailure>()),
        );
      },
    );

    test('lève StateError si aucun utilisateur authentifié', () async {
      final container = makeContainer(authenticated: false);
      addTearDown(container.dispose);

      await expectLater(
        container.read(todaySalatNotifierProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('TodaySalatNotifier — markPrayer()', () {
    test(
      'persiste le statut puis recharge le PrayerDay (PrayerTimes inchangés)',
      () async {
        final updatedPrayerDay = PrayerDay(
          userId: testUser.id,
          date: civilDay,
          fajr: PrayerStatus.onTime,
          dhuhr: PrayerStatus.pending,
          asr: PrayerStatus.pending,
          maghrib: PrayerStatus.pending,
          isha: PrayerStatus.pending,
        );

        when(() => settingsRepo.get()).thenAnswer((_) async => settings);
        when(
          () => prayerRepo.getTodayPrayers(testUser.id),
        ).thenAnswer((_) async => emptyPrayerDay);
        when(
          () => prayerRepo.markPrayer(
            userId: any(named: 'userId'),
            date: any(named: 'date'),
            prayerName: any(named: 'prayerName'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);

        // bootstrap
        await container.read(todaySalatNotifierProvider.future);

        // second appel renvoie l'état mis à jour
        when(
          () => prayerRepo.getTodayPrayers(testUser.id),
        ).thenAnswer((_) async => updatedPrayerDay);

        await container
            .read(todaySalatNotifierProvider.notifier)
            .markPrayer(prayerName: 'fajr', status: PrayerStatus.onTime);

        final after = container.read(todaySalatNotifierProvider).requireValue;
        expect(after.prayerDay, equals(updatedPrayerDay));
        expect(after.prayerTimes, equals(freshTimes));
        verify(
          () => prayerRepo.markPrayer(
            userId: testUser.id,
            date: civilDay,
            prayerName: 'fajr',
            status: PrayerStatus.onTime,
          ),
        ).called(1);
        // PrayerTimes n'est PAS recalculé sur markPrayer (1 appel = bootstrap).
        expect(timesService.callCount, 1);
      },
    );

    test('expose une AsyncError si markPrayer échoue', () async {
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);
      when(
        () => prayerRepo.getTodayPrayers(testUser.id),
      ).thenAnswer((_) async => emptyPrayerDay);
      when(
        () => prayerRepo.markPrayer(
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          prayerName: any(named: 'prayerName'),
          status: any(named: 'status'),
        ),
      ).thenThrow(const PrayerFailure.network(message: 'no connection'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(todaySalatNotifierProvider.future);
      await container
          .read(todaySalatNotifierProvider.notifier)
          .markPrayer(prayerName: 'dhuhr', status: PrayerStatus.late);

      final state = container.read(todaySalatNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<PrayerNetworkFailure>());
    });

    test('no-op si state n\'est pas encore chargé', () async {
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);
      when(
        () => prayerRepo.getTodayPrayers(testUser.id),
      ).thenAnswer((_) async => emptyPrayerDay);

      final container = makeContainer();
      addTearDown(container.dispose);

      // pas de await sur le bootstrap : on appelle markPrayer trop tôt.
      await container
          .read(todaySalatNotifierProvider.notifier)
          .markPrayer(prayerName: 'fajr', status: PrayerStatus.onTime);

      verifyNever(
        () => prayerRepo.markPrayer(
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          prayerName: any(named: 'prayerName'),
          status: any(named: 'status'),
        ),
      );
    });
  });
}
