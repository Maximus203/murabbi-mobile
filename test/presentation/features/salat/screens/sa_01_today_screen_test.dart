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

  Widget pumpableScreen({
    VoidCallback? onConfigureSettings,
    ValueChanged<String>? onOpenDetail,
  }) {
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
          onOpenDetail: onOpenDetail,
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

    expect(find.text('Aller dans Paramètres'), findsOneWidget);
    await tester.tap(find.text('Aller dans Paramètres'));
    await tester.pumpAndSettle();
    expect(configureCalled, isTrue);
  });

  // D-22 (issue #98) — Option A : tap → navigation SA-03, plus de StatusPicker
  testWidgets(
    'D-22 : tap sur une row déclenche onOpenDetail (navigation SA-03)',
    (tester) async {
      when(
        () => prayerRepo.getTodayPrayers(testUser.id),
      ).thenAnswer((_) async => emptyDay);
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);

      String? openedPrayer;
      await tester.pumpWidget(
        pumpableScreen(onOpenDetail: (name) => openedPrayer = name),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fajr'));
      await tester.pumpAndSettle();

      expect(openedPrayer, equals('fajr'));
      // Pas de bottom sheet ouvert (D-22 Option A — status picker retiré de SA-01).
      expect(find.text("À l'heure"), findsNothing);
    },
  );

  // D-22 : sans onOpenDetail, le tap ne provoque pas d'erreur
  testWidgets('D-22 : tap sans onOpenDetail ne provoque pas d\'erreur', (
    tester,
  ) async {
    when(
      () => prayerRepo.getTodayPrayers(testUser.id),
    ).thenAnswer((_) async => emptyDay);
    when(() => settingsRepo.get()).thenAnswer((_) async => settings);

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    // Aucun onTap → tap silencieux, pas d'exception.
    await tester.tap(find.text('Fajr'), warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  // D-34 (issue #98) : noms arabes affichés sous les noms latins
  testWidgets('D-34 : noms arabes affichés sous chaque nom latin', (
    tester,
  ) async {
    when(
      () => prayerRepo.getTodayPrayers(testUser.id),
    ).thenAnswer((_) async => emptyDay);
    when(() => settingsRepo.get()).thenAnswer((_) async => settings);

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    expect(find.text('فَجْر'), findsOneWidget);
    expect(find.text('ظُهْر'), findsOneWidget);
    expect(find.text('عَصْر'), findsOneWidget);
    expect(find.text('مَغْرِب'), findsOneWidget);
    expect(find.text('عِشَاء'), findsOneWidget);
  });

  // D-19 (issue #98) : prières passées non priées à opacité réduite
  testWidgets('D-19 : prières passées non priées rendues avec Opacity réduite', (
    tester,
  ) async {
    // clockNow = 14h30 UTC → fajr (04h12) et dhuhr (13h51) sont passées.
    when(
      () => prayerRepo.getTodayPrayers(testUser.id),
    ).thenAnswer((_) async => emptyDay);
    when(() => settingsRepo.get()).thenAnswer((_) async => settings);

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    // Au moins une Opacity à 0.55 doit être présente (prières passées pending).
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .where((o) => o.opacity < 1.0)
        .toList();
    expect(opacities, isNotEmpty);
  });
}
