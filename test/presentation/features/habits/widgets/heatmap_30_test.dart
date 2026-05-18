import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/heatmap_30.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

void main() {
  /// Construit une heatmap de 30 jours se terminant à [reference] avec le
  /// statut [status] appliqué uniquement au dernier jour.
  Map<DateTime, HabitLogStatus?> buildData(
    DateTime reference,
    HabitLogStatus? status,
  ) {
    final data = <DateTime, HabitLogStatus?>{};
    for (var i = 29; i >= 0; i--) {
      final day = reference.subtract(Duration(days: i));
      data[day] = i == 0 ? status : null;
    }
    return data;
  }

  Widget pumpable(Map<DateTime, HabitLogStatus?> data) {
    return MaterialApp(
      home: Scaffold(body: Heatmap30(heatmapData: data)),
    );
  }

  Color cellColor(WidgetTester tester, DateTime day) {
    final container = tester.widget<Container>(
      find.byKey(Key('heatmap_cell_${day.toIso8601String()}')),
    );
    final decoration = container.decoration! as BoxDecoration;
    return decoration.color!;
  }

  final reference = DateTime.utc(2026, 5, 17);

  testWidgets('rend exactement 30 cellules', (tester) async {
    await tester.pumpWidget(pumpable(buildData(reference, null)));
    expect(find.byKey(const Key('heatmap_cell')), findsNothing);
    final cells = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('heatmap_cell_'),
    );
    expect(cells, findsNWidgets(30));
  });

  testWidgets('cellule verte pour status onTime', (tester) async {
    await tester.pumpWidget(
      pumpable(buildData(reference, HabitLogStatus.onTime)),
    );
    expect(cellColor(tester, reference), AppColors.success);
  });

  testWidgets('cellule orange pour status late', (tester) async {
    await tester.pumpWidget(
      pumpable(buildData(reference, HabitLogStatus.late)),
    );
    expect(cellColor(tester, reference), AppColors.warning);
  });

  testWidgets('cellule rouge pour status missed', (tester) async {
    await tester.pumpWidget(
      pumpable(buildData(reference, HabitLogStatus.missed)),
    );
    expect(cellColor(tester, reference), AppColors.danger);
  });

  testWidgets('cellule grise pour status null', (tester) async {
    await tester.pumpWidget(pumpable(buildData(reference, null)));
    expect(cellColor(tester, reference), AppColors.bgInput);
  });

  testWidgets('affiche une légende avec 4 pastilles', (tester) async {
    await tester.pumpWidget(pumpable(buildData(reference, null)));
    expect(find.byKey(const Key('heatmap_legend')), findsOneWidget);
    expect(find.text('À temps'), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Manquée'), findsOneWidget);
    expect(find.text('Aucun log'), findsOneWidget);
  });
}
