import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_02_signup_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_03_forgot_password_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_gate.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/screens/hb_03_categories_list_screen.dart';
import 'package:murabbi_mobile/presentation/features/categories/screens/hb_04_category_form_screen.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_01_collections_screen.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_02_create_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_detail_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/screens/hm_01_dashboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_01_habits_list_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_02_create_habit_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/hb_detail_screen.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/screens/lb_01_leaderboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/providers/onboarding_notifier.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_01_today_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_03_prayer_detail_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_01_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_02_edit_profile_screen.dart';
import 'package:murabbi_mobile/presentation/features/settings/screens/st_03_delete_account_screen.dart';
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

/// Shell principal avec barre de navigation persistante (D-17 — issue #103).
///
/// Utilise [StatefulShellRoute.indexedStack] pour conserver l'état de chaque
/// onglet lorsque l'utilisateur navigue entre Accueil, Salat et Habitudes.
/// Sans ce shell, chaque `context.go()` détruisait et recréait l'arbre du
/// nouvel onglet, déclenchant un re-fetch complet et un flash de chargement.
class _ShellScaffold extends ConsumerWidget {
  /// Shell fourni par [StatefulShellRoute] — contient le [Navigator] de
  /// l'onglet actif avec son historique propre.
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

  /// Index → onglet [AppBottomNavTab] correspondant.
  static const List<AppBottomNavTab> _tabs = [
    AppBottomNavTab.home,
    AppBottomNavTab.salat,
    AppBottomNavTab.habits,
    AppBottomNavTab.collections,
    AppBottomNavTab.leaderboard,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = _tabs[navigationShell.currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      // La BottomNav est dans le shell → un seul widget partagé entre onglets,
      // pas de reconstruction à chaque changement d'onglet.
      bottomNavigationBar: AppBottomNav(
        active: activeTab,
        onTabSelected: (tab) => _onTabSelected(context, ref, tab),
      ),
      // Le body est le Navigator de l'onglet courant maintenu par go_router.
      body: navigationShell,
    );
  }

