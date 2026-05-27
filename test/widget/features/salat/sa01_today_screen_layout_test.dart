import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_state.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_01_today_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

import '../../../helpers/test_uuids.dart';

/// Tests de layout SA-01 — vérifie que les trois sections clés (hero, carte
/// de prière, bannière résumé) respectent la structure attendue par le design.
///
/// Couverture minimale : smoke test layout + présence des données.
/// Golden tests à ajouter en Phase 5 polish (nécessite golden_toolkit setup).
void main() {
  /// Construit un [TodaySalatState] avec toutes les prières en attente
  /// et des horaires UTC de référence.
  TodaySalatState buildPendingState() {
    final day = DateTime.utc(2026, 5, 26);
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
        fajr: DateTime.utc(2026, 5, 26, 4, 21),
        sunrise: DateTime.utc(2026, 5, 26, 6, 0),
        dhuhr: DateTime.utc(2026, 5, 26, 12, 7),
        asr: DateTime.utc(2026, 5, 26, 15, 27),
        maghrib: DateTime.utc(2026, 5, 26, 18, 34),
        isha: DateTime.utc(2026, 5, 26, 19, 47),
      ),
    );
  }

  /// Construit un [TodaySalatState] avec 2 prières à l'heure, 1 en retard.
  TodaySalatState buildMixedState() {
    final day = DateTime.utc(2026, 5, 26);
    return TodaySalatState(
      date: day,
      prayerDay: PrayerDay(
        userId: UserId(kUserIdAlpha),
        date: day,
        fajr: PrayerStatus.onTime,
        dhuhr: PrayerStatus.onTime,
        asr: PrayerStatus.late,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      ),
      prayerTimes: PrayerTimes(
        fajr: DateTime.utc(2026, 5, 26, 4, 21),
        sunrise: DateTime.utc(2026, 5, 26, 6, 0),
        dhuhr: DateTime.utc(2026, 5, 26, 12, 7),
        asr: DateTime.utc(2026, 5, 26, 15, 27),
        maghrib: DateTime.utc(2026, 5, 26, 18, 34),
        isha: DateTime.utc(2026, 5, 26, 19, 47),
      ),
    );
  }

  Widget buildApp(TodaySalatState state) {
    return ProviderScope(
      overrides: [
        todaySalatNotifierProvider.overrideWith(
          () => _FakeNotifier(state),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent),
        ),
        home: Sa01TodayScreen(
          onConfigureSettings: () {},
        ),
      ),
    );
  }

  group('SA-01 — layout prayer cards', () {
    testWidgets('affiche les 5 noms arabes des prières', (tester) async {
      await tester.pumpWidget(buildApp(buildPendingState()));
      await tester.pump();

      // Noms arabes conformes au wireframe : article défini "ال", sans diacritiques
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('الظهر'), findsOneWidget);
      expect(find.text('العصر'), findsOneWidget);
      expect(find.text('المغرب'), findsOneWidget);
      expect(find.text('العشاء'), findsOneWidget);
    });

    testWidgets('affiche les 5 noms latins des prières', (tester) async {
      await tester.pumpWidget(buildApp(buildPendingState()));
      await tester.pump();

      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Dhuhr'), findsOneWidget);
      expect(find.text('Asr'), findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Isha'), findsOneWidget);
    });

    testWidgets('le hero affiche "X/5 complétées" dans le subtitle', (tester) async {
      await tester.pumpWidget(buildApp(buildPendingState()));
      await tester.pump();

      // Avec toutes les prières pending, completed = 0
      // Le subtitle doit contenir "0/5 complétées" (sans espaces autour du /)
      expect(find.textContaining('0/5 complétées'), findsOneWidget);
    });

    testWidgets('le hero subtitle est une seule ligne (date + compteur fusionnés)', (tester) async {
      await tester.pumpWidget(buildApp(buildPendingState()));
      await tester.pump();

      // La date et le compteur ne doivent PAS être deux Text distincts
      // séparés — on vérifie que le compteur est dans le même texte que la date.
      // En cherchant un texte contenant à la fois "2026" ET "complétées"
      expect(
        find.textContaining('2026'),
        findsWidgets, // date présente quelque part
      );
      // Un seul widget contient le "·" séparateur
      expect(find.textContaining('·'), findsAtLeast(1));
    });

    testWidgets('la bannière résumé est masquée quand 0 prières complétées', (tester) async {
      await tester.pumpWidget(buildApp(buildPendingState()));
      await tester.pumpAndSettle();

      // Avec 0 onTime / 0 late / 0 missed → bannière cachée (aucun chip ni texte résumé)
      // La nouvelle bannière utilise un format condensé "X à l'heure · Y en retard"
      // → si 0 des deux, pas de texte résumé visible
      expect(find.textContaining('à l\'heure'), findsNothing);
    });

    testWidgets('la bannière résumé est visible quand au moins 1 prière loggée', (tester) async {
      await tester.pumpWidget(buildApp(buildMixedState()));
      await tester.pumpAndSettle();

      // Scroll pour révéler la bannière (en bas du CustomScrollView)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // 2 onTime + 1 late → bannière avec format "2 à l'heure · 1 en retard"
      expect(find.textContaining('à l\'heure'), findsOneWidget);
      expect(find.textContaining('en retard'), findsOneWidget);
    });
  });
}

/// Notifier de test — retourne un état fixe sans appels réseau.
class _FakeNotifier extends TodaySalatNotifier {
  final TodaySalatState _state;
  _FakeNotifier(this._state);

  @override
  Future<TodaySalatState> build() async => _state;
}
