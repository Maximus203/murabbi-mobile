import 'package:murabbi_mobile/domain/entities/notification_action.dart';
import 'package:murabbi_mobile/domain/entities/scheduled_notification.dart';

/// Contrat figé du service de notifications locales (ADR-018 §4.1).
///
/// Une seule implémentation autorisée : `LocalNotificationService` dans
/// `lib/services/notification/` (seul module à pouvoir importer
/// `package:flutter_local_notifications/...`).
///
/// Les use cases du système d'alertes consomment uniquement cette interface
/// (cf. ADR-018 §3 / §4.3 router).
abstract interface class NotificationService {
  /// Initialise le plugin natif : channels Android, catégories iOS,
  /// timezone data, callbacks d'action. À appeler une seule fois au
  /// démarrage, avant tout autre appel.
  Future<void> initialize();

  /// Demande la permission OS. Retourne `true` si accordée, `false` sinon.
  /// No-op (renvoie l'état actuel) si déjà demandée précédemment.
  Future<bool> requestPermission();

  /// État actuel de la permission OS (sans la redemander).
  Future<NotificationPermissionStatus> permissionStatus();

  /// Planifie ou re-planifie une notification pour une occurrence donnée.
  ///
  /// Idempotent : re-appeler avec le même `occurrenceId` annule la
  /// notification précédente et en planifie une nouvelle.
  Future<void> schedule(ScheduledNotification spec);

  /// Annule la notification pour une occurrence. Pas d'erreur si l'id
  /// n'avait rien de planifié (utilisé par cycle de vie inverse BUG-002).
  Future<void> cancel(String occurrenceId);

  /// Annule **toutes** les notifications planifiées (purge complète, ex:
  /// logout, révocation permission).
  Future<void> cancelAll();

  /// Stream des actions utilisateur reçues. Émet un évènement à chaque tap
  /// sur action button (done/later/dismiss) OU sur le body de la
  /// notification (action implicite `done`).
  ///
  /// Doit être un broadcast stream — plusieurs subscribers possibles
  /// (router de validation + listener d'invalidation cache UI).
  Stream<NotificationAction> get actionStream;
}
