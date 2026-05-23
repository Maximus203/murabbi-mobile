import 'package:equatable/equatable.dart';

/// Identifiants des trois actions possibles sur une notification
/// (ADR-018 §3.2).
///
/// - `done` : valider (log onTime/late selon timing)
/// - `later` : reporter +30min (jamais offert sur prière, BUG-004)
/// - `dismiss` : fermer sans logger
enum NotificationActionId { done, later, dismiss }

/// État de la permission OS notifications.
enum NotificationPermissionStatus { granted, denied, notDetermined }

/// Évènement émis sur `NotificationService.actionStream` quand l'utilisateur
/// agit sur une notification (tap body ou tap action button).
///
/// Le payload contient les metadata sérialisées lors de la planification
/// (sourceId, deeplink, etc. — cf. `ScheduledNotification.payload`).
class NotificationAction extends Equatable {
  /// UUID de l'occurrence cible (route vers `OccurrenceRepository.findById`).
  final String occurrenceId;

  /// Action utilisateur déclenchée.
  final NotificationActionId actionId;

  /// Horodatage de réception du callback OS.
  final DateTime receivedAt;

  /// Payload arbitraire (déserialisé du JSON natif).
  final Map<String, String> payload;

  const NotificationAction({
    required this.occurrenceId,
    required this.actionId,
    required this.receivedAt,
    this.payload = const {},
  });

  @override
  List<Object?> get props => [occurrenceId, actionId, receivedAt, payload];
}
