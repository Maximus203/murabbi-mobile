import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/prayer_times_provider.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_times_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/screens/hm_01_dashboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/widgets/app_progress_ring.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';
import 'package:murabbi_mobile/services/video_service.dart';

class _MockSettingsRepo extends Mock implements PrayerSettingsRepository {}

/// Stub [VideoService] sans Supabase — retourne une URL vide en test.
/// ADR-017 : nécessaire car Supabase n'est pas initialisé dans les widget tests.
class _StubVideoService implements VideoService {
  const _StubVideoService();
  @override
  String getRemoteVideoUrl(String key) => '';
}

/// Notifier de test retournant une liste statique d'habitudes.
class _FakeHabitsNotifier extends HabitsNotifier {
  _FakeHabitsNotifier(this._habits);
  final List<Habit> _habits;

  @override
  Future<List<Habit>> build() async => _habits;
}

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
  late _MockSettingsRepo settingsRepo;

  final settings = PrayerSettings(
    method: CalculationMethod.uoif,
    madhab: Madhab.shafi,
    latitude: 48.8566,
    longitude: 2.3522,
    highLatitudeRule: HighLatitudeRule.middleOfTheNight,
  );

  final day = DateTime.utc(2026, 5, 12);
  final times = PrayerTimes(
    fajr: day.add(const Duration(hours: 4, minutes: 12)),
    sunrise: day.add(const Duration(hours: 5, minutes: 50)),
    dhuhr: day.add(const Duration(hours: 13, minutes: 51)),
    asr: day.add(const Duration(hours: 17, minutes: 49)),
    maghrib: day.add(const Duration(hours: 21, minutes: 36)),
    isha: day.add(const Duration(hours: 23, minutes: 14)),
  );

  setUp(() {
    settingsRepo = _MockSettingsRepo();
  });

  Widget pumpable({DateTime? now, bool settingsNotConfigured = false}) {
    if (settingsNotConfigured) {
      when(() => settingsRepo.get()).thenAnswer((_) async => null);
    } else {
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);
    }
    final clockNow = now ?? day.add(const Duration(hours: 10));
    return ProviderScope(
      overrides: [
        dashboardClockProvider.overrideWithValue(() => clockNow),
        getPrayerTimesUseCaseProvider.overrideWith(
          (ref) async => GetPrayerTimesUseCase(
            service: _FakePrayerTimesService(times),
            repository: settingsRepo,
          ),
        ),
        // ADR-017 : Supabase non initialisé en test — on court-circuite le
        // provider pour éviter l'assertion '_instance._isInitialized'.
        videoServiceProvider.overrideWithValue(const _StubVideoService()),
      ],
      child: MaterialApp(
        home: Hm01DashboardScreen(
          onTabSelected: (_) {},
          onConfigurePrayers: () {},
          onOpenSalat: () {},
        ),
      ),
    );
  }

  testWidgets('affiche la salutation et la prochaine prière du jour', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    // #132 : ʿ (ayn) remplacé par apostrophe ASCII.
    expect(find.text("AS-SALĀMU 'ALAYKUM"), findsOneWidget);
    expect(find.text('PROCHAINE PRIÈRE'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
  });

  testWidgets('affiche le CTA "Configurer" quand settings non configurés', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable(settingsNotConfigured: true));
    await tester.pumpAndSettle();

    // #133 : registre "tu" cohérent.
    expect(find.text('Configure tes prières'), findsOneWidget);
    expect(find.text('Configurer'), findsOneWidget);
  });

  testWidgets('marque "(DEMAIN)" quand toutes les prières sont passées', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpable(now: day.add(const Duration(hours: 23, minutes: 59))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('DEMAIN'), findsOneWidget);
  });

  testWidgets('rend les sections Habitudes / Niyyah / Score-Streak', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    // Phase 5 : "Série globale" remplacée par _ScoreStreakCard.
    expect(find.text('Habitudes du jour'), findsOneWidget);
    expect(find.text('Niyyah du jour'), findsOneWidget);
    // Phase 5 : _ScoreStreakCard affiche au minimum les 3 labels de stats.
    expect(find.text('Pts hebdo'), findsOneWidget);
    expect(find.text('Série'), findsOneWidget);
    expect(find.text('Niveau'), findsOneWidget);
  });

  test('PrayerSettingsNotConfiguredFailure remonte settingsNotConfigured', () {
    // Pure unit-check : la propagation est testée indirectement par le
    // widget test "Configurer" ci-dessus — ce test sert de marqueur de
    // contrat (la failure doit être PrayerFailure et non un autre type).
    expect(
      const PrayerFailure.settingsNotConfigured(),
      isA<PrayerSettingsNotConfiguredFailure>(),
    );
  });

  // ── Nouveaux tests — issues #57 #62 #59 #66 ───────────────────────────────

  testWidgets('placeholders ne contiennent pas de jargon interne (#57)', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.textContaining('slice 3.D'), findsNothing);
    expect(find.textContaining('(slice'), findsNothing);
    expect(find.textContaining('quand les habitudes'), findsNothing);
  });

  testWidgets('_dualDate retourne le jour capitalisé (#62)', (tester) async {
    // day = DateTime.utc(2026, 5, 12) → mardi 12 mai → doit afficher 'Mardi'
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.textContaining('Mardi'), findsOneWidget);
  });

  testWidgets('affiche la date avec séparateur Hijri (#66)', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    // La date duale contient "·" entre gregorien et hijri, et un mois hijri connu
    expect(find.textContaining('1447'), findsOneWidget);
  });

  testWidgets('_NextPrayerCard affiche un ChevronRight (#59)', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets('ne montre plus le stub notification Bell (#128)', (
    tester,
  ) async {
    // #128 : le bouton cloche stub (fausse affordance) a été retiré du
    // header jusqu'à l'implémentation réelle des notifications (Phase 5).
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.bell), findsNothing);
  });

  // ── Nouveaux tests — issue #89 (mis à jour Phase 5 : _ScoreStreakCard) ──────

  testWidgets(
    'score card (_ScoreStreakCard) affiche les labels de stats (#89 Phase 5)',
    (tester) async {
      await tester.pumpWidget(pumpable());
      await tester.pumpAndSettle();

      // _ScoreStreakCard affiche 3 labels permanents (Phase 5 — _ScoreCard supprimée)
      expect(find.text('Pts hebdo'), findsOneWidget);
      expect(find.text('Série'), findsOneWidget);
      expect(find.text('Niveau'), findsOneWidget);
    },
  );

  testWidgets(
    'section habitudes affiche état vide quand pas d\'habitudes (#89)',
    (tester) async {
      await tester.pumpWidget(pumpable());
      await tester.pumpAndSettle();

      // Sans habitudes, on affiche le texte d'état vide
      expect(find.textContaining('habitude'), findsWidgets);
    },
  );

  testWidgets(
    'section habitudes affiche les micro-rows quand habitudes présentes (#89)',
    (tester) async {
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);
      final habit = Habit(
        id: HabitId('h-test-1'),
        name: NonEmptyString('Lecture Coran'),
        categoryId: CategoryId('cat-religion'),
        frequencyType: HabitFrequencyType.daily,
        frequency: 1,
        activeDays: const {1, 2, 3, 4, 5, 6, 7},
        points: HabitPoints(5),
        isSystem: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardClockProvider.overrideWithValue(
              () => day.add(const Duration(hours: 10)),
            ),
            getPrayerTimesUseCaseProvider.overrideWith(
              (ref) async => GetPrayerTimesUseCase(
                service: _FakePrayerTimesService(times),
                repository: settingsRepo,
              ),
            ),
            habitsNotifierProvider.overrideWith(
              () => _FakeHabitsNotifier([habit]),
            ),
            // ADR-017 : Supabase non initialisé en test.
            videoServiceProvider.overrideWithValue(const _StubVideoService()),
          ],
          child: MaterialApp(
            home: Hm01DashboardScreen(
              onTabSelected: (_) {},
              onConfigurePrayers: () {},
              onOpenSalat: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lecture Coran'), findsOneWidget);
    },
  );

  testWidgets(
    'section habitudes max 5 habitudes + lien Voir tout si plus (#89)',
    (tester) async {
      when(() => settingsRepo.get()).thenAnswer((_) async => settings);
      final habits = List.generate(
        7,
        (i) => Habit(
          id: HabitId('h-$i'),
          name: NonEmptyString('Habitude $i'),
          categoryId: CategoryId('cat-religion'),
          frequencyType: HabitFrequencyType.daily,
          frequency: 1,
          activeDays: const {1, 2, 3, 4, 5, 6, 7},
          points: HabitPoints(5),
          isSystem: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardClockProvider.overrideWithValue(
              () => day.add(const Duration(hours: 10)),
            ),
            getPrayerTimesUseCaseProvider.overrideWith(
              (ref) async => GetPrayerTimesUseCase(
                service: _FakePrayerTimesService(times),
                repository: settingsRepo,
              ),
            ),
            habitsNotifierProvider.overrideWith(
              () => _FakeHabitsNotifier(habits),
            ),
            // ADR-017 : Supabase non initialisé en test.
            videoServiceProvider.overrideWithValue(const _StubVideoService()),
          ],
          child: MaterialApp(
            home: Hm01DashboardScreen(
              onTabSelected: (_) {},
              onConfigurePrayers: () {},
              onOpenSalat: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Affiche au max 5 habitudes
      expect(find.text('Habitude 0'), findsOneWidget);
      expect(find.text('Habitude 4'), findsOneWidget);
      expect(find.text('Habitude 5'), findsNothing);
      // Lien "Voir tout" présent
      expect(find.text('Voir tout'), findsOneWidget);
    },
  );
}
