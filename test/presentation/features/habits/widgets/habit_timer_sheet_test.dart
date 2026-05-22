import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_timer_sheet.dart';

Habit _makeHabit({String name = 'Lecture Coran'}) => Habit(
  id: HabitId('h1'),
  name: NonEmptyString(name),
  categoryId: CategoryId('cat-religion'),
  frequencyType: HabitFrequencyType.daily,
  frequency: 1,
  activeDays: const {1, 2, 3, 4, 5, 6, 7},
  points: HabitPoints(5),
  isSystem: false,
  target: HabitTarget.timed(value: TargetValue(15), unit: TargetUnit.minutes),
);

HabitTargetTimed _timedTarget() =>
    HabitTargetTimed(value: TargetValue(15), unit: TargetUnit.minutes);

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('HabitTimerSheet —', () {
    testWidgets('affiche le nom de l\'habitude', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Lecture Coran'), findsOneWidget);
    });

    testWidgets('affiche le sous-titre avec durée cible', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('min'), findsWidgets);
    });

    testWidgets('variante A.1 : bouton play visible en état initial', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets(
      'variante A.1 : lien "valider sans timer" visible et appelle onValidate(zero)',
      (tester) async {
        Duration? validated;
        await tester.pumpWidget(
          _wrap(
            HabitTimerSheet(
              habit: _makeHabit(),
              target: _timedTarget(),
              onValidate: (d) => validated = d,
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('valider sans démarrer'), findsOneWidget);
        await tester.tap(find.textContaining('valider sans démarrer'));
        await tester.pump();
        expect(validated, equals(Duration.zero));
      },
    );

    testWidgets('bouton Fermer (×) est présent', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('affiche "✓ Valider l\'habitude" dans A.1 (état initial)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      // _PrimaryButton en état initial affiche ce label
      expect(find.textContaining('Valider l\'habitude'), findsWidgets);
    });

    testWidgets('tap play passe en état running (icône pause visible)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('affiche le cercle de progression', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HabitTimerSheet(
            habit: _makeHabit(),
            target: _timedTarget(),
            onValidate: (_) {},
          ),
        ),
      );
      await tester.pump();
      // _TimerCircle uses CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
