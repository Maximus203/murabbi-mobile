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
