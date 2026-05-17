import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/google_sign_in_button.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('#119 — renders styled button with text and tappable surface', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(host(GoogleSignInButton(onPressed: () => taps++)));

    expect(find.text('Continuer avec Google'), findsOneWidget);
    // Le glyphe « G » est dessiné via CustomPaint (pas un texte brut).
    expect(find.byType(CustomPaint), findsWidgets);
    // Bordure / surface : un Material entoure le contenu.
    expect(find.byType(InkWell), findsOneWidget);

    await tester.tap(find.text('Continuer avec Google'));
    expect(taps, 1);
  });

  testWidgets('#119 — disabled state does not trigger onPressed', (
    tester,
  ) async {
    await tester.pumpWidget(host(const GoogleSignInButton(onPressed: null)));

    await tester.tap(find.text('Continuer avec Google'));
    // Aucun callback : le bouton est inerte (onPressed null).
    expect(tester.takeException(), isNull);
  });

  testWidgets('#119 — exposes button semantics for screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(host(GoogleSignInButton(onPressed: () {})));

    final semantics = tester.getSemantics(find.text('Continuer avec Google'));
    expect(semantics.label, contains('Continuer avec Google'));
  });
}
