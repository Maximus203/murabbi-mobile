# ✅ POINT DE VALIDATION #2 — Auth + Navigation

## Ce qui est livré

- **Écrans**
  - `SplashScreen` (`lib/presentation/features/splash/screens/splash_screen.dart`)
  - `Au01LoginScreen` — email/password + Google OAuth + lien "Mot de passe oublié"
  - `Au02SignupScreen` — email/password (Q-18 : pas de pseudo, auto-généré)
  - `Au03ForgotPasswordScreen` — anti-enumeration OWASP (Q-7)
  - `Au04EmailVerificationScreen` (dumb) + `Au04EmailVerificationGate` (poll 5s, auto-detect Q2-C)
  - `Setup01OnboardingScreen` — walkthrough 4 slides + skip + dots
  - Placeholder `_HomePlaceholderScreen` (la HM-01 vraie arrive en Phase 3)
- **Routing**
  - `appRouterProvider` (GoRouter) avec routes `/splash`, `/auth/{login,signup,forgot,verify-email}`, `/onboarding`, `/home`
  - `authRedirect` (fonction pure testable hors GoRouter) — règle Q3-A : onboarding pédagogique pre-auth
  - `_RouterRefreshNotifier` qui pont Riverpod → GoRouter `refreshListenable`
- **State management**
  - `AuthNotifier` (`AsyncNotifier<User?>`) + `authStateChanges` listener
  - `OnboardingNotifier` (`AsyncNotifier<bool>`) + `OnboardingFlagStorage` (SharedPreferences, clé `onboarding_seen_v1` + migration douce du legacy `onboarding_completed_v1`)
  - `resendVerificationEmail` exposé sur le repository et le notifier (clôture PR #19)
  - `RefreshSessionUseCase` + `AuthRepository.refreshSession()` (Q2-C — auto-detect email confirmé sans tap manuel)
  - `User.emailConfirmedAt` + `isEmailVerified` exposés depuis le mapper Supabase
- **Tests**
  - 515 tests unit + widget
  - 3 flows E2E (`integration_test/flows/`) + helper `fakes.dart`
- **ADR**
  - ADR-012 — Onboarding pédagogique pre-auth & flag `onboarding_seen` (Q3-A)
- **Doc**
  - Ce fichier de validation

## Tests automatisés

- **Unit** : ~70 % du total (domain entities, value objects, use cases auth/onboarding/refreshSession, scoring, etc.) — passes 100 %
- **Widget** : ~30 % du total (auth screens, onboarding screen, splash, design-system goldens) — passes 100 %
- **Integration** : 3 flows E2E + 1 cas bis (4 scénarios)
  - `flow_a_onboarding_first_test.dart` — visiteur non onboardé → /onboarding → tap "Passer" → /auth/login + bis visiteur déjà onboardé → /auth/login direct
  - `flow_b_signup_verify_home_test.dart` — signUp → AU-04 → tap "vérifié" → /home
  - `flow_c_signin_signout_test.dart` — signIn → /home → signOut → /auth/login
  - **Compilent** (`flutter analyze` 0 issue couvre `integration_test/`).
  - **Exécution réelle** requiert un device/émulateur (`flutter test integration_test/ -d <device>`). Non automatisée en CI Phase 2 (cf. limitations).
- **Coverage global** (unit + widget seulement) : **89,75 %** (1278 / 1424 lignes) — ≥ seuil 80 %
- `flutter analyze` : **0 issue**
- `dart format --set-exit-if-changed .` : **0 fichier**

## Scénarios à tester manuellement

1. **Cold start — fresh install** — lancer l'app pour la 1ʳᵉ fois → splash bref → arrive sur SETUP-01 (onboarding pédagogique pre-auth Q3-A).
2. **Tap "Passer" sur SETUP-01** — flag `onboarding_seen` posé → arrive sur AU-01.
3. **Cold start — onboarding déjà vu, non connecté** — relance après un "Passer" → splash → AU-01 directement.
4. **Cold start — onboarding vu + déjà connecté** — relance après une session → splash → /home.
5. **Signup nominal** — depuis AU-01 tap "Créer un compte" → AU-02, saisir email + password 8+ chars → AU-04 affiche l'email tapé.
6. **Vérification email auto (Q2-C)** — sur AU-04 confirmer l'email côté Supabase (clic dans le mail) puis attendre ≤ 5s : le gate appelle `refreshSession`, détecte `email_confirmed_at` non null, et redirige automatiquement vers `/home` sans intervention de l'utilisateur. Le bouton "J'ai vérifié mon email" reste comme fallback.
7. **Signup email déjà utilisé** — bannière `EmailAlreadyInUseFailure` rouge sous le formulaire, pas de redirection.
8. **SignIn nominal** — credentials valides → `/home` placeholder avec pseudo.
9. **SignIn invalide** — bannière `InvalidCredentialsFailure`, formulaire reste sur AU-01.
10. **Mot de passe oublié** — depuis AU-01 tap "Mot de passe oublié ?" → AU-03, soumettre un email → message de succès générique (peu importe que l'email existe ou non, OWASP Q-7).
11. **Onboarding "Suivant"** — sur SETUP-01, tap 4 fois "Suivant" jusqu'au dernier slide puis tap "Commencer" → flag `onboarding_seen` posé → /auth/login.
12. **SignOut** — depuis le placeholder /home tap "Se déconnecter" → retour AU-01 ; le flag `onboarding_seen` reste posé.
13. **Resilience offline (sanity)** — couper le réseau, tenter signIn → bannière `NetworkFailure`. Sur AU-04, le poll `refreshSession` ne crashe pas, il retentera au prochain tick.

## Limitations connues

- **Deep-link reset password** : non implémenté en Phase 2 (hors scope explicite). L'utilisateur reçoit le mail Supabase et clique manuellement le lien → l'app ne consomme pas encore le `recovery` token côté `/auth/callback`. Reporté en Phase 2.5 ou 3.
- **Integration_test non exécutés en CI** : compilation validée par `flutter analyze`, mais l'exécution effective demande un device/émulateur — non câblé dans le workflow GitHub Actions Phase 2. À ajouter en Phase 3 (suite à instrumentation Patrol ou MacStadium runner).
- **Pseudo généré côté data** : implémenté en mock côté fake. Le vrai `auth_repository_impl.dart` génère `'Anonyme #' + 4 derniers chars de l'id` — comportement réel non couvert par les flows E2E (mock fake n'inspecte pas l'id).
- **OnboardingFlagStorage local** : flag SharedPreferences (un user qui change de device revoit le walkthrough). Choix assumé tant qu'il s'agit d'un onboarding pédagogique pré-auth (cf. ADR-012). Migration vers `users.account_setup_completed_at` côté admin uniquement si un onboarding post-auth est ajouté en Phase 3.
- **Goldens Linux-only** : sur Windows/macOS un `_BypassGoldenFileComparator` neutralise les goldens (cf. `test/flutter_test_config.dart` + ADR-010).

## Questions ouvertes

- **À valider — flow C signOut** : le flow C inclut un assert sur `signOut` (clôt la boucle). Si tu préfères que le scénario s'arrête à l'arrivée sur `/home`, je le retire — décision senior par défaut prise : on garde, parce que c'est la seule action mutante exposée sur le placeholder home.

Donne-moi ton avis avant que je passe à la suite.
