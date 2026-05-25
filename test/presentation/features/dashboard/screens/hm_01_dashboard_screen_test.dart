import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_settings_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_times_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/screens/hm_01_dashboard_screen.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_providers.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

class _MockSettingsRepo extends Mock implements PrayerSettingsRepository {}

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
      ],
      child: MaterialApp(
        home: Hm01DashboardScreen(
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

    expect(find.text('As-salāmu ʿalaykum'), findsOneWidget);
    expect(find.text('PROCHAINE PRIÈRE'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
  });

  testWidgets('affiche le CTA "Configurer" quand settings non configurés', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable(settingsNotConfigured: true));
    await tester.pumpAndSettle();

    expect(find.text('Configurez vos prières'), findsOneWidget);
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

  testWidgets('rend la carte intention du jour', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    // La _NiyyahCard affiche "INTENTION DU JOUR" (redesign HM-01).
    // Section score masquée hors session (pas d'auth dans ce test).
    expect(find.text('INTENTION DU JOUR'), findsOneWidget);
    expect(find.text('Habitudes du jour'), findsNothing);
    expect(find.text('Série globale'), findsNothing);
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
    expect(find.textContaining('·'), findsOneWidget);
  });

  testWidgets('_NextPrayerCard affiche un ChevronRight (#59)', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
  });

  testWidgets(
    'UX-5 : icône Bell absente, avatar remplace l\'accès aux paramètres (#58)',
    (tester) async {
      await tester.pumpWidget(pumpable());
      await tester.pumpAndSettle();
      // Bell supprimé — l'avatar est désormais le point d'entrée paramètres.
      expect(find.byIcon(lu(LucideIcons.bell)), findsNothing);
      // L'avatar circulaire affiche l'initiale (user null → '?').
      expect(find.text('?'), findsOneWidget);
    },
  );
}
