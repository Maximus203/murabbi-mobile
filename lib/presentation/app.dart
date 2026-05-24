import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/presentation/app_resume_invalidator.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/providers/leaderboard_notifier.dart';
import 'package:murabbi_mobile/presentation/router/app_router.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/services/connectivity/connectivity_service.dart';
import 'package:murabbi_mobile/services/sync/sync_service_provider.dart';

/// Seuil de pause au-delà duquel on invalide les caches de classement /
/// dashboard au resume (issue #197 — M5). 5 min évite les invalidations
/// inutiles lors d'une pause courte (notification, double-tap home).
const Duration kResumeInvalidationThreshold = Duration(minutes: 5);

/// Racine de l'application Murabbi — branche le GoRouter Riverpod et
/// observe le lifecycle pour invalider les caches au retour de background
/// long et déclencher le replay de la sync queue offline (M2 — issue #200).
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

    // Rejoue les items offline persistés avant le dernier redémarrage.
    // La DB sqflite est déjà initialisée via syncServiceProvider.
    _processPendingQueueOnStartup();

    // Écoute les changements de connectivité pour déclencher le replay
    // automatique au retour du réseau (M2 — issue #200).
    _listenConnectivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _invalidator.didChangeAppLifecycleState(state);
  }

  // ── SyncService (M2) ────────────────────────────────────────────────────────

  /// Rejoue la queue offline au démarrage (items persistés avant le
  /// dernier crash ou fermeture de l'app).
  Future<void> _processPendingQueueOnStartup() async {
    try {
      await ref.read(syncServiceProvider).processPendingQueue();
      appLog.i('MurabbiApp: startup sync replay complete');
    } catch (e, st) {
      appLog.e('MurabbiApp: startup sync replay failed', error: e, stackTrace: st);
    }
  }

  /// Écoute [connectivityProvider] et rejoue la queue offline dès que la
  /// connexion revient (false → true).
  void _listenConnectivity() {
    ref.listenManual(connectivityProvider, (previous, next) {
      final wasOffline = previous?.valueOrNull == false;
      final isNowOnline = next.valueOrNull == true;
      if (wasOffline && isNowOnline) {
        appLog.i('MurabbiApp: connectivity restored — triggering sync replay');
        ref.read(syncServiceProvider).processPendingQueue().catchError(
          // ignore: avoid_types_on_closure_parameters
          (Object e, StackTrace st) {
            appLog.e('MurabbiApp: sync replay failed', error: e, stackTrace: st);
          },
        );
      }
    });
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
