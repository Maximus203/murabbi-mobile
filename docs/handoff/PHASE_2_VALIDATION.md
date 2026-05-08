# ✅ POINT DE VALIDATION #2 — Auth + Navigation

## Ce qui est livré

- **Écrans**
  - `SplashScreen` (`lib/presentation/features/splash/screens/splash_screen.dart`)
  - `Au01LoginScreen` — email/password + Google OAuth + lien "Mot de passe oublié"
  - `Au02SignupScreen` — email/password (Q-18 : pas de pseudo, auto-généré)
  - `Au03ForgotPasswordScreen` — anti-enumeration OWASP (Q-7)
  - `Au04EmailVerificationScreen` (dumb) + `Au04EmailVerificationGate` (poll 5s)
  - `Setup01OnboardingScreen` — walkthrough 4 slides + skip + dots
  - Placeholder `_HomePlaceholderScreen` (la HM-01 vraie arrive en Phase 3)
- **Routing**
  - `appRouterProvider` (GoRouter) avec routes `/splash`, `/auth/{login,signup,forgot,verify-email}`, `/onboarding`, `/home`
  - `authRedirect` (fonction pure testable hors GoRouter)
  - `_RouterRefreshNotifier` qui pont Riverpod → GoRouter `refreshListenable`
- **State management**
  - `AuthNotifier` (`AsyncNotifier<User?>`) + `authStateChanges` listener
  - `OnboardingNotifier` (`AsyncNotifier<bool>`) + `OnboardingFlagStorage` (SharedPreferences)
  - `resendVerificationEmail` exposé sur le repository et le notifier (clôture PR #19)
- **Tests**
  - 499 tests unit + widget (41 fichiers)
  - 3 flows E2E (`integration_test/flows/`) + helper `fakes.dart`
- **Doc**
  - Ce fichier de validation

## Tests automatisés

- **Unit** : ~70 % du total (domain entities, value objects, use cases auth/onboarding, scoring, etc.) — passes 100 %
- **Widget** : ~30 % du total (auth screens, onboarding screen, splash, design-system goldens) — passes 100 %
- **Integration** : 3 flows E2E + 1 cas bis (4 scénarios)
  - `flow_a_onboarding_first_test.dart` — onboarding skip → /home + bis user déconnecté → /auth/login
  - `flow_b_signup_verify_home_test.dart` — signUp → AU-04 → tap "vérifié" → /home
  - `flow_c_signin_signout_test.dart` — signIn → /home → signOut → /auth/login
  - **Compilent** (`flutter analyze` 0 issue couvre `integration_test/`).
  - **Exécution réelle** requiert un device/émulateur (`flutter test integration_test/ -d <device>`). Non automatisée en CI Phase 2 (cf. limitations).
- **Coverage global** (unit + widget seulement) : **89,96 %** (1255 / 1395 lignes) — ≥ seuil 80 %
- `flutter analyze` : **0 issue**
- `dart format --set-exit-if-changed .` : **0 fichier**

## Scénarios à tester manuellement

1. **Cold start non onboardé + non connecté** — lancer l'app → splash bref → arrive sur AU-01.
2. **Cold start onboardé + connecté** (re-launch après une session précédente) — splash → directement /home (placeholder).
3. **Signup nominal** — depuis AU-01 tap "Créer un compte" → AU-02, saisir email + password 8+ chars → AU-04 affiche l'email tapé.
4. **Vérification email manuelle** — sur AU-04 attendre une confirmation Supabase puis tap "J'ai vérifié mon email" → `/onboarding` (si pas encore onboardé) puis `/home`.
5. **Signup email déjà utilisé** — bannière `EmailAlreadyInUseFailure` rouge sous le formulaire, pas de redirection.
6. **SignIn nominal** — credentials valides → `/home` placeholder avec pseudo.
7. **SignIn invalide** — bannière `InvalidCredentialsFailure`, formulaire reste sur AU-01.
8. **Mot de passe oublié** — depuis AU-01 tap "Mot de passe oublié ?" → AU-03, soumettre un email → message de succès générique (peu importe que l'email existe ou non, OWASP Q-7).
9. **Onboarding "Suivant"** — sur SETUP-01, tap 4 fois "Suivant" jusqu'au dernier slide puis tap "Commencer" → `/home`.
10. **Onboarding "Passer"** — tap "Passer" depuis n'importe quel slide → flag posé immédiatement → `/home`.
11. **SignOut** — depuis le placeholder /home tap "Se déconnecter" → retour AU-01 ; le flag onboarding reste posé.
12. **Resilience offline (sanity)** — couper le réseau, tenter signIn → bannière `NetworkFailure`.

## Limitations connues

- **Deep-link reset password** : non implémenté en Phase 2 (hors scope explicite). L'utilisateur reçoit le mail Supabase et clique manuellement le lien → l'app ne consomme pas encore le `recovery` token côté `/auth/callback`. Reporté en Phase 2.5 ou 3.
- **Vérification email auto** : le `Timer.periodic(5s)` invalide bien `authNotifierProvider`, mais comme Supabase ne flippe pas l'event `authStateChanges` sur la simple confirmation d'email (il faut un re-signIn), l'utilisateur doit aujourd'hui tap "J'ai vérifié mon email" manuellement. La nav vers `/home` est bien câblée par cette callback (fix `feat(router): GREEN -- onContinue verify-email push vers /home`).
- **Integration_test non exécutés en CI** : compilation validée par `flutter analyze`, mais l'exécution effective demande un device/émulateur — non câblé dans le workflow GitHub Actions Phase 2. À ajouter en Phase 3 (suite à instrumentation Patrol ou MacStadium runner).
- **Pseudo généré côté data** : implémenté en mock côté fake. Le vrai `auth_repository_impl.dart` génère `'Anonyme #' + 4 derniers chars de l'id` — comportement réel non couvert par les flows E2E (mock fake n'inspecte pas l'id).
- **OnboardingFlagStorage local** : flag SharedPreferences (un user qui change de device refait SETUP-01). Migration vers `users.onboarding_completed_at` côté admin → Q-18 mobile à finaliser (voir TODO dans `lib/services/onboarding_flag_storage.dart`).
- **Goldens Linux-only** : sur Windows/macOS un `_BypassGoldenFileComparator` neutralise les goldens (cf. `test/flutter_test_config.dart` + ADR-010).

## Questions ouvertes

- **À valider — flow C signOut** : le flow C inclut un assert sur `signOut` (clôt la boucle). Si tu préfères que le scénario s'arrête à l'arrivée sur `/home`, je le retire — décision senior par défaut prise : on garde, parce que c'est la seule action mutante exposée sur le placeholder home.
- **À valider — décision UX AU-04** : aujourd'hui "J'ai vérifié mon email" est manuel. Veux-tu qu'on remplace le polling par un deep-link `/auth/callback` en Phase 2.5 (avant Phase 3 produit) ou est-ce qu'on remet ça à plus tard ?
- **À valider — onboarding gating** : règle actuelle = un user non auth est toujours envoyé sur `/auth/login`, jamais directement sur `/onboarding`. C'est cohérent (l'onboarding configure des settings prière liés à l'utilisateur) mais ça veut dire qu'un visiteur qui ouvre l'app ne voit jamais la pédagogie 4 slides avant de créer un compte. Si tu veux un onboarding "marketing" pre-auth, il faut ajouter un flag séparé.

Donne-moi ton avis avant que je passe à la suite.
