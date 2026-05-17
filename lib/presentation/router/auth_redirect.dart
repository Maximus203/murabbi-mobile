import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';

/// Routes connues du shell d'authentification.
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const forgot = '/auth/forgot';
  static const verifyEmail = '/auth/verify-email';
  static const onboarding = '/onboarding';
  static const home = '/home';

  /// Salat — SA-01 "Aujourd'hui" (slice 3.C.3).
  static const salat = '/salat';

  /// Salat — SA-02 "Réglages des prières" (slice 3.C.3).
  static const salatSettings = '/salat/settings';

  /// Salat — SL-DETAIL "Détail prière" (issue #50). Chemin dynamique :
  /// `/salat/<prayerName>/detail` où prayerName ∈ fajr/dhuhr/asr/maghrib/isha.
  static String salatDetail(String prayerName) => '/salat/$prayerName/detail';
  static const salatDetailPattern = '/salat/:prayerName/detail';

  /// Habitudes — HA-01 liste (slice 3.D).
  static const habits = '/habits';

  /// Habitudes — HA-02 création (slice 3.D).
  static const habitsCreate = '/habits/create';

  /// Catégories — HB-03 liste (issue #150).
  static const categories = '/categories';

  /// Catégories — HB-04 création (issue #150).
  static const categoriesCreate = '/categories/new';

  /// Catégories — HB-04 édition (issue #150). Chemin dynamique :
  /// `/categories/<id>/edit`.
  static String categoryEdit(String id) => '/categories/$id/edit';
  static const categoryEditPattern = '/categories/:id/edit';

  /// Collections — CO-01 liste (slice 5.D).
  static const collections = '/collections';

  /// Collections — CO-02 création (slice 5.D).
  static const collectionsCreate = '/collections/create';

  /// Collections — CO-DETAIL (slice 5.D). `extra` = [Collection].
  static const collectionsDetail = '/collections/detail';

  /// Leaderboard — LB-01 (slice 5.E).
  static const leaderboard = '/leaderboard';

  /// `/auth/verify-email` est traité à part : il est accessible aussi bien
  /// quand l'utilisateur n'a pas de session que quand il vient de signUp et
  /// attend la confirmation par mail.
  static bool isAuthRoute(String path) =>
      path.startsWith('/auth/') && path != verifyEmail;
}

/// Logique de redirection — pure fonction testable hors GoRouter.
///
/// Règles (Q3-A — onboarding pédagogique pre-auth) :
/// - L'une des sources est en `loading` → `/splash` (sauf si déjà dessus)
/// - Pas de session :
///   * onboarding pas encore vu → toute route hors `/onboarding` et hors
///     routes auth pousse vers `/onboarding` ; sur les routes auth on
///     laisse l'utilisateur (il peut sauter le walkthrough) ;
///   * onboarding vu → routes auth (login/signup/forgot) et `/onboarding`
///     restent autorisées, le reste pousse vers `/auth/login`.
/// - Session active :
///   * `/auth/verify-email` est toujours autorisé (transient post-signUp) ;
///   * sinon, toute route auth/splash/onboarding pousse vers `/home`.
String? authRedirect({
  required AsyncValue<User?> auth,
  required AsyncValue<bool> onboarded,
  required String currentPath,
}) {
  if (auth.isLoading || onboarded.isLoading) {
    return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final user = auth.valueOrNull;
  final onboardingSeen = onboarded.valueOrNull ?? false;

  if (user == null) {
    // Q3-A : onboarding pédagogique pre-auth.
    if (!onboardingSeen) {
      // L'utilisateur n'a jamais vu les slides — on les pousse, sauf s'il
      // est déjà sur une route auth (signup direct, login, forgot) où on
      // le laisse poursuivre.
      if (currentPath == AppRoutes.onboarding) return null;
      if (AppRoutes.isAuthRoute(currentPath)) return null;
      return AppRoutes.onboarding;
    }
    // Onboarding deja vu : routes auth + onboarding restent libres.
    if (AppRoutes.isAuthRoute(currentPath) ||
        currentPath == AppRoutes.onboarding) {
      return null;
    }
    return AppRoutes.login;
  }

  // User signe in : verify-email est un sas transient toujours permis.
  if (currentPath == AppRoutes.verifyEmail) return null;

  // Authenticated — repousser depuis tout sas pre-home (Q3-A : pas de
  // second flag d'onboarding post-auth, on va directement /home).
  if (AppRoutes.isAuthRoute(currentPath) ||
      currentPath == AppRoutes.splash ||
      currentPath == AppRoutes.onboarding) {
    return AppRoutes.home;
  }
  return null;
}
