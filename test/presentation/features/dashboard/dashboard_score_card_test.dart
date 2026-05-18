import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('DashboardScoreCard', () {
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

      expect(find.text('Série'), findsOneWidget);
      expect(find.text('7 j'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('#12'), findsOneWidget);
    });
  });
}
