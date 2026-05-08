import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murabbi_mobile/presentation/app.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';

import '../helpers/fakes.dart';

/// Flow A — *Onboarding-first pre-auth* (Q3-A) :
///
/// Utilisateur visiteur (sans session) qui n'a jamais ouvert l'app
/// (onboarding_seen=false). Au démarrage :
///   1. Le splash s'efface dès que les deux notifiers résolvent.
///   2. La redirection globale pousse vers `/onboarding` (walkthrough
///      pédagogique pre-auth).
///   3. L'utilisateur tape "Passer" — le flag `onboarding_seen` est
///      posé puis le routeur redirige vers `/auth/login` (visiteur sans
///      session, onboarding désormais vu).
///
/// Variante : si le flag est déjà posé (relance après onboarding vu),
/// le visiteur arrive directement sur `/auth/login`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Flow A — visiteur non onboardé voit /onboarding puis /auth/login après "Passer"',
    (tester) async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final onboarding = FakeOnboardingFlagStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(auth: auth, onboarding: onboarding),
          child: const MurabbiApp(),
        ),
      );

      // Laisse le router résoudre auth + onboarding et naviguer.
      await tester.pumpAndSettle();

      // Visiteur + onboarding pas vu → SETUP-01 (Q3-A).
      expect(find.byType(Setup01OnboardingScreen), findsOneWidget);

      // Tap "Passer" — pose le flag onboarding_seen + redirige
      // vers /auth/login (visiteur, plus de session).
      final skip = find.text('Passer');
      expect(skip, findsOneWidget);
      await tester.tap(skip);
      await tester.pumpAndSettle();

      // Visiteur + onboarding vu → /auth/login.
      expect(find.byType(Au01LoginScreen), findsOneWidget);
      expect(find.byType(Setup01OnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'Flow A bis — visiteur déjà onboardé arrive directement sur /auth/login',
    (tester) async {
      final auth = FakeAuthRepository();
      addTearDown(auth.dispose);
      final onboarding = FakeOnboardingFlagStorage(completed: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(auth: auth, onboarding: onboarding),
          child: const MurabbiApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Au01LoginScreen), findsOneWidget);
      expect(find.byType(Setup01OnboardingScreen), findsNothing);
    },
  );
}
