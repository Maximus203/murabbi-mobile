import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_01_login_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_02_signup_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_03_forgot_password_screen.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_gate.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_01_habits_list_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/ha_02_create_habit_screen.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/providers/onboarding_notifier.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/screens/setup_01_onboarding_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_01_today_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_02_prayer_settings_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/screens/sa_03_prayer_detail_screen.dart';
import 'package:murabbi_mobile/presentation/features/splash/screens/splash_screen.dart';
import 'package:murabbi_mobile/presentation/router/auth_redirect.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

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
        builder: (_, _) => const _HomePlaceholderScreen(),
      ),
      GoRoute(
        path: AppRoutes.salat,
        builder: (context, _) => Sa01TodayScreen(
          onConfigureSettings: () => context.go(AppRoutes.salatSettings),
          onOpenDetail: (prayerName) =>
              context.go(AppRoutes.salatDetail(prayerName)),
        ),
      ),
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
        path: AppRoutes.habits,
        builder: (context, _) => Ha01HabitsListScreen(
          onCreate: () => context.go(AppRoutes.habitsCreate),
          onBack: () => context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.habitsCreate,
        builder: (context, _) => Ha02CreateHabitScreen(
          onCreated: () => context.go(AppRoutes.habits),
          onCancel: () => context.go(AppRoutes.habits),
        ),
      ),
    ],
  );
});

/// Placeholder /home : la vraie HM-01 (dashboard) arrive en Phase 3.
class _HomePlaceholderScreen extends ConsumerWidget {
  const _HomePlaceholderScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Murabbi', style: AppTypography.h1),
              const SizedBox(height: 8),
              Text(
                user == null
                    ? 'Phase 2 — auth + routing OK'
                    : 'Bienvenue, ${user.pseudo.value}',
                style: AppTypography.body,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.salat),
                child: const Text('Ouvrir Salat (SA-01)'),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.habits),
                child: const Text('Mes habitudes'),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
