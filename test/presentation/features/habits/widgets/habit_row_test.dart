import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_row.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

void main() {
  Habit makeHabit() => Habit(
    id: HabitId('h1'),
    userId: UserId('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
    name: NonEmptyString('Lecture Coran'),
    categoryId: CategoryId('cat-religion'),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: const {1, 2, 3, 4, 5, 6, 7},
    points: HabitPoints(5),
    isSystem: false,
  );

  Widget pumpable({
    HabitLogStatus? status,
    VoidCallback? onTap,
    VoidCallback? onToggle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HabitRow(
          habit: makeHabit(),
          todayStatus: status,
          onTap: onTap ?? () {},
          onToggle: onToggle ?? () {},
        ),
      ),
    );
  }

  Color checkmarkColor(WidgetTester tester) {
    final icon = tester.widget<Icon>(
      find.byKey(const Key('habit_row_checkmark_icon')),
    );
    return icon.color!;
  }

  testWidgets('affiche le nom et les points', (tester) async {
    await tester.pumpWidget(pumpable());
    expect(find.text('Lecture Coran'), findsOneWidget);
    expect(find.text('+5 pts'), findsOneWidget);
  });

  testWidgets('status null → checkmark gris', (tester) async {
    await tester.pumpWidget(pumpable());
    expect(checkmarkColor(tester), AppColors.textTertiary);
  });

  testWidgets('status onTime → checkmark vert', (tester) async {
    await tester.pumpWidget(pumpable(status: HabitLogStatus.onTime));
    expect(checkmarkColor(tester), AppColors.success);
    expect(
      tester
          .widget<Icon>(find.byKey(const Key('habit_row_checkmark_icon')))
          .icon,
      LucideIcons.circleCheck,
    );
  });

  testWidgets('status late → checkmark orange', (tester) async {
    await tester.pumpWidget(pumpable(status: HabitLogStatus.late));
    expect(checkmarkColor(tester), AppColors.warning);
  });

  testWidgets('status missed → checkmark rouge', (tester) async {
    await tester.pumpWidget(pumpable(status: HabitLogStatus.missed));
    expect(checkmarkColor(tester), AppColors.danger);
  });

  testWidgets('tap sur le checkmark déclenche onToggle', (tester) async {
    var toggled = false;
    var tapped = false;
    await tester.pumpWidget(
      pumpable(onToggle: () => toggled = true, onTap: () => tapped = true),
    );
    await tester.tap(find.byKey(const Key('habit_row_checkmark')));
    await tester.pump();
    expect(toggled, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('tap sur le reste de la ligne déclenche onTap', (tester) async {
    var toggled = false;
    var tapped = false;
    await tester.pumpWidget(
      pumpable(onToggle: () => toggled = true, onTap: () => tapped = true),
    );
    await tester.tap(find.text('Lecture Coran'));
    await tester.pump();
    expect(tapped, isTrue);
    expect(toggled, isFalse);
  });
}
