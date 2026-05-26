import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/leader_row.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/podium_col.dart';

UserScore _score({
  int rank = 1,
  int weekly = 120,
  int total = 5000,
  String pseudo = 'Aicha',
}) => UserScore(
      userId: UserId('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa0$rank'),
      totalPoints: total,
      weeklyPoints: weekly,
      currentLevel: Level.fromPoints(total),
      weeklyRank: rank,
      pseudo: pseudo,
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PodiumCol', () {
    testWidgets('affiche le rang dans le socle', (tester) async {
      await tester.pumpWidget(
        _wrap(PodiumCol(score: _score(rank: 1, weekly: 312), name: 'Aicha')),
      );
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('affiche le score en nombre brut sans "pts"', (tester) async {
      await tester.pumpWidget(
        _wrap(PodiumCol(score: _score(rank: 2, weekly: 284), name: 'Yacine')),
      );
      expect(find.text('284'), findsOneWidget);
      expect(find.text('284 pts'), findsNothing);
    });

    testWidgets('affiche le nom complet sous l\'avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(PodiumCol(score: _score(rank: 3, weekly: 261), name: 'Omar')),
      );
      expect(find.text('Omar'), findsOneWidget);
    });

    testWidgets('affiche l\'initiale du nom dans l\'avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(PodiumCol(score: _score(rank: 1, weekly: 312), name: 'Aicha')),
      );
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('LeaderRow', () {
    testWidgets('affiche le rang préfixé d\'un dièse', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaderRow(
            score: _score(rank: 5, weekly: 231, total: 12000, pseudo: 'Ibrahim'),
            name: 'Ibrahim',
          ),
        ),
      );
      expect(find.text('#5'), findsOneWidget);
    });

    testWidgets('affiche le nom et non le niveau', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaderRow(
            score: _score(rank: 5, weekly: 231, total: 12000, pseudo: 'Ibrahim'),
            name: 'Ibrahim',
          ),
        ),
      );
      expect(find.text('Ibrahim'), findsOneWidget);
      expect(find.text('Murīd'), findsNothing);
    });

    testWidgets('affiche le score en nombre brut sans "pts"', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaderRow(
            score: _score(rank: 4, weekly: 248, total: 8000, pseudo: 'Khadija'),
            name: 'Khadija',
          ),
        ),
      );
      expect(find.text('248'), findsOneWidget);
      expect(find.text('248 pts'), findsNothing);
    });

    testWidgets('met en évidence l\'utilisateur courant', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LeaderRow(
            score: _score(rank: 7, pseudo: 'Cherif'),
            name: 'Cherif',
            isCurrentUser: true,
          ),
        ),
      );
      expect(find.text('#7'), findsOneWidget);
      expect(find.byType(LeaderRow), findsOneWidget);
    });
  });
}
