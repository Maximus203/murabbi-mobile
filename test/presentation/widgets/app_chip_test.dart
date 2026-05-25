import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';

/// Construit un widget isolé avec MaterialApp minimal.
Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppChip — état inactif (selected = false)', () {
    testWidgets('affiche le label', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Tout', selected: false, onTap: () {})),
      );

      expect(find.text('Tout'), findsOneWidget);
    });

    testWidgets('fond bgInput quand non sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Tout', selected: false, onTap: () {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.bgInput);
    });

    testWidgets('bordure borderDefault quand non sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Tout', selected: false, onTap: () {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.borderDefault);
    });
  });

  group('AppChip — état actif (selected = true)', () {
    testWidgets('affiche le label', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Religion', selected: true, onTap: () {})),
      );

      expect(find.text('Religion'), findsOneWidget);
    });

    testWidgets('fond accent teinté quand sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Religion', selected: true, onTap: () {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      // fond = accent avec alpha 0.15
      expect(decoration.color, AppColors.accent.withValues(alpha: 0.15));
    });

    testWidgets('bordure accent quand sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Religion', selected: true, onTap: () {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.accent);
    });
  });

  group('AppChip — interaction', () {
    testWidgets('appelle onTap au tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Sport', selected: false, onTap: () => tapped++)),
      );

      await tester.tap(find.byType(AppChip));
      await tester.pump();

      expect(tapped, 1);
    });
  });

  group('AppChip — hauteur', () {
    testWidgets('hauteur == 32px', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Santé', selected: false, onTap: () {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxHeight, 32);
    });
  });

  group('AppChip — widget leading optionnel', () {
    testWidgets('affiche un widget leading si fourni', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppChip(
            label: 'Religion',
            selected: false,
            onTap: () {},
            leading: const Icon(LucideIcons.star, size: 12),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.star), findsOneWidget);
      expect(find.text('Religion'), findsOneWidget);
    });

    testWidgets('n\'affiche pas de leading si absent', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Tout', selected: false, onTap: () {})),
      );

      // Pas d'icône star
      expect(find.byIcon(LucideIcons.star), findsNothing);
    });
  });

  group('AppChip — border radius pill', () {
    testWidgets('border radius est AppRadius.pill (100)', (tester) async {
      await tester.pumpWidget(
        _wrap(AppChip(label: 'Tout', selected: false, onTap: () {})),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.pill));
    });
  });
}
