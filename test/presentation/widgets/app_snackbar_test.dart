import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_snackbar.dart';

/// Tests de régression #146 — les SnackBars de l'app doivent utiliser les
/// couleurs du design system, pas le thème dark Material par défaut.
void main() {
  Widget host(void Function(BuildContext) onTap) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onTap(context),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('showAppSnackBar affiche le message fourni', (tester) async {
    await tester.pumpWidget(
      host((ctx) => showAppSnackBar(ctx, 'Collections arrive bientôt.')),
    );
    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.text('Collections arrive bientôt.'), findsOneWidget);
  });

  testWidgets('showAppSnackBar utilise le fond thémé de l\'app', (
    tester,
  ) async {
    await tester.pumpWidget(host((ctx) => showAppSnackBar(ctx, 'Hello')));
    await tester.tap(find.text('show'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppColors.textPrimary);
  });
}
