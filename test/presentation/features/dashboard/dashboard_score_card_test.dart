import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_score_card.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_stats_grid.dart';

UserScore _score({
  int total = 5000,
  Level level = Level.aspirant,
  int rank = 4,
}) => UserScore(
  userId: UserId('u-1'),
  totalPoints: total,
  weeklyPoints: 100,
  currentLevel: level,
  weeklyRank: rank,
);

DailySummary _summary({
  double rate = 60.0,
  int habitPts = 18,
}) => DailySummary(
  userId: UserId('u-1'),
  day: DateTime(2026, 5, 25),
  completionRate: rate,
  streakValid: false,
  habitPointsToday: habitPts,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DashboardScoreCard — sans dailySummary (comportement existant)', () {
    testWidgets('affiche le niveau, les points et le pourcentage', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(DashboardScoreCard(score: _score(total: 5000))),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Aspirant'), findsOneWidget);
      expect(find.text('5000 pts'), findsOneWidget);
      // aspirant 0 → murid 10000 : 5000 ⇒ 50%
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Prochain palier : Murīd'), findsOneWidget);
    });

    testWidgets('affiche "Niveau maximal atteint" pour Murabbī', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DashboardScoreCard(
            score: _score(total: 400000, level: Level.murabbi),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Niveau maximal atteint'), findsOneWidget);
    });
  });

  group('DashboardScoreCard — avec dailySummary', () {
    testWidgets('affiche habitPointsToday et objectif du niveau', (
      tester,
    ) async {
      // aspirant dailyGoal = 30
      await tester.pumpWidget(
        _wrap(
          DashboardScoreCard(
            score: _score(total: 5000, level: Level.aspirant),
            dailySummary: _summary(habitPts: 18),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('18 / 30 pts'), findsOneWidget);
      expect(find.text('Score du jour · objectif 30 pts'), findsOneWidget);
    });

    testWidgets('affiche le pourcentage de complétion dans l\'anneau', (
      tester,
    ) async {
      // completionRate = 60.0 → affiche 60%
      await tester.pumpWidget(
        _wrap(
          DashboardScoreCard(
            score: _score(),
            dailySummary: _summary(rate: 60.0),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('n\'affiche pas "Prochain palier" quand dailySummary présent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DashboardScoreCard(
            score: _score(total: 5000),
            dailySummary: _summary(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Prochain palier'), findsNothing);
    });
  });

  group('DashboardStatsGrid', () {
    testWidgets('affiche les 4 tuiles de stats', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardStatsGrid(
            streakDays: 7,
            salatLabel: '3/5',
            habitsLabel: '2/4',
            weeklyRank: 12,
          ),
        ),
      );

      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('7 j'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('#12'), findsOneWidget);
    });

    testWidgets('affiche le sous-label habitudes quand fourni', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardStatsGrid(
            streakDays: 3,
            salatLabel: '5/5',
            habitsLabel: '4/5',
            weeklyRank: 2,
            habitsSubLabel: '80% · +24 pts',
          ),
        ),
      );

      expect(find.text('80% · +24 pts'), findsOneWidget);
    });

    testWidgets('affiche le mouvement de rang positif', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardStatsGrid(
            streakDays: 5,
            salatLabel: '4/5',
            habitsLabel: '3/4',
            weeklyRank: 3,
            rankSubLabel: '↗ 2 places',
          ),
        ),
      );

      expect(find.text('↗ 2 places'), findsOneWidget);
    });

    testWidgets('masque le sous-label classement quand null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardStatsGrid(
            streakDays: 1,
            salatLabel: '1/5',
            habitsLabel: '1/3',
            weeklyRank: 10,
          ),
        ),
      );

      expect(find.textContaining('places'), findsNothing);
    });

    testWidgets('affiche le sous-label salat "à l\'heure" quand fourni', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardStatsGrid(
            streakDays: 2,
            salatLabel: '5/5',
            habitsLabel: '2/2',
            weeklyRank: 1,
            salatSubLabel: 'à l\'heure',
          ),
        ),
      );

      expect(find.text("à l'heure"), findsOneWidget);
    });
  });
}
