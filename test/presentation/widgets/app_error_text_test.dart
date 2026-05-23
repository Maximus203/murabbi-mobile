import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/app_error_text.dart';

void main() {
  group('AppErrorText (#201, M9)', () {
    testWidgets('rend le message FR mappé depuis le Failure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorText(ScoreFailure.network())),
        ),
      );

      expect(
        find.text('Impossible de charger le score. Vérifie ta connexion.'),
        findsOneWidget,
      );
    });

    testWidgets('applique la couleur danger du design system', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppErrorText(ScoreFailure.notFound())),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, AppColors.danger);
    });

    testWidgets('Failure inconnu → fallback générique', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: AppErrorText(Exception('boom')))),
      );

      expect(find.text('Une erreur inattendue est survenue.'), findsOneWidget);
    });
  });
}
