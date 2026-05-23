import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart'
    show OccurrenceStatus;
export 'package:murabbi_mobile/domain/entities/occurrence.dart'
    show OccurrenceStatus;

/// Représente une occurrence planifiée d'habitude (ou de prière).
///
/// Une notification = une occurrence persistée. Cf. ADR-018 §3.1.
///
/// **Invariants** :
/// - [snoozeCount] ∈ [0, 2] (cf. ADR-018 §3.3).
/// - [snoozedUntil] non-null si et seulement si [status] == [OccurrenceStatus.snoozed].
/// - [windowEndsAt] > [scheduledAt].
class HabitOccurrence extends Equatable {
  /// Identifiant stable de l'occurrence (UUID).
  /// Tronqué en [int] pour servir de notificationId (flutter_local_notifications).
  final String id;

  /// Identifiant de l'habitude source (`habit_id`).
  final String habitId;

  /// Identifiant de l'utilisateur propriétaire.
  final String userId;

  /// Heure planifiée de déclenchement de la notification (UTC).
  final DateTime scheduledAt;

  /// Fin de la grace window (CDC §5 — 23:59 du même jour local, stocké UTC).
  final DateTime windowEndsAt;

  /// Statut de cycle de vie de l'occurrence.
  final OccurrenceStatus status;

  /// Nombre de reports consécutifs (0 à 2).
  final int snoozeCount;

  /// Prochaine heure de déclenchement après un report (null si pas snoozed).
  final DateTime? snoozedUntil;

  /// Horodatage réel du déclenchement OS (null si pas encore fired).
  final DateTime? firedAt;

  /// Horodatage de l'action utilisateur (null si pas encore agi).
  final DateTime? actedAt;

  /// Métadonnées libres (titre, body précalculés, deeplink).
  final Map<String, dynamic>? payloadJson;

  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitOccurrence({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.scheduledAt,
    required this.windowEndsAt,
    required this.status,
    required this.snoozeCount,
    this.snoozedUntil,
    this.firedAt,
    this.actedAt,
    this.payloadJson,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    habitId,
    userId,
    scheduledAt,
    windowEndsAt,
    status,
    snoozeCount,
    snoozedUntil,
    firedAt,
    actedAt,
    payloadJson,
    createdAt,
    updatedAt,
  ];
}
