import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_state.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_03_prayer_detail_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

import '../../../helpers/test_uuids.dart';

/// Tests de layout SA-03 — vérifie que les 5 sections clés (hero, statut
/// actuel, MARQUER COMME, toggle rattrapée, CETTE SEMAINE) correspondent
/// à la structure du wireframe SL-DETAIL.
void main() {
  // ── Builders d'état ────────────────────────────────────────────────────────

  PrayerDetailState buildDetailState({
    PrayerStatus fajrToday = PrayerStatus.pending,
  }) {
    final days = List.generate(7, (i) {
      final d = DateTime.utc(2026, 5, 21 + i);
      final isToday = i == 6;
      return PrayerDay(
        userId: UserId(kUserIdAlpha),
        date: d,
        fajr: isToday ? fajrToday : PrayerStatus.pending,
        dhuhr: PrayerStatus.pending,
        asr: PrayerStatus.pending,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      );
    });
    return PrayerDetailState(prayerName: 'fajr', weekDays: days);
  }

  TodaySalatState buildTodaySalatState() {
    final day = DateTime.utc(2026, 5, 27);
    return TodaySalatState(
      date: day,
      prayerDay: PrayerDay(
        userId: UserId(kUserIdAlpha),
        date: day,
        fajr: PrayerStatus.pending,
        dhuhr: PrayerStatus.pending,
        asr: PrayerStatus.pending,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      ),
      prayerTimes: PrayerTimes(
        fajr: DateTime.utc(2026, 5, 27, 4, 21),
        sunrise: DateTime.utc(2026, 5, 27, 6, 0),
        dhuhr: DateTime.utc(2026, 5, 27, 12, 7),
        asr: DateTime.utc(2026, 5, 27, 15, 27),
        maghrib: DateTime.utc(2026, 5, 27, 18, 34),
        isha: DateTime.utc(2026, 5, 27, 19, 47),
      ),
    );
  }

  // ── Helper widget builder ─────────────────────────────────────────────────

  Widget buildApp(PrayerDetailState detailState) {
    return ProviderScope(
      overrides: [
        // Family override — s'applique à toutes les valeurs d'arg (prayerName).
        prayerDetailNotifierProvider.overrideWith(
          () => _FakePrayerDetailNotifier(detailState),
        ),
        todaySalatNotifierProvider.overrideWith(
          () => _FakeTodaySalatNotifier(buildTodaySalatState()),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
        ),
        home: Sa03PrayerDetailScreen(
          prayerName: 'fajr',
          onBack: () {},
        ),
      ),
    );
  }

  // ── Tests ─────────────────────────────────────────────────────────────────

  group('SA-03 — hero overlay', () {
    testWidgets('affiche le nom arabe dans le hero (الفجر)', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('الفجر'), findsOneWidget);
    });

    testWidgets('affiche le nom latin dans le hero (Fajr)', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('Fajr'), findsOneWidget);
    });
  });

  group('SA-03 — statut actuel', () {
    testWidgets('affiche "Statut actuel :" avec le libellé du statut',
        (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      // Le texte est "Statut actuel : Non priée" (pending)
      expect(find.textContaining('Statut actuel :'), findsOneWidget);
    });

    testWidgets('statut onTime affiche le bon libellé', (tester) async {
      await tester.pumpWidget(
        buildApp(buildDetailState(fajrToday: PrayerStatus.onTime)),
      );
      await tester.pump();

      expect(find.textContaining('À l\'heure'), findsWidgets);
    });
  });

  group('SA-03 — section MARQUER COMME', () {
    testWidgets('affiche le label "MARQUER COMME"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('MARQUER COMME'), findsOneWidget);
    });

    testWidgets('affiche le bouton "À l\'heure"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('À l\'heure'), findsOneWidget);
    });

    testWidgets('affiche le bouton "En retard"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      // "En retard" peut apparaître aussi dans le statut actuel — au moins 1
      expect(find.text('En retard'), findsAtLeast(1));
    });

    testWidgets('affiche le bouton "Manquée"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('Manquée'), findsOneWidget);
    });

    testWidgets('affiche le bouton "Réinitialiser"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('Réinitialiser'), findsOneWidget);
    });
  });

  group('SA-03 — toggle rattrapée', () {
    testWidgets('affiche "Marquer comme rattrapée"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('Marquer comme rattrapée'), findsOneWidget);
    });

    testWidgets('affiche le sous-titre "À effectuer plus tard"', (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      expect(find.text('À effectuer plus tard'), findsOneWidget);
    });
  });

  group('SA-03 — section semaine', () {
    testWidgets('affiche le label "CETTE SEMAINE" (pas "7 DERNIERS JOURS")',
        (tester) async {
      await tester.pumpWidget(buildApp(buildDetailState()));
      await tester.pump();

      // Nouveau label wireframe
      expect(find.text('CETTE SEMAINE'), findsOneWidget);
      // Ancien label — doit avoir disparu
      expect(find.text('7 DERNIERS JOURS'), findsNothing);
    });
  });
}

// ── Notifiers de test ────────────────────────────────────────────────────────

/// Notifier de test SA-03 — retourne un état fixe sans appels réseau.
class _FakePrayerDetailNotifier extends PrayerDetailNotifier {
  final PrayerDetailState _state;
  _FakePrayerDetailNotifier(this._state);

  @override
  Future<PrayerDetailState> build(String prayerName) async => _state;
}

/// Notifier de test SA-01 — retourne un état fixe pour les horaires.
class _FakeTodaySalatNotifier extends TodaySalatNotifier {
  final TodaySalatState _state;
  _FakeTodaySalatNotifier(this._state);

  @override
  Future<TodaySalatState> build() async => _state;
}
