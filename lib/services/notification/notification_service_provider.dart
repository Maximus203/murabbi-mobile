import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/services/notification_service.dart';
import 'package:murabbi_mobile/services/notification/flutter_local_notification_platform.dart';
import 'package:murabbi_mobile/services/notification/local_notification_service.dart';
import 'package:murabbi_mobile/services/notification/notification_platform.dart';

/// Provider du [NotificationPlatform] concret basé sur
/// `flutter_local_notifications`. Singleton — pas d'état Dart mutable
/// au-delà du callback `onActionReceived`.
///
/// Surchargeable en test via `ProviderScope(overrides: [...])`.
final notificationPlatformProvider = Provider<NotificationPlatform>((ref) {
  return FlutterLocalNotificationPlatform();
});

/// Provider du [NotificationService] domain (ADR-018 §4.1).
///
/// Consommé par les use cases d'alertes (Schedule* / Complete /
/// Snooze / Dismiss) via `ref.read` et par le router de notifications
/// pour écouter `actionStream`.
///
/// L'appel à `initialize()` doit être fait au démarrage de l'app (cf.
/// `main.dart` — MOB-005 câblera l'init dans la séquence boot).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final platform = ref.watch(notificationPlatformProvider);
  return LocalNotificationService(platform: platform);
});
