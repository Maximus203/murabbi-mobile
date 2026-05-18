import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';
import 'package:murabbi_mobile/presentation/widgets/app_filter_chips.dart';

/// Construit un widget isolé avec MaterialApp minimal.
Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppFilterChips — affichage', () {
    testWidgets('affiche un chip par label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppFilterChips(
            labels: const ['Toutes', 'Actives', 'Inactives'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(AppChip), findsNWidgets(3));
      expect(find.text('Toutes'), findsOneWidget);
      expect(find.text('Actives'), findsOneWidget);
      expect(find.text('Inactives'), findsOneWidget);
    });

    testWidgets('marque le chip d\'index sélectionné comme selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AppFilterChips(
            labels: const ['A', 'B', 'C'],
            selectedIndex: 1,
            onChanged: (_) {},
          ),
        ),
      );

      final chips = tester.widgetList<AppChip>(find.byType(AppChip)).toList();
      expect(chips[0].selected, isFalse);
      expect(chips[1].selected, isTrue);
      expect(chips[2].selected, isFalse);
    });
  });

  group('AppFilterChips — interaction', () {
    testWidgets('appelle onChanged avec l\'index tappé', (tester) async {
      int? changed;
      await tester.pumpWidget(
        _wrap(
          AppFilterChips(
            labels: const ['A', 'B', 'C'],
            selectedIndex: 0,
            onChanged: (i) => changed = i,
          ),
        ),
      );

      await tester.tap(find.text('C'));
      await tester.pump();

      expect(changed, 2);
    });
  });
}
