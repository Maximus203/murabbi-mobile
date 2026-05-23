import 'package:equatable/equatable.dart';

/// Source d'une occurrence : prière (Salat) ou habitude (Habit).
/// Cf. ADR-018 §3.1.
enum OccurrenceSource {
  prayer,
  habit;

  bool get isPrayer => this == OccurrenceSource.prayer;
  bool get isHabit => this == OccurrenceSource.habit;
}

/// Machine à états du cycle de vie d'une occurrence (ADR-018 §4.2).
///
/// - `pending` : planifiée, pas encore firée par l'OS
/// - `fired` : OS a déclenché la notif, en attente d'action utilisateur
/// - `acknowledged` : utilisateur a tappé le body (aucune action) — état
///   transitoire, l'occurrence reste « en attente » jusqu'à action ou expiration
/// - `snoozed` : reportée +30min (max 2 fois, jamais sur prière)
/// - `done` : validée (action `done`), un log métier a été créé
/// - `dismissed` : action `dismiss` — fermée sans logger
/// - `missed` : grace window expirée sans action
/// - `cancelled` : source supprimée (habit deleted, prière désactivée)
/// - `pendingPermissionDenied` : planifiée alors que la permission OS est
///   refusée. Sera replanifiée si la permission est accordée plus tard.
enum OccurrenceStatus {
  pending,
  fired,
  acknowledged,
  snoozed,
  done,
  dismissed,
  missed,
  cancelled,
  pendingPermissionDenied;

  /// États terminaux : aucune action utilisateur ne peut plus les modifier
  /// (sauf `dismissed` → `done` via validation manuelle dashboard, traité
  /// séparément). Cf. ADR-018 §4.2.
  bool get isFinalized =>
      this == OccurrenceStatus.done ||
      this == OccurrenceStatus.missed ||
      this == OccurrenceStatus.cancelled;
}

/// Résultat métier d'une validation utilisateur (ADR-018 §10 Q-OPEN-C).
///
/// - `onTime` : validée dans la fenêtre `[scheduledAt-60s, windowEndsAt]`
/// - `late`   : validée après `windowEndsAt` mais avant `windowEndsAt + 24h`
///   (rattrapage J+1). L'utilisateur perd les points de streak mais gagne
///   les points de complétion.
/// - `missed` : non validée avant `windowEndsAt + 24h` → archived
enum OccurrenceOutcome {
  onTime,
  late,
  missed,
}

/// Origine de l'action de validation (utilisée pour audit + scoring).
enum ValidationSource {
  /// Tap sur action button d'une notification OS.
  notificationAction,

  /// Action depuis l'UI app (dashboard / detail screen).
  app,

  /// Job de batch qui passe en `missed` les occurrences expirées.
  autoExpire,

  /// Validation rattrapage J+1 depuis le dashboard.
  catchup,
}

/// Occurrence unique d'une alerte. Représente l'engagement « à l'instant T,
/// l'utilisateur doit être notifié pour l'item X (prière ou habitude) ».
///
/// Modèle unifié prière + habitude (ADR-018 §3.1).
class Occurrence extends Equatable {
  /// UUID v4 — sert aussi de payload de notification.
  final String id;

  /// Type d'item amont (prière ou habitude).
  final OccurrenceSource source;

  /// Id de l'item amont : `habit_id` (UUID) ou `prayer_id` (constante
  /// `fajr|dhuhr|asr|maghrib|isha`).
  final String sourceId;

  /// Owner de l'occurrence.
  final String userId;

  /// Heure prévue de la notification (stockée en UTC).
  final DateTime scheduledAt;

  /// Fin de la grace window (CDC §5). Au-delà, l'occurrence devient `missed`
  /// par le job `MarkMissedOccurrencesUseCase`.
  final DateTime windowEndsAt;

  /// État courant dans la machine à états ADR-018 §4.2.
  final OccurrenceStatus status;

  /// Outcome métier — null tant que l'occurrence n'est pas validée/missed.
  final OccurrenceOutcome? outcome;

  /// Compteur de reports utilisateur (0..2, cf. ADR-018 §3.3).
  /// **Doit rester 0 si `source == prayer`** (CHECK SQL backstop).
  final int snoozeCount;

  /// Prochain horodatage de fire (null si pas snoozée).
  final DateTime? nextFireAt;

  /// Horodatage réel du déclenchement OS de la notif.
  final DateTime? firedAt;

  /// Horodatage de l'action utilisateur.
  final DateTime? actedAt;

  /// Origine de l'action de validation (renseignée si `outcome` non-null).
  final ValidationSource? validationSource;

  /// Payload libre sérialisé en JSON (titre/body précalculés, deeplink, etc.).
  final Map<String, String> payload;

  /// Timezone du device au moment de la planification (audit DST cf. ADR-018
  /// §3.5).
  final String? deviceTimezone;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Occurrence({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.userId,
    required this.scheduledAt,
    required this.windowEndsAt,
    required this.status,
    required this.snoozeCount,
    required this.createdAt,
    required this.updatedAt,
    this.outcome,
    this.nextFireAt,
    this.firedAt,
    this.actedAt,
    this.validationSource,
    this.payload = const {},
    this.deviceTimezone,
  }) : assert(
         snoozeCount >= 0 && snoozeCount <= 2,
         'snoozeCount must be in [0,2] (ADR-018 §3.3)',
       );

  /// Maximum de snooze autorisés (ADR-018 §3.3).
  static const int maxSnoozes = 2;

  /// Délai d'un snooze (ADR-018 §3.3).
  static const Duration snoozeDuration = Duration(minutes: 30);

  /// Fenêtre de rattrapage J+1 (ADR-018 §10 Q-OPEN-C).
  static const Duration lateCatchupGrace = Duration(hours: 24);

  /// Tolérance pour considérer une validation comme onTime même si elle est
  /// déclenchée juste avant `scheduledAt` (latence OS + clic utilisateur).
  static const Duration onTimeLead = Duration(seconds: 60);

  Occurrence copyWith({
    OccurrenceStatus? status,
    OccurrenceOutcome? outcome,
    int? snoozeCount,
    DateTime? nextFireAt,
    DateTime? firedAt,
    DateTime? actedAt,
    ValidationSource? validationSource,
    Map<String, String>? payload,
    String? deviceTimezone,
    DateTime? updatedAt,
  }) {
    return Occurrence(
      id: id,
      source: source,
      sourceId: sourceId,
      userId: userId,
      scheduledAt: scheduledAt,
      windowEndsAt: windowEndsAt,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      nextFireAt: nextFireAt ?? this.nextFireAt,
      firedAt: firedAt ?? this.firedAt,
      actedAt: actedAt ?? this.actedAt,
      validationSource: validationSource ?? this.validationSource,
      payload: payload ?? this.payload,
      deviceTimezone: deviceTimezone ?? this.deviceTimezone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    source,
    sourceId,
    userId,
    scheduledAt,
    windowEndsAt,
    status,
    outcome,
    snoozeCount,
    nextFireAt,
    firedAt,
    actedAt,
    validationSource,
    payload,
    deviceTimezone,
    createdAt,
    updatedAt,
  ];
}
