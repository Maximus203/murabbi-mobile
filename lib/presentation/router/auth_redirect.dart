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
/// Règles :
/// - L'une des sources est en `loading` → `/splash` (sauf si déjà dessus)
/// - Pas de session :
///   * sur `/auth/login`, `/auth/signup`, `/auth/forgot` → reste
///   * sinon → `/auth/login`
/// - Session active :
///   * `/auth/verify-email` est toujours autorisé (transient post-signUp)
///   * sinon, si non onboarded → `/onboarding`
///   * sinon (onboarded) → toute route auth/splash/onboarding repousse vers
///     `/home`
String? authRedirect({
  required AsyncValue<User?> auth,
  required AsyncValue<bool> onboarded,
  required String currentPath,
}) {
  if (auth.isLoading || onboarded.isLoading) {
    return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final user = auth.valueOrNull;
  final isOnboarded = onboarded.valueOrNull ?? false;

  if (user == null) {
    if (AppRoutes.isAuthRoute(currentPath)) return null;
    return AppRoutes.login;
  }

  // User signe in : verify-email est un sas transient toujours permis.
  if (currentPath == AppRoutes.verifyEmail) return null;

  if (!isOnboarded) {
    return currentPath == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  // Authenticated + onboarded — repousser depuis tout sas pre-home.
  if (AppRoutes.isAuthRoute(currentPath) ||
      currentPath == AppRoutes.splash ||
      currentPath == AppRoutes.onboarding) {
    return AppRoutes.home;
  }
  return null;
}
