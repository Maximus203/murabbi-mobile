import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/notification_action.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';

/// Spec d'une notification à planifier via `NotificationService.schedule`.
///
/// Toutes les chaînes (`title`, `body`) sont déjà localisées par le use case
/// appelant — le service de notification ne fait aucune i18n.
///
/// Cf. ADR-018 §4.1.
class ScheduledNotification extends Equatable {
  /// = `Occurrence.id`. Sert d'id de notification natif (hashé) et de payload.
  final String occurrenceId;

  /// Source pour choisir le channel Android et la catégorie iOS.
  final OccurrenceSource source;

  /// Heure prévue (UTC stockée, `flutter_local_notifications.zonedSchedule`
  /// la convertira en `TZDateTime` locale).
  final DateTime scheduledAt;

  /// Titre affiché par l'OS (précalculé i18n par le use case).
  final String title;

  /// Corps affiché par l'OS.
  final String body;

  /// Sous-ensemble des actions à offrir. Cf. ADR-018 §3.2 :
  /// - habitude → `[done, later, dismiss]`
  /// - prière   → `[done, dismiss]` (no `later`)
  final List<NotificationActionId> actions;

  /// Metadata libre (sourceId, deeplink, etc.). Sérialisé en JSON dans le
  /// payload natif. Le service ne valide pas le contenu.
  final Map<String, String> payload;

  const ScheduledNotification({
    required this.occurrenceId,
    required this.source,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.actions,
    this.payload = const {},
  });

  @override
  List<Object?> get props => [
    occurrenceId,
    source,
    scheduledAt,
    title,
    body,
    actions,
    payload,
  ];
}
