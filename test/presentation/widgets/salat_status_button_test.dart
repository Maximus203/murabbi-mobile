import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/salat_status_button.dart';

/// Construit un widget isolé avec MaterialApp minimal.
Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('SalatStatus enum', () {
    test('contient exactement 4 valeurs', () {
      expect(SalatStatus.values.length, 4);
      expect(
        SalatStatus.values,
        containsAll([
          SalatStatus.pending,
          SalatStatus.onTime,
          SalatStatus.late,
          SalatStatus.missed,
        ]),
      );
    });
  });

  group('SalatStatusButton — affichage par statut', () {
    testWidgets('pending — affiche l\'icône clock + label "Non priée"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SalatStatusButton(status: SalatStatus.pending, onCycleNext: () {}),
        ),
      );

      expect(find.byIcon(lu(LucideIcons.clock)), findsOneWidget);
      expect(find.text('Non priée'), findsOneWidget);

      // Vérifie la couleur de l'icône
      final icon = tester.widget<Icon>(find.byIcon(lu(LucideIcons.clock)));
      expect(icon.color, AppColors.textSecondary);
    });

    testWidgets('onTime — affiche l\'icône circleCheck + label "À l\'heure"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SalatStatusButton(status: SalatStatus.onTime, onCycleNext: () {}),
        ),
      );

      expect(find.byIcon(lu(LucideIcons.circleCheck)), findsOneWidget);
      expect(find.text('À l\'heure'), findsOneWidget);

      final icon = tester.widget<Icon>(
        find.byIcon(lu(LucideIcons.circleCheck)),
      );
      expect(icon.color, AppColors.success);
    });

    testWidgets('late — affiche l\'icône alertCircle + label "En retard"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SalatStatusButton(status: SalatStatus.late, onCycleNext: () {})),
      );

      expect(find.byIcon(lu(LucideIcons.triangleAlert)), findsOneWidget);
      expect(find.text('En retard'), findsOneWidget);

      final icon = tester.widget<Icon>(
        find.byIcon(lu(LucideIcons.triangleAlert)),
      );
      expect(icon.color, AppColors.warning);
    });

    testWidgets('missed — affiche l\'icône xCircle + label "Manquée"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SalatStatusButton(status: SalatStatus.missed, onCycleNext: () {}),
        ),
      );

      expect(find.byIcon(lu(LucideIcons.circleX)), findsOneWidget);
      expect(find.text('Manquée'), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(lu(LucideIcons.circleX)));
      expect(icon.color, AppColors.danger);
    });
  });

  group('SalatStatusButton — cycle onCycleNext', () {
    testWidgets('appelle onCycleNext au tap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          SalatStatusButton(
            status: SalatStatus.pending,
            onCycleNext: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.byType(SalatStatusButton));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('tap multiple fois — onCycleNext appelé à chaque fois', (
      tester,
    ) async {
      var count = 0;
      await tester.pumpWidget(
        _wrap(
          SalatStatusButton(
            status: SalatStatus.onTime,
            onCycleNext: () => count++,
          ),
        ),
      );

      await tester.tap(find.byType(SalatStatusButton));
      await tester.pump();
      await tester.tap(find.byType(SalatStatusButton));
      await tester.pump();

      expect(count, 2);
    });
  });

  group('SalatStatusButton — accessibilité', () {
    testWidgets('hauteur minimale >= kMinInteractiveDimension', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SalatStatusButton(status: SalatStatus.pending, onCycleNext: () {}),
        ),
      );

      final size = tester.getSize(find.byType(SalatStatusButton));
      expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    });
  });
}
