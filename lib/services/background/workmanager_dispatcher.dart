import 'package:logger/logger.dart';

/// Abstraction sur le runner WorkManager — permet l'injection en test
/// sans dépendre du plugin natif.
///
/// L'implémentation production utilise `workmanager` package.
/// L'implémentation test utilise un mock (cf. MOB-005 tests).
abstract class WorkManagerRunner {
  /// Initialise WorkManager avec le callback dispatcher top-level.
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode,
  });

  /// Enregistre une tâche périodique.
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
  });

  /// Enregistre une tâche one-shot.
  Future<void> registerOneOffTask(String uniqueName, String taskName);
}

/// Use case de planification des occurrences du lendemain.
/// Implémentation injectée — permet isolation en test.
abstract class ScheduleOccurrencesUseCase {
  Future<void> call();
}

/// Use case qui marque les occurrences dépassées en `missed`.
abstract class ExpireOverdueOccurrencesUseCase {
  Future<void> call();
}

/// Abstraction pour replanifier toutes les notifications locales en attente.
/// Appelée au reboot et lors du reschedule window.
abstract class NotificationRescheduler {
  Future<void> rescheduleAll();
}

/// Dispatcher WorkManager — planifie et exécute les tâches background
/// de l'alert system (ADR-018, MOB-005).
///
/// **Trois tâches** :
/// - [kTaskDailyOccurrenceRefresh] : refresh quotidien des occurrences (24h).
/// - [kTaskGraceExpirySweep] : sweep des occurrences expirées (15 min).
/// - [kTaskBootReschedule] : replanification des notifs au reboot.
///
/// **iOS note** : WorkManager utilise BGTaskScheduler sur iOS.
/// - Daily refresh → BGAppRefreshTask (best-effort, ~quelques heures).
/// - Grace sweep (15 min) : non garanti sur iOS — iOS peut délayer ou
///   grouper les tâches. Le sweep sera déclenché opportunistement.
///   L'UI iOS se repose sur le fetch au foreground pour compenser.
///
/// **Architecture** : ce dispatcher ne contient aucune logique métier.
/// Il route les noms de tâches vers les use cases injectés.
class WorkManagerDispatcher {
  static const kTaskDailyOccurrenceRefresh = 'daily_occurrence_refresh';
  static const kTaskGraceExpirySweep = 'grace_expiry_sweep';
  static const kTaskBootReschedule = 'boot_reschedule';

  final WorkManagerRunner _runner;
  final ScheduleOccurrencesUseCase _scheduleOccurrencesUseCase;
  final ExpireOverdueOccurrencesUseCase _expireOverdueUseCase;
  final NotificationRescheduler _notificationRescheduler;
  final Logger _logger;

  WorkManagerDispatcher({
    required WorkManagerRunner runner,
    required ScheduleOccurrencesUseCase scheduleOccurrencesUseCase,
    required ExpireOverdueOccurrencesUseCase expireOverdueUseCase,
    required NotificationRescheduler notificationRescheduler,
    Logger? logger,
  })  : _runner = runner,
        _scheduleOccurrencesUseCase = scheduleOccurrencesUseCase,
        _expireOverdueUseCase = expireOverdueUseCase,
        _notificationRescheduler = notificationRescheduler,
        _logger = logger ?? Logger();

  /// Initialise WorkManager avec le callback dispatcher natif.
  ///
  /// À appeler une seule fois au démarrage de l'app (dans `main()`).
  Future<void> initialize() async {
    await _runner.initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
    _logger.i('WorkManagerDispatcher: initialized');
  }

  /// Enregistre le refresh quotidien des occurrences.
  ///
  /// Fréquence : 24h. Flex : 30 min (OS peut optimiser).
  Future<void> registerDailyRefresh() async {
    await _runner.registerPeriodicTask(
      kTaskDailyOccurrenceRefresh,
      kTaskDailyOccurrenceRefresh,
      frequency: const Duration(hours: 24),
      flexInterval: const Duration(minutes: 30),
    );
    _logger.i('WorkManagerDispatcher: daily refresh registered');
  }

  /// Enregistre le sweep des occurrences expirées.
  ///
  /// Fréquence : 15 min.
  ///
  /// **iOS note** : cette fréquence n'est pas garantie sur iOS (BGTaskScheduler
  /// peut grouper les appels). Le comportement iOS est best-effort.
  Future<void> registerGraceExpirySweep() async {
    await _runner.registerPeriodicTask(
      kTaskGraceExpirySweep,
      kTaskGraceExpirySweep,
      frequency: const Duration(minutes: 15),
      flexInterval: const Duration(minutes: 5),
    );
    _logger.i('WorkManagerDispatcher: grace expiry sweep registered');
  }

  /// Enregistre la replanification des notifications au reboot.
  Future<void> registerBootReschedule() async {
    await _runner.registerOneOffTask(
      kTaskBootReschedule,
      kTaskBootReschedule,
    );
    _logger.i('WorkManagerDispatcher: boot reschedule registered');
  }

  /// Gère l'exécution d'une tâche par son nom.
  ///
  /// Retourne `true` si la tâche s'est exécutée avec succès, `false` sinon.
  /// Un nom de tâche inconnu retourne `false` sans exception.
  Future<bool> handleTask(String taskName) async {
    _logger.d('WorkManagerDispatcher: handling task "$taskName"');
    try {
      switch (taskName) {
        case kTaskDailyOccurrenceRefresh:
          await _scheduleOccurrencesUseCase.call();
          return true;
        case kTaskGraceExpirySweep:
          await _expireOverdueUseCase.call();
          return true;
        case kTaskBootReschedule:
          await _notificationRescheduler.rescheduleAll();
          return true;
        default:
          _logger.w(
            'WorkManagerDispatcher: unknown task "$taskName" — ignoring',
          );
          return false;
      }
    } catch (e, st) {
      _logger.e(
        'WorkManagerDispatcher: task "$taskName" failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}

/// Entry point background WorkManager — top-level function requise par le plugin.
///
/// L'annotation `@pragma('vm:entry-point')` empêche le tree-shaker de
/// supprimer cette fonction dans les builds release.
///
/// **Important** : cette fonction s'exécute dans un isolat Dart séparé.
/// L'accès aux providers Riverpod de l'app principale est impossible.
/// Un conteneur DI minimal doit être reconstruit ici.
@pragma('vm:entry-point')
void callbackDispatcher() {
  // L'implémentation production instanciera WorkManager.executeTask(...)
  // et appellera WorkManagerDispatcher.handleTask(taskName).
  // En V1 : stub — la logique réelle sera connectée lors de l'intégration
  // native (cf. docs/questions/Q-20-workmanager-integration.md).
}
