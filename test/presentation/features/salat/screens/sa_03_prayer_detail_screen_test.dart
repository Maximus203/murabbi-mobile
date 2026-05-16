import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_history_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/mark_prayer_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_03_prayer_detail_screen.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

class _MockPrayerRepository extends Mock implements PrayerRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(PrayerStatus.pending);
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(UserId('fallback'));
  });

  late _MockPrayerRepository prayerRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  final clockNow = DateTime.utc(2026, 5, 12, 14, 30);
  final today = DateTime.utc(2026, 5, 12);

  /// Crée 7 jours glissants remplis de `pending`.
  List<PrayerDay> sevenDaysPending() {
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return PrayerDay(
        userId: testUser.id,
        date: date,
        fajr: PrayerStatus.pending,
        dhuhr: PrayerStatus.pending,
        asr: PrayerStatus.pending,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      );
    });
  }

  setUp(() {
    prayerRepo = _MockPrayerRepository();
  });

  Widget pumpableScreen({String prayerName = 'fajr'}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        clockProvider.overrideWithValue(() => clockNow),
        markPrayerUseCaseProvider.overrideWithValue(
          MarkPrayerUseCase(prayerRepo),
        ),
        getPrayerHistoryUseCaseProvider.overrideWithValue(
          GetPrayerHistoryUseCase(prayerRepo),
        ),
      ],
      child: MaterialApp(
        home: Sa03PrayerDetailScreen(
          prayerName: prayerName,
          onBack: () {},
        ),
      ),
    );
  }

  testWidgets('affiche le titre de la prière et le statut courant', (
    tester,
  ) async {
    when(
      () => prayerRepo.getPrayerHistory(
        userId: testUser.id,
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => sevenDaysPending());

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    expect(find.text('Fajr'), findsWidgets);
    expect(find.text('Non priée'), findsOneWidget);
  });

  // D-04 / D-20 (issue #99) : bouton Modifier DS-compliant (AppButton.link)
  testWidgets(
    'D-04/D-20 : bouton Modifier est un AppButton.link (pas de TextButton Material)',
    (tester) async {
      when(
        () => prayerRepo.getPrayerHistory(
          userId: testUser.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => sevenDaysPending());

      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      // Vérifier qu'AppButton est présent avec label "Modifier".
      final appButtons = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((b) => b.label == 'Modifier')
          .toList();
      expect(appButtons, hasLength(1));
      expect(appButtons.first.variant, equals(AppButtonVariant.link));

      // Aucun TextButton Material.
      expect(find.byType(TextButton), findsNothing);
    },
  );

  // D-04 : tap sur Modifier ouvre le StatusPickerBottomSheet
  testWidgets(
    'D-04 : tap sur Modifier ouvre le bottom sheet de changement de statut',
    (tester) async {
      when(
        () => prayerRepo.getPrayerHistory(
          userId: testUser.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => sevenDaysPending());

      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      // Le bottom sheet contient les options de statut.
      expect(find.text("À l'heure"), findsOneWidget);
    },
  );

  // D-26 (issue #99) : légende supprimée — _LegendChip n'est plus présent
  testWidgets(
    'D-26 : légende redondante (_LegendChip) absente de l\'écran',
    (tester) async {
      when(
        () => prayerRepo.getPrayerHistory(
          userId: testUser.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => sevenDaysPending());

      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      // Les labels de statuts ne doivent pas apparaître en double (légende
      // supprimée). "Non priée" doit apparaître exactement 1 fois (statut
      // courant), pas N fois (légende).
      // Avec 7 jours tous pending et le statut courant, sans légende :
      // "Non priée" = 1 occurrence (statut courant uniquement).
      expect(find.text('Non priée'), findsOneWidget);
    },
  );

  // D-26 : icône info + tooltip visible
  testWidgets(
    'D-26 : icône info présente (légende accessible via tooltip)',
    (tester) async {
      when(
        () => prayerRepo.getPrayerHistory(
          userId: testUser.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => sevenDaysPending());

      await tester.pumpWidget(pumpableScreen());
      await tester.pumpAndSettle();

      expect(find.byTooltip('À l\'heure · En retard · Rattrapée · Manquée · Non priée'),
          findsOneWidget);
    },
  );

  testWidgets('affiche les 7 pastilles de la heatmap', (tester) async {
    when(
      () => prayerRepo.getPrayerHistory(
        userId: testUser.id,
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => sevenDaysPending());

    await tester.pumpWidget(pumpableScreen());
    await tester.pumpAndSettle();

    // 7 pastilles = 7 Semantics(button: true) dans la heatmap.
    final semanticButtons = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.button == true)
        .toList();
    expect(semanticButtons.length, greaterThanOrEqualTo(7));
  });
}
