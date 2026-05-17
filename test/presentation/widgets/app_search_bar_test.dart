import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_search_bar.dart';

/// Construit un widget isolé avec MaterialApp minimal.
Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppSearchBar — affichage', () {
    testWidgets('affiche le placeholder fourni', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppSearchBar(
            placeholder: 'Rechercher une habitude',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Rechercher une habitude'), findsOneWidget);
    });

    testWidgets('affiche l\'icône search à gauche', (tester) async {
      await tester.pumpWidget(
        _wrap(AppSearchBar(placeholder: 'Rechercher', onChanged: (_) {})),
      );

      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('fond bgInput', (tester) async {
      await tester.pumpWidget(
        _wrap(AppSearchBar(placeholder: 'Rechercher', onChanged: (_) {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppSearchBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.bgInput);
    });

    testWidgets('pas d\'icône clear quand la query est vide', (tester) async {
      await tester.pumpWidget(
        _wrap(AppSearchBar(placeholder: 'Rechercher', onChanged: (_) {})),
      );

      expect(find.byIcon(LucideIcons.x), findsNothing);
    });
  });

  group('AppSearchBar — interaction', () {
    testWidgets('appelle onChanged à la saisie', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        _wrap(AppSearchBar(placeholder: 'Rechercher', onChanged: values.add)),
      );

      await tester.enterText(find.byType(TextField), 'salat');
      expect(values, contains('salat'));
    });

    testWidgets('affiche l\'icône clear quand la query est non vide', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AppSearchBar(placeholder: 'Rechercher', onChanged: (_) {})),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('le tap sur clear vide le champ et notifie onChanged', (
      tester,
    ) async {
      final values = <String>[];
      await tester.pumpWidget(
        _wrap(AppSearchBar(placeholder: 'Rechercher', onChanged: values.add)),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(values.last, isEmpty);
    });

    testWidgets('le tap sur clear déclenche onClear si fourni', (tester) async {
      var cleared = 0;
      await tester.pumpWidget(
        _wrap(
          AppSearchBar(
            placeholder: 'Rechercher',
            onChanged: (_) {},
            onClear: () => cleared++,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(cleared, 1);
    });
  });
}
