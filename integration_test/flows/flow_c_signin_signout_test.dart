import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murabbi_mobile/presentation/app.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

import '../helpers/fakes.dart';

/// Flow C — *SignIn direct + signOut* :
///
/// Utilisateur onboardé (flag posé) avec un compte déjà existant. Saisit ses
/// credentials sur AU-01 → arrive sur /home → tap "Se déconnecter" → revient
/// sur AU-01.
///
/// Décision senior à valider par Cherif : on assert le `signOut` ici parce
/// qu'il complète la boucle d'auth (sinon impossible de re-tester un autre
/// scénario sur l'app live, et c'est la seule action mutante exposée sur
/// le placeholder home).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow C — signIn → /home → signOut → /auth/login', (tester) async {
    final auth = FakeAuthRepository(
      seededEmail: 'cherif@murabbi.test',
      seededPassword: 'password123',
    );
    addTearDown(auth.dispose);
    final onboarding = FakeOnboardingFlagStorage(completed: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(auth: auth, onboarding: onboarding),
        child: const MurabbiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Pas de session → AU-01.
    expect(find.byType(Au01LoginScreen), findsOneWidget);

    // Saisie credentials valides + submit.
    await tester.enterText(
      find.byType(TextField).at(0),
      'cherif@murabbi.test',
    );
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(AppButton, 'Se connecter'));
    await tester.pumpAndSettle();

    // /home placeholder affiché.
    expect(find.text('Murabbi'), findsOneWidget);
    expect(find.textContaining('Cherif'), findsOneWidget);

    // SignOut → retour AU-01.
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.byType(Au01LoginScreen), findsOneWidget);
  });
}