  void _onTabSelected(
    BuildContext context,
    WidgetRef ref,
    AppBottomNavTab tab,
  ) {
    final index = _tabs.indexOf(tab);
    if (index == -1) return;

    // Collections et Classement non encore implémentés (slices Phase 4 / 5).
    if (tab == AppBottomNavTab.collections ||
        tab == AppBottomNavTab.leaderboard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_tabLabel(tab)} arrive bientôt.')),
      );
      return;
    }

    // goBranch avec `initialLocation: true` si on retap le même onglet
    // → remonte en haut de l'historique de cet onglet (comportement standard).
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static String _tabLabel(AppBottomNavTab tab) {
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
      // ── Routes pre-home (hors shell) ──────────────────────────────────
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
            // session puis on quitte le sas verify-email (le redirect
            // global laisse cette route toujours autorisée — sans push
            // explicite l'utilisateur resterait bloqué ici).
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

      // ── Routes hors-shell (modal / sous-pages) ────────────────────────
      // Ces routes naviguent en dehors du shell indexedStack — l'utilisateur
      // les quitte via `context.go(AppRoutes.salat)` ou `context.go(AppRoutes.habits)`.
      GoRoute(
        path: AppRoutes.salatSettings,
        builder: (context, _) => Sa02PrayerSettingsScreen(
          onBack: () => context.go(AppRoutes.salat),
          onSaved: () => context.go(AppRoutes.salat),
        ),
      ),
      GoRoute(
        path: AppRoutes.salatDetailPattern,
        builder: (context, state) {
          final prayerName = state.pathParameters['prayerName'] ?? 'fajr';
          return Sa03PrayerDetailScreen(
            prayerName: prayerName,
            onBack: () => context.go(AppRoutes.salat),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.habitsCreate,
        builder: (context, _) => Ha02CreateHabitScreen(
          onCreated: () => context.go(AppRoutes.habits),
          onCancel: () => context.go(AppRoutes.habits),
        ),
      ),
      // HA-02 mode édition (issue #152). L'habitude à éditer est lue depuis
      // la liste déjà chargée ; si introuvable (deep-link à froid), on
      // retombe sur HA-01.
      GoRoute(
        path: AppRoutes.habitEditPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return Consumer(
            builder: (context, ref, _) {
              final habits =
                  ref.watch(habitsNotifierProvider).valueOrNull ??
                  const <Habit>[];
              final matches = habits.where((h) => h.id.value == id).toList();
              final match = matches.isEmpty ? null : matches.first;
              if (match == null) {
                return Ha01HabitsListScreen(
                  onCreate: () => context.go(AppRoutes.habitsCreate),
                  onOpenCategories: () => context.go(AppRoutes.categories),
                  onEditHabit: (id) => context.go(AppRoutes.habitEdit(id)),
                  onOpenHabit: (id) => context.go(AppRoutes.habitDetail(id)),
                );
              }
              return Ha02CreateHabitScreen(
                initialHabit: match,
                onCreated: () => context.go(AppRoutes.habits),
                onCancel: () => context.go(AppRoutes.habits),
              );
            },
          );
        },
      ),

      // HB-DETAIL — détail habitude (issue #153). Déclarée APRÈS
      // `/habits/create` et `/habits/:id/edit` pour que go_router matche
      // ces routes plus spécifiques d'abord.
      GoRoute(
        path: AppRoutes.habitDetailPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return HbDetailScreen(
            habitId: id,
            onBack: () => context.go(AppRoutes.habits),
            onEdit: (habitId) => context.go(AppRoutes.habitEdit(habitId)),
            onDeleted: () => context.go(AppRoutes.habits),
          );
        },
      ),

      // ── Catégories — HB-03 liste / HB-04 formulaire (issue #150) ──────
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, _) => Hb03CategoriesListScreen(
          onCreate: () => context.go(AppRoutes.categoriesCreate),
          onEdit: (id) => context.go(AppRoutes.categoryEdit(id.value)),
        ),
      ),
      GoRoute(
        path: AppRoutes.categoriesCreate,
        builder: (context, _) => Hb04CategoryFormScreen(
          onDone: () => context.go(AppRoutes.categories),
          onCancel: () => context.go(AppRoutes.categories),
        ),
      ),
      GoRoute(
        path: AppRoutes.categoryEditPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return Consumer(
            builder: (context, ref, _) {
              // La catégorie à éditer est lue depuis la liste déjà chargée.
              // Si introuvable (deep-link à froid), on retombe sur HB-03.
              final categories =
                  ref.watch(categoriesNotifierProvider).valueOrNull ??
                  const <Category>[];
              final matches = categories
                  .where((c) => c.id.value == id)
                  .toList();
              final match = matches.isEmpty ? null : matches.first;
              if (match == null) {
                return Hb03CategoriesListScreen(
                  onCreate: () => context.go(AppRoutes.categoriesCreate),
                  onEdit: (id) => context.go(AppRoutes.categoryEdit(id.value)),
                );
              }
              return Hb04CategoryFormScreen(
                initialCategory: match,
                onDone: () => context.go(AppRoutes.categories),
                onCancel: () => context.go(AppRoutes.categories),
              );
            },
          );
        },
      ),

      // ── Paramètres — ST-01 / ST-02 / ST-03 (issue #7, Phase 6) ────────
      // Hors shell : sous-pages authentifiées. ST-02/ST-03 déclarées avant
      // rien de plus spécifique — pas de conflit de pattern.
      GoRoute(
        path: AppRoutes.settingsProfile,
        builder: (context, _) => St02EditProfileScreen(
          onBack: () => context.go(AppRoutes.settings),
          onSaved: () => context.go(AppRoutes.settings),
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsDelete,
        builder: (context, _) => Consumer(
          builder: (context, ref, _) => St03DeleteAccountScreen(
            onBack: () => context.go(AppRoutes.settings),
            // Suppression réussie → le signOut interne au use case bascule
            // l'auth state, le redirect global pousse vers /auth/login.
            onDeleted: () => context.go(AppRoutes.login),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, _) => Consumer(
          builder: (context, ref, _) => St01SettingsScreen(
            onBack: () => context.go(AppRoutes.home),
            onEditProfile: () => context.go(AppRoutes.settingsProfile),
            onDeleteAccount: () => context.go(AppRoutes.settingsDelete),
            onSignOut: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ),
      ),


      // ── Shell persistant — onglets principaux (D-17) ──────────────────
      // StatefulShellRoute.indexedStack maintient un Navigator distinct par
      // branche → l'état (scroll, providers, page stack) est préservé lors
      // du changement d'onglet. Chaque branche a sa propre initialLocation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: [
          // Branche 0 — Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) => Consumer(
                  builder: (context, ref, _) => Hm01DashboardScreen(
                    onTabSelected: (tab) {
                      // La BottomNav dans _ShellScaffold gère la navigation
                      // inter-onglets. Ce callback couvre l'éventuel tap
                      // résiduel depuis la card dashboard (contexte hors shell).
                      final index = _ShellScaffold._tabs.indexOf(tab);
                      if (index == -1) return;
                      context.go(_tabRootRoute(tab));
                    },
                    onConfigurePrayers: () =>
                        context.go(AppRoutes.salatSettings),
                    onOpenSalat: () => context.go(AppRoutes.salat),
                    // Audit TL PR #42 : Consumer + ref.read plutôt que
                    // ProviderScope.containerOf (plus idiomatique).
                    onSignOut: () =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                  ),
                ),
              ),
            ],
          ),

          // Branche 1 — Salat
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
              ),
            ],
          ),

          // Branche 2 — Habitudes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.habits,
                builder: (context, _) => Ha01HabitsListScreen(
                  onCreate: () => context.go(AppRoutes.habitsCreate),
                  onOpenCategories: () => context.go(AppRoutes.categories),
                  onEditHabit: (id) => context.go(AppRoutes.habitEdit(id)),
                  onOpenHabit: (id) => context.go(AppRoutes.habitDetail(id)),
                ),
              ),
            ],
          ),

          // Branche 3 — Collections (stub — Phase 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.collections,
                builder: (_, _) => const _StubScreen(title: 'Collections'),
              ),
            ],
          ),

          // Branche 4 — Classement (stub — Phase 5)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (_, _) => const _StubScreen(title: 'Classement'),
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

/// Route racine par onglet — utilisée pour naviguer directement via `context.go`.
String _tabRootRoute(AppBottomNavTab tab) {
  switch (tab) {
    case AppBottomNavTab.home:
      return AppRoutes.home;
    case AppBottomNavTab.salat:
      return AppRoutes.salat;
    case AppBottomNavTab.habits:
      return AppRoutes.habits;
    case AppBottomNavTab.collections:
      return AppRoutes.collections;
    case AppBottomNavTab.leaderboard:
      return AppRoutes.leaderboard;
  }
}

/// Placeholder minimaliste pour les onglets non encore implémentés.
/// Remplacé par la vraie feature dans les phases 4 / 5.
class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Text(title, style: const TextStyle(fontSize: 18))),
    );
  }
}
