import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/gamification/screens/level_up_screen.dart';

void main() {
  testWidgets('LevelUpScreen affiche le nom de niveau', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpScreen(
          levelName: 'Constant',
          onContinue: () {},
        ),
      ),
    );
    // pump() sans pumpAndSettle — la vidéo de fond ne se "stabilise" jamais.
    await tester.pump();
    expect(find.text('Constant'), findsOneWidget);
    expect(find.text('NIVEAU ATTEINT'), findsOneWidget);
  });

  testWidgets('LevelUpScreen appelle onContinue au tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpScreen(
          levelName: 'Aspirant',
          onContinue: () => tapped = true,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Continuer'));
    expect(tapped, isTrue);
  });
}
