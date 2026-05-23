/// Type d'opération offline pouvant être mis en queue (BUG-002).
///
/// Cf. issue #182 : les actions utilisateur hors connexion doivent être
/// persistées et rejouées au retour du réseau.
enum OfflineOperationType {
  /// Validation d'une occurrence (tap « Valider » hors ligne).
  validateOccurrence,

  /// Snooze d'une occurrence (tap « Plus tard » hors ligne).
  snoozeOccurrence,

  /// Mise à jour d'un log habitude (valeur, durée, sous-tâches).
  updateHabitLog,
}

/// Opération offline persistée en attente de replay.
///
/// Chaque opération a un identifiant stable, un type, un payload générique,
/// une date d'enqueue et un compteur de retries.
///
/// Lifecycle :
/// - `retryCount < 3` + `deadLetter == false` → rejoué à chaque reconnexion.
/// - `retryCount == 3` → `deadLetter = true` → exclu du replay, notifie
///   l'utilisateur (cf. [OfflineQueueService] §dead-letter).
class OfflineOperation {
  /// Identifiant unique de l'opération (UUID v4 recommandé).
  final String id;

  /// Type de l'opération.
  final OfflineOperationType type;

  /// Données de l'opération (structure dépend de [type]).
  final Map<String, dynamic> payload;

  /// Moment de mise en queue (UTC).
  final DateTime enqueuedAt;

  /// Nombre de tentatives échouées.
  final int retryCount;

  /// Si `true`, l'opération a dépassé le max de retries et est en dead-letter.
  /// Elle n'est plus rejouée mais reste dans le storage pour audit.
  final bool deadLetter;

  const OfflineOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.enqueuedAt,
    required this.retryCount,
    required this.deadLetter,
  });

  /// Sérialise l'opération en JSON pour la persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'enqueuedAt': enqueuedAt.toIso8601String(),
    'retryCount': retryCount,
    'deadLetter': deadLetter,
  };

  /// Désérialise depuis JSON (ex: lecture depuis `flutter_secure_storage`).
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] as String,
      type: OfflineOperationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => OfflineOperationType.validateOccurrence,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      enqueuedAt: DateTime.parse(json['enqueuedAt'] as String),
      retryCount: json['retryCount'] as int,
      deadLetter: json['deadLetter'] as bool,
    );
  }

  /// Retourne une copie avec [retryCount] incrémenté.
  OfflineOperation incrementRetry() => OfflineOperation(
    id: id,
    type: type,
    payload: payload,
    enqueuedAt: enqueuedAt,
    retryCount: retryCount + 1,
    deadLetter: retryCount + 1 >= OfflineQueueConfig.maxRetries,
  );

  @override
  String toString() =>
      'OfflineOperation($id, $type, retries=$retryCount, dead=$deadLetter)';
}

/// Configuration de la queue offline.
abstract final class OfflineQueueConfig {
  /// Nombre maximal de retries avant dead-letter (spec BUG-002).
  static const int maxRetries = 3;
}
