import 'package:murabbi_mobile/domain/entities/notification_action.dart';

/// Requête de planification envoyée au plugin natif. Forme normalisée
/// indépendante de `flutter_local_notifications` pour permettre le test
/// unitaire du `LocalNotificationService` sans toucher au plugin réel.
///
/// Cf. ADR-018 §4.1.
class PlatformScheduleRequest {
  /// ID natif (int32) — hash stable de `occurrenceId` côté service.
  final int notificationId;

  /// Titre déjà localisé.
  final String title;

  /// Body déjà localisé.
  final String body;

  /// Heure prévue (UTC ; le platform impl convertit en TZDateTime local).
  final DateTime scheduledAt;

  /// Actions à afficher (sous-ensemble de done/later/dismiss).
  final List<NotificationActionId> actions;

  /// Payload sérialisé (JSON string) — contient `occurrenceId` + metadata
  /// libres injectées par le use case appelant.
  final String payload;

  const PlatformScheduleRequest({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.actions,
    required this.payload,
  });
}

/// Adapter testable autour de `flutter_local_notifications`. Seule l'impl
/// concrète (`FlutterLocalNotificationPlatform`) importe le plugin.
///
/// Le `LocalNotificationService` consomme uniquement cette interface — ce
/// qui permet le test unitaire via mocktail sans device.
abstract interface class NotificationPlatform {
  /// Initialise channels Android, catégories iOS, timezone, et enregistre
  /// le callback d'action. Le callback est appelé chaque fois que l'OS
  /// remonte une action utilisateur (cold ou warm start).
  Future<void> initialize({
    required void Function(NotificationAction action) onActionReceived,
  });

  Future<bool> requestPermission();

  Future<NotificationPermissionStatus> permissionStatus();

  Future<void> schedule(PlatformScheduleRequest request);

  Future<void> cancel(int notificationId);

  Future<void> cancelAll();
}
