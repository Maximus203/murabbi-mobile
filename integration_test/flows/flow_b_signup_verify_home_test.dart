import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murabbi_mobile/presentation/app.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_02_signup_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_screen.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

import '../helpers/fakes.dart';

/// Flow B — *SignUp → email verification → home* :
///
/// Utilisateur déjà onboardé (le flag est posé dans le storage de test) qui
/// crée un compte. Après submit :
///   1. AU-02 → `signUp` réussit, redirection vers `/auth/verify-email`.
///   2. L'écran AU-04 démarre un `Timer.periodic(5s)` qui invalide le
///      provider auth. À chaque invalidation, `getCurrentUser` est rappelé.
///   3. Le fake retourne le même user "non vérifié" jusqu'au Nᵉ appel ;
///      après il renvoie le même user (simulant Supabase qui flip
///      `email_confirmed_at`). Comme le state utilisateur reste non null
///      tout du long, le routeur ne déplace pas l'utilisateur tant que
///      l'on est sur /auth/verify-email (toujours autorisé).
///   4. L'utilisateur tap "J'ai vérifié mon email" → on `invalidate(auth)`
///      et on `go('/home')` — l'app affiche le placeholder home.
///
/// Décision senior à valider par Cherif : ce flow s'arrête quand
/// l'utilisateur tap manuellement "J'ai vérifié mon email" parce que la
/// redirection auto sur confirmation Supabase passe par un deep-link non
/// scopé en Phase 2 (cf. `PHASE_2_VALIDATION.md`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow B — signUp → /auth/verify-email → /home', (tester) async {
    final auth = FakeAuthRepository(emailConfirmsAfterNthGetCurrent: 2);
    addTearDown(auth.dispose);
    final onboarding = FakeOnboardingFlagStorage(completed: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(auth: auth, onboarding: onboarding),
        child: const MurabbiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Pas de session → AU-01 par défaut. Tap "Créer un compte".
    await tester.tap(find.text('Créer un compte').last);
    await tester.pumpAndSettle();
    expect(find.byType(Au02SignupScreen), findsOneWidget);

    // Saisie email + password puis submit.
    await tester.enterText(find.byType(TextField).at(0), 'cherif@murabbi.test');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(AppButton, 'Créer mon compte'));
    await tester.pumpAndSettle();

    // SignUp ok → AU-04 (email verification gate).
    expect(find.byType(Au04EmailVerificationScreen), findsOneWidget);
    expect(find.text('cherif@murabbi.test'), findsOneWidget);

    // Tap "J'ai vérifié mon email" — déclenche le flux invalidate→home.
    await tester.tap(find.widgetWithText(AppButton, 'J\'ai vérifié mon email'));
    await tester.pumpAndSettle();

    // L'app arrive sur le placeholder home (titre Murabbi + pseudo
    // "Anonyme" généré côté fake).
    expect(find.text('Murabbi'), findsOneWidget);
    expect(find.textContaining('Anonyme'), findsOneWidget);
    expect(find.byType(Au04EmailVerificationScreen), findsNothing);
  });
}
