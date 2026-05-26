import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_stats_grid.dart';

/// Tests widget de [DashboardStatsGrid] pour le sous-label de mouvement de rang
/// (issue #199, Q-F, feat/dashboard-rank-movement).
///
/// [DashboardStatsGrid] est un widget pur (StatelessWidget) sans provider —
/// les tests instancient directement le widget avec les paramètres voulus.
///
/// Couverture :
///   - rankSubLabel null        → tuile CLASSEMENT sans texte de mouvement
///   - rankSubLabel '↗ N places' → texte rendu (progression)
///   - rankSubLabel '↘ N places' → texte rendu (régression)
///   - singulier vs pluriel     → 1 place / 2 places
void main() {
  Widget buildGrid({String? rankSubLabel}) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardStatsGrid(
            streakDays: 7,
            salatLabel: '3/5',
            habitsLabel: '4/6',
            weeklyRank: 3,
            rankSubLabel: rankSubLabel,
          ),
        ),
      ),
    );
  }

  group('DashboardStatsGrid — rankSubLabel', () {
    testWidgets('rankSubLabel null → pas de texte de mouvement visible', (
      tester,
    ) async {
      await tester.pumpWidget(buildGrid());

      // Le widget rend toujours un Text vide (transparent) pour conserver la
      // hauteur de tuile — on vérifie qu'aucune flèche n'est affichée.
      expect(find.text('↗ 3 places'), findsNothing);
      expect(find.text('↘ 3 places'), findsNothing);
      // La valeur du rang reste présente (#3).
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('rankSubLabel "↗ 3 places" → texte progression rendu', (
      tester,
    ) async {
      await tester.pumpWidget(buildGrid(rankSubLabel: '↗ 3 places'));

      expect(find.text('↗ 3 places'), findsOneWidget);
    });

    testWidgets('rankSubLabel "↘ 2 places" → texte régression rendu', (
      tester,
    ) async {
      await tester.pumpWidget(buildGrid(rankSubLabel: '↘ 2 places'));

      expect(find.text('↘ 2 places'), findsOneWidget);
    });

    testWidgets('singulier "↗ 1 place" → accordé au singulier', (tester) async {
      await tester.pumpWidget(buildGrid(rankSubLabel: '↗ 1 place'));

      expect(find.text('↗ 1 place'), findsOneWidget);
      // Pluriel absent.
      expect(find.text('↗ 1 places'), findsNothing);
    });

    testWidgets('semaine nulle rankSubLabel="" → aucune flèche', (
      tester,
    ) async {
      // rankMovement = 0 → ni progression ni régression → _StatsCard passe null.
      await tester.pumpWidget(buildGrid());

      expect(find.textContaining('↗'), findsNothing);
      expect(find.textContaining('↘'), findsNothing);
    });
  });
}
