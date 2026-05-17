import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/leader_row.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/podium_col.dart';

UserScore _score({int rank = 1, int weekly = 120, int total = 5000}) =>
    UserScore(
      userId: UserId('user-$rank'),
      totalPoints: total,
      weeklyPoints: weekly,
      currentLevel: Level.fromPoints(total),
      weeklyRank: rank,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PodiumCol', () {
    testWidgets('affiche rang, score et initiales', (tester) async {
      await tester.pumpWidget(
        _wrap(PodiumCol(score: _score(rank: 1, weekly: 240), initials: 'AB')),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('240 pts'), findsOneWidget);
      expect(find.text('AB'), findsOneWidget);
    });
  });

  group('LeaderRow', () {
    testWidgets('affiche rang, niveau et score hebdo', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaderRow(
            score: _score(rank: 5, weekly: 80, total: 12000),
            initials: 'CD',
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('80 pts'), findsOneWidget);
      expect(find.text('Murīd'), findsOneWidget); // 12000 ≥ 10000
      expect(find.text('CD'), findsOneWidget);
    });

    testWidgets('met en évidence l\'utilisateur courant', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaderRow(
            score: _score(rank: 8),
            initials: 'EF',
            isCurrentUser: true,
          ),
        ),
      );

      // La ligne reste rendue sans erreur avec le flag courant.
      expect(find.byType(LeaderRow), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });
}
