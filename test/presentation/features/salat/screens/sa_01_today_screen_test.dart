import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
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
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_01_today_screen.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

class _MockPrayerRepository extends Mock implements PrayerRepository {}

class _MockPrayerSettingsRepository extends Mock
    implements PrayerSettingsRepository {}

class _FakePrayerTimesService implements PrayerTimesService {
  _FakePrayerTimesService(this.response);
  final PrayerTimes response;
  @override
  PrayerTimes computeForDay({
    required PrayerSettings settings,
    required DateTime day,
  }) => response;
}

void main() {
  setUpAll(() {
    registerFallbackValue(PrayerStatus.pending);
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(UserId('fallback'));
  });

  late _MockPrayerRepository prayerRepo;
  late _MockPrayerSettingsRepository settingsRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );
  final clockNow = DateTime.utc(2026, 5, 12, 14, 30);
  final civilDay = DateTime.utc(2026, 5, 12);
  final settings = PrayerSettings(
    method: CalculationMethod.uoif,
    madhab: Madhab.shafi,
    latitude: 48.8566,
    longitude: 2.3522,
    highLatitudeRule: HighLatitudeRule.middleOfTheNight,
  );
  final times = PrayerTimes(
    fajr: civilDay.add(const Duration(hours: 4, minutes: 12)),
    sunrise: civilDay.add(const Duration(hours: 5, minutes: 50)),
    dhuhr: civilDay.add(const Duration(hours: 13, minutes: 51)),
    asr: civilDay.add(const Duration(hours: 17, minutes: 49)),
    maghrib: civilDay.add(const Duration(hours: 21, minutes: 36)),
    isha: civilDay.add(const Duration(hours: 23, minutes: 14)),
  );
  final emptyDay = PrayerDay(
    userId: testUser.id,
    date: civilDay,
    fajr: PrayerStatus.pending,
    dhuhr: PrayerStatus.pending,
    asr: PrayerStatus.pending,
    maghrib: PrayerStatus.pending,
    isha: PrayerStatus.pending,
  );

  setUp(() {
    prayerRepo = _MockPrayerRepository();
    settingsRepo = _MockPrayerSettingsRepository();
  });

  Widget pumpableScreen({VoidCallback? onConfigureSettings}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        clockProvider.overrideWithValue(() => clockNow),
        getTodayPrayersUseCaseProvider.overrideWithValue(
          GetTodayPrayersUseCase(prayerRepo),
        ),
        markPrayerUseCaseProvider.overrideWithValue(
          MarkPrayerUseCase(prayerRepo),
        ),
        getPrayerTimesUseCaseProvider.overrideWith(
          (ref) async => GetPrayerTimesUseCase(
            service: _FakePrayerTimesService(times),
            repository: settingsRepo,
          ),
        ),
      ],
      child: MaterialApp(
        home: Sa01TodayScreen(
          onConfigureSettings: onConfigureSettings ?? () {},
        ),
      ),
    );
  }

  testWidgets('rend les 5 prières + leurs horaires HH:mm locaux', (
    tester,
  ) async {
    when(
      () => prayerRepo.getTodayPrayers(testUser.id),
    ).thenAnswer((_) async => emptyDay);
    when(() => settingsRepo.get()).thenAnswer((_) async => settings);

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha'), findsOneWidget);
  });

  testWidgets('redirige via le callback quand settings non configurés', (
    tester,
  ) async {
    when(
      () => prayerRepo.getTodayPrayers(testUser.id),
    ).thenAnswer((_) async => emptyDay);
    when(() => settingsRepo.get()).thenAnswer((_) async => null);

    var configureCalled = false;
    await tester.pumpWidget(
      pumpableScreen(onConfigureSettings: () => configureCalled = true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurer les prières'), findsOneWidget);
    await tester.tap(find.text('Configurer les prières'));
    await tester.pumpAndSettle();
    expect(configureCalled, isTrue);
  });

  testWidgets('tap sur une row ouvre le bottom sheet et déclenche markPrayer', (
    tester,
  ) async {
    when(
      () => prayerRepo.getTodayPrayers(testUser.id),
    ).thenAnswer((_) async => emptyDay);
    when(() => settingsRepo.get()).thenAnswer((_) async => settings);
    when(
      () => prayerRepo.markPrayer(
        userId: any(named: 'userId'),
        date: any(named: 'date'),
        prayerName: any(named: 'prayerName'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fajr'));
    await tester.pumpAndSettle();

    // bottom sheet ouvert : on tape "À l'heure"
    expect(find.text("À l'heure"), findsOneWidget);
    await tester.tap(find.text("À l'heure"));
    await tester.pumpAndSettle();

    verify(
      () => prayerRepo.markPrayer(
        userId: testUser.id,
        date: civilDay,
        prayerName: 'fajr',
        status: PrayerStatus.onTime,
      ),
    ).called(1);
  });
}
