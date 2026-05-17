import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';

/// Tests widget pour AppDialog — composant DS D-25.
///
/// Cycle TDD : phase RED — tests écrits avant l'implémentation.
void main() {
  Widget wrapWithDialog({
    required String title,
    String? body,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDangerous = false,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AppDialog(
                title: title,
                body: body,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                onConfirm: onConfirm ?? () {},
                onCancel: onCancel ?? () {},
                isDangerous: isDangerous,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  // ---------------------------------------------------------------------------
  // Structure de base
  // ---------------------------------------------------------------------------
  group('AppDialog — structure', () {
    testWidgets('shows title', (tester) async {
      await tester.pumpWidget(wrapWithDialog(title: 'Se déconnecter ?'));
      await openDialog(tester);
      expect(find.text('Se déconnecter ?'), findsOneWidget);
    });

    testWidgets('shows body text when provided', (tester) async {
      await tester.pumpWidget(
        wrapWithDialog(
          title: 'Titre',
          body: 'Vous devrez vous reconnecter.',
        ),
      );
      await openDialog(tester);
      expect(find.text('Vous devrez vous reconnecter.'), findsOneWidget);
    });

    testWidgets('does not crash when body is null', (tester) async {
      await tester.pumpWidget(wrapWithDialog(title: 'Titre'));
      await openDialog(tester);
      expect(find.text('Titre'), findsOneWidget);
    });

    testWidgets('shows confirmLabel and cancelLabel buttons', (tester) async {
      await tester.pumpWidget(
        wrapWithDialog(
          title: 'Titre',
          confirmLabel: 'Oui',
          cancelLabel: 'Non',
        ),
      );
      await openDialog(tester);
      expect(find.text('Oui'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------
  group('AppDialog — callbacks', () {
    testWidgets('calls onConfirm when confirm button tapped', (tester) async {
      var confirmed = false;
      await tester.pumpWidget(
        wrapWithDialog(
          title: 'Titre',
          confirmLabel: 'Confirmer',
          onConfirm: () => confirmed = true,
        ),
      );
      await openDialog(tester);
      await tester.tap(find.text('Confirmer'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('calls onCancel when cancel button tapped', (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        wrapWithDialog(
          title: 'Titre',
          cancelLabel: 'Annuler',
          onCancel: () => cancelled = true,
        ),
      );
      await openDialog(tester);
      await tester.tap(find.text('Annuler'));
      await tester.pump();
      expect(cancelled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Mode isDangerous
  // ---------------------------------------------------------------------------
  group('AppDialog — isDangerous', () {
    testWidgets(
      'confirm button text color is AppColors.danger when isDangerous=true',
      (tester) async {
        await tester.pumpWidget(
          wrapWithDialog(
            title: 'Supprimer ?',
            confirmLabel: 'Supprimer',
            isDangerous: true,
          ),
        );
        await openDialog(tester);

        // Cherche un Text 'Supprimer' dont la couleur effective est danger.
        final textWidgets = tester
            .widgetList<Text>(find.text('Supprimer'))
            .toList();
        final dangerText = textWidgets.any(
          (t) => t.style?.color == AppColors.danger,
        );
        expect(
          dangerText,
          isTrue,
          reason:
              'Le label de confirmation doit être rouge (danger) en mode isDangerous',
        );
      },
    );

    testWidgets(
      'confirm button text color is NOT danger when isDangerous=false',
      (tester) async {
        await tester.pumpWidget(
          wrapWithDialog(
            title: 'Confirmer ?',
            confirmLabel: 'Confirmer',
          ),
        );
        await openDialog(tester);

        final textWidgets = tester
            .widgetList<Text>(find.text('Confirmer'))
            .toList();
        final dangerText = textWidgets.any(
          (t) => t.style?.color == AppColors.danger,
        );
        expect(dangerText, isFalse);
      },
    );
  });
}
