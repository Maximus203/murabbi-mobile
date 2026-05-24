import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/app_resume_invalidator.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/providers/leaderboard_notifier.dart';
import 'package:murabbi_mobile/presentation/router/app_router.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

/// Seuil de pause au-delà duquel on invalide les caches de classement /
/// dashboard au resume (issue #197 — M5). 5 min évite les invalidations
/// inutiles lors d'une pause courte (notification, double-tap home).
const Duration kResumeInvalidationThreshold = Duration(minutes: 5);

/// Racine de l'application Murabbi — branche le GoRouter Riverpod et
/// observe le lifecycle pour invalider les caches au retour de
/// background long.
class MurabbiApp extends ConsumerStatefulWidget {
  const MurabbiApp({super.key});

  @override
  ConsumerState<MurabbiApp> createState() => _MurabbiAppState();
}

class _MurabbiAppState extends ConsumerState<MurabbiApp>
    with WidgetsBindingObserver {
  late final AppResumeInvalidator _invalidator;

  @override
  void initState() {
    super.initState();
    _invalidator = AppResumeInvalidator(
      threshold: kResumeInvalidationThreshold,
      onResumeAfterLongPause: () {
        // Invalider leaderboard + dashboard force un refetch au prochain
        // watch (cf. issue #197 — données potentiellement périmées après
        // un long background).
        ref
          ..invalidate(leaderboardNotifierProvider)
          ..invalidate(dashboardNotifierProvider);
      },
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Retire l'observer pour éviter une fuite mémoire (critère #197).
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _invalidator.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Murabbi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
