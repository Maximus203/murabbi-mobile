import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_02_signup_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_03_forgot_password_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_gate.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/screens/hm_01_dashboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/providers/onboarding_notifier.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_01_today_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/splash/screens/splash_screen.dart';
import 'package:murabbi_mobile/presentation/router/auth_redirect.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';

/// Pont Riverpod → Listenable pour le `refreshListenable` de GoRouter :
/// chaque fois que l'état d'auth ou d'onboarding change, on notifie le
/// routeur qui ré-évalue [authRedirect].
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, _) => notifyListeners());
    ref.listen(onboardingNotifierProvider, (_, _) => notifyListeners());
  }
}

/// Provider du GoRouter Murabbi — lifecycle aligné sur le ProviderContainer
/// racine. Toute la logique de redirection vit dans [authRedirect] (testable
/// hors GoRouter).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      return authRedirect(
        auth: ref.read(authNotifierProvider),
        onboarded: ref.read(onboardingNotifierProvider),
        currentPath: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => Au01LoginScreen(
          onForgotPassword: () => context.go(AppRoutes.forgot),
          onSignUp: () => context.go(AppRoutes.signup),
          onAuthenticated: () {
            // Le redirect global gère la suite (onboarding ou home).
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, _) => Au02SignupScreen(
          onSignIn: () => context.go(AppRoutes.login),
          onSignedUp: () => context.go(AppRoutes.verifyEmail),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (context, _) =>
            Au03ForgotPasswordScreen(onBack: () => context.go(AppRoutes.login)),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, _) => Au04EmailVerificationGate(
          onContinue: () {
            // Une fois l'email confirme cote Supabase, on rafraichit la
            // session puis on quitte le sas verify-email (le redirect
            // global laisse cette route toujours autorisee — sans push
            // explicite l'utilisateur resterait bloque ici).
            ref.invalidate(authNotifierProvider);
            context.go(AppRoutes.home);
          },
          onChangeEmail: () => context.go(AppRoutes.signup),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => Setup01OnboardingScreen(
          onCompleted: () {
            // Le redirect global pousse vers /home après la mise à jour
            // de onboardingNotifierProvider — rien à faire ici.
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, _) => Consumer(
          builder: (context, ref, _) => Hm01DashboardScreen(
            onTabSelected: (tab) => _handleTabSelection(context, tab),
            // PR #38 (slice Salat) mergée → wiring direct vers les routes.
            onConfigurePrayers: () => context.go(AppRoutes.salatSettings),
            onOpenSalat: () => context.go(AppRoutes.salat),
            // Audit TL PR #42 : Consumer + ref.read plutôt que
            // ProviderScope.containerOf (plus idiomatique).
            onSignOut: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.salat,
        builder: (context, _) => Sa01TodayScreen(
          onConfigureSettings: () => context.go(AppRoutes.salatSettings),
        ),
      ),
      GoRoute(
        path: AppRoutes.salatSettings,
        builder: (context, _) => Sa02PrayerSettingsScreen(
          onBack: () => context.go(AppRoutes.salat),
          onSaved: () => context.go(AppRoutes.salat),
        ),
      ),
    ],
  );
});

/// Routage des onglets de [AppBottomNav]. Salat est activé (PR #38
/// mergée), les destinations Habitudes / Collections / Classement
/// affichent un snackbar tant que leurs slices ne sont pas mergées.
void _handleTabSelection(BuildContext context, AppBottomNavTab tab) {
  switch (tab) {
    case AppBottomNavTab.home:
      // Déjà sur /home.
      return;
    case AppBottomNavTab.salat:
      context.go(AppRoutes.salat);
    case AppBottomNavTab.habits:
    case AppBottomNavTab.collections:
    case AppBottomNavTab.leaderboard:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tabLabel(tab)} arrive bientôt.')),
      );
  }
}

String _tabLabel(AppBottomNavTab tab) {
  switch (tab) {
    case AppBottomNavTab.home:
      return 'Accueil';
    case AppBottomNavTab.salat:
      return 'Salat';
    case AppBottomNavTab.habits:
      return 'Habitudes';
    case AppBottomNavTab.collections:
      return 'Collections';
    case AppBottomNavTab.leaderboard:
      return 'Classement';
  }
}
