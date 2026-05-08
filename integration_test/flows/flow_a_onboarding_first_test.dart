import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:murabbi_mobile/presentation/app.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';

import '../helpers/fakes.dart';

/// Flow A — *Onboarding-first* :
///
/// Utilisateur qui n'a jamais ouvert l'app (non onboardé) **et** non
/// authentifié. Au démarrage :
///   1. Le splash s'efface dès que les deux notifiers résolvent.
///   2. Comme l'utilisateur n'est pas connecté → la redirection globale
///      pousse vers `/auth/login`.
///   3. Note senior : l'onboarding est **gated** par l'auth (cf.
///      `auth_redirect.dart` — un user non connecté est toujours envoyé
///      sur `/auth/login`, jamais sur `/onboarding`). Donc dans le flow A
///      "fresh install", l'utilisateur passe d'abord par /login (ou
///      /signup) puis seulement après auth, l'onboarding est proposé.
///
/// Ce flow couvre donc le post-signup : l'utilisateur fraîchement créé
/// (et qui aurait validé son email) est non onboardé → /onboarding s'affiche
/// → "Passer" marque le flag → l'app redirige vers /home.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow A — onboarding skip envoie sur /home', (tester) async {
    final auth = FakeAuthRepository(
      initialUser: FakeAuthRepository.makeUser(pseudo: 'Cherif'),
    );
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

    // L'utilisateur est connecté mais non onboardé → SETUP-01.
    expect(find.byType(Setup01OnboardingScreen), findsOneWidget);

    // Tap "Passer" — doit marquer onboarding completed et rediriger.
    final skip = find.text('Passer');
    expect(skip, findsOneWidget);
    await tester.tap(skip);
    await tester.pumpAndSettle();

    // Le placeholder /home affiche le titre "Murabbi" et le pseudo.
    expect(find.text('Murabbi'), findsOneWidget);
    expect(find.textContaining('Cherif'), findsOneWidget);
    expect(find.byType(Setup01OnboardingScreen), findsNothing);
    expect(find.byType(Au01LoginScreen), findsNothing);
  });

  testWidgets(
    'Flow A bis — utilisateur déconnecté arrive directement sur /auth/login',
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

      await tester.pumpAndSettle();

      expect(find.byType(Au01LoginScreen), findsOneWidget);
      expect(find.byType(Setup01OnboardingScreen), findsNothing);
    },
  );
}
