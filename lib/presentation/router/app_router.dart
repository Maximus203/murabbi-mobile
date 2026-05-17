import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_02_signup_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_03_forgot_password_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_gate.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_01_collections_screen.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_02_create_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_detail_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/screens/hm_01_dashboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_01_habits_list_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_02_create_habit_screen.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/screens/lb_01_leaderboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/providers/onboarding_notifier.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_01_today_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_03_prayer_detail_screen.dart';
import 'package:murabbi_mobile/presentation/features/splash/screens/splash_screen.dart';
import 'package:murabbi_mobile/presentation/router/auth_redirect.dart';
import 'package:murabbi_mobile/presentation/router/scaffold_with_bottom_nav.dart';

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
///
/// D-18 (issue #103) : les 3 onglets principaux (home / salat / habits) sont
/// encapsulés dans un [StatefulShellRoute.indexedStack] qui maintient un
/// [Navigator] persistant par branche — plus de reconstruction à chaque
/// switch d'onglet, plus d'appel réseau parasite sur SA-01.
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
      // ── Routes hors shell (auth, splash, onboarding) ───────────────────
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => Au01LoginScreen(
          onForgotPassword: (email) =>
              context.go(AppRoutes.forgot, extra: email),
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
        builder: (context, state) => Au03ForgotPasswordScreen(
          onBack: () => context.go(AppRoutes.login),
          initialEmail: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, _) => Au04EmailVerificationGate(
          onContinue: () {
            // Une fois l'email confirmé côté Supabase, on rafraîchit la
            // session puis on quitte le sas verify-email.
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
            // de onboardingNotifierProvider.
          },
        ),
      ),

      // ── Shell d'onglets — D-18 : IndexedStack, état préservé ───────────
      // [StatefulShellRoute.indexedStack] maintient un Navigator indépendant
      // par branche : la branche salat ne reconstruit plus au retour sur
      // l'onglet home, et vice-versa.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithBottomNav(navigationShell: navigationShell),
        branches: [
          // Branche 0 — Accueil (HM-01)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) => Consumer(
                  builder: (context, ref, _) => Hm01DashboardScreen(
                    // onTabSelected délégué au ScaffoldWithBottomNav.
                    // Le dashboard n'a plus besoin de connaître les autres
                    // onglets — navigation inter-tab via la bottom nav.
                    onTabSelected: (_) {},
                    onConfigurePrayers: () =>
                        context.go(AppRoutes.salatSettings),
                    onOpenSalat: () => context.go(AppRoutes.salat),
                    onSignOut: () =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                  ),
                ),
              ),
            ],
          ),

          // Branche 1 — Salat (SA-01, SA-02, SA-03)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.salat,
                builder: (context, _) => Sa01TodayScreen(
                  onConfigureSettings: () =>
                      context.go(AppRoutes.salatSettings),
                  onOpenDetail: (prayerName) =>
                      context.go(AppRoutes.salatDetail(prayerName)),
                ),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, _) => Sa02PrayerSettingsScreen(
                      onBack: () => context.go(AppRoutes.salat),
                      onSaved: () => context.go(AppRoutes.salat),
                    ),
                  ),
                  GoRoute(
                    path: ':prayerName/detail',
                    builder: (context, state) {
                      final prayerName =
                          state.pathParameters['prayerName'] ?? 'fajr';
                      return Sa03PrayerDetailScreen(
                        prayerName: prayerName,
                        onBack: () => context.go(AppRoutes.salat),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branche 2 — Habitudes (HA-01, HA-02)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.habits,
                builder: (context, _) => Ha01HabitsListScreen(
                  onCreate: () => context.go(AppRoutes.habitsCreate),
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, _) => Ha02CreateHabitScreen(
                      onCreated: () => context.go(AppRoutes.habits),
                      onCancel: () => context.go(AppRoutes.habits),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.collections,
        builder: (context, _) => Co01CollectionsScreen(
          onCreate: () => context.go(AppRoutes.collectionsCreate),
          onTap: (collection) =>
              context.go(AppRoutes.collectionsDetail, extra: collection),
        ),
      ),
      GoRoute(
        path: AppRoutes.collectionsCreate,
        builder: (context, _) => Co02CreateCollectionScreen(
          onCreated: () => context.go(AppRoutes.collections),
          onCancel: () => context.go(AppRoutes.collections),
        ),
      ),
      GoRoute(
        path: AppRoutes.collectionsDetail,
        builder: (context, state) {
          final collection = state.extra as Collection;
          return CoDetailCollectionScreen(
            collection: collection,
            onBack: () => context.go(AppRoutes.collections),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (_, _) => const Lb01LeaderboardScreen(),
      ),
    ],
  );
});

/// Routage des onglets de [AppBottomNav] — slice 5.G : tous les onglets
/// sont maintenant câblés vers leurs routes réelles.
void _handleTabSelection(BuildContext context, AppBottomNavTab tab) {
  switch (tab) {
    case AppBottomNavTab.home:
      context.go(AppRoutes.home);
    case AppBottomNavTab.salat:
      context.go(AppRoutes.salat);
    case AppBottomNavTab.habits:
      context.go(AppRoutes.habits);
    case AppBottomNavTab.collections:
      context.go(AppRoutes.collections);
    case AppBottomNavTab.leaderboard:
      context.go(AppRoutes.leaderboard);
  }
}
