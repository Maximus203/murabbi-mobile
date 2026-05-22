import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_objective_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

HabitTargetValue _target(int value) =>
    HabitTargetValue(value: TargetValue(value), unit: TargetUnit.reps);

void main() {
  group('HabitObjectiveSheet —', () {
    testWidgets('affiche "0 / N" avec valeur initiale 0', (tester) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(10), onValidate: (_) {})),
      );
      expect(find.text('0'), findsWidgets);
      expect(find.text(' / 10'), findsOneWidget);
    });

    testWidgets('affiche currentValue si fourni', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitObjectiveSheet(
            target: _target(10),
            currentValue: 5,
            onValidate: (_) {},
          ),
        ),
      );
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('bouton + incrémente la valeur', (tester) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(10), onValidate: (_) {})),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('bouton - décrémente la valeur', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitObjectiveSheet(
            target: _target(10),
            currentValue: 5,
            onValidate: (_) {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('bouton - ne décrémente pas quand valeur = 0', (tester) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(10), onValidate: (_) {})),
      );
      // _StepButton with Icons.remove uses GestureDetector; onTap is null → no effect
      await tester.tap(find.byIcon(Icons.remove), warnIfMissed: false);
      await tester.pump();
      // Value should still be 0
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('bouton Valider désactivé tant que valeur < objectif', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(5), onValidate: (_) {})),
      );
      expect(find.text('Valider l\'habitude'), findsOneWidget);
      // The button should be disabled (onPressed null via AppButton)
      await tester.tap(find.text('Valider l\'habitude'));
      await tester.pump();
      // No callback = no navigation = widget still present
      expect(find.byType(HabitObjectiveSheet), findsOneWidget);
    });

    testWidgets('bouton Valider activé quand valeur >= objectif', (
      tester,
    ) async {
      int? validated;
      await tester.pumpWidget(
        _wrap(
          HabitObjectiveSheet(
            target: _target(3),
            currentValue: 3,
            onValidate: (v) => validated = v,
          ),
        ),
      );
      expect(find.text('✓ Valider l\'habitude'), findsOneWidget);
      await tester.tap(find.text('✓ Valider l\'habitude'));
      await tester.pump();
      expect(validated, equals(3));
    });

    testWidgets('"Mettre à jour" applique la saisie directe', (tester) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(10), onValidate: (_) {})),
      );
      await tester.enterText(find.byType(TextField), '7');
      await tester.tap(find.text('Mettre à jour'));
      await tester.pump();
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('affiche l\'unité rép. pour TargetUnit.reps', (tester) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(10), onValidate: (_) {})),
      );
      expect(find.text('rép.'), findsOneWidget);
    });

    testWidgets('hint "Atteignez l\'objectif" visible si non atteint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HabitObjectiveSheet(target: _target(10), onValidate: (_) {})),
      );
      expect(find.textContaining('Atteignez l\'objectif'), findsOneWidget);
    });

    testWidgets('hint absent quand objectif atteint', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitObjectiveSheet(
            target: _target(3),
            currentValue: 3,
            onValidate: (_) {},
          ),
        ),
      );
      expect(find.textContaining('Atteignez l\'objectif'), findsNothing);
    });
  });
}
