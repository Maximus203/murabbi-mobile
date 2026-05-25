import 'dart:convert';

/// Type d'opération en attente de synchronisation (M2 — issue #200).
enum SyncItemType {
  /// Log d'habitude (habit_logs).
  logHabit,

  /// Log de prière (prayer_logs).
  logPrayer,
}

/// Statut d'un item dans la sync queue.
enum SyncItemStatus {
  /// En attente de traitement ou de retry.
  pending,

  /// Échec permanent (maxRetries atteint) — dead-letter.
  failed,
}

/// Item persisté dans la table `pending_sync_items` (SQLite via sqflite).
///
/// Représente une opération utilisateur en attente de synchronisation avec
/// Supabase. Quand l'utilisateur valide une habitude hors ligne, un
/// [PendingSyncItem] est créé immédiatement (optimistic UI). Le [SyncService]
/// le rejoue dès que la connexion revient.
///
/// **Politique de retry** :
/// - Succès → supprimé de la queue.
/// - Échec et `retryCount < maxRetries` → `incrementRetry()`.
/// - Échec et `retryCount >= maxRetries` → `status = failed` (dead-letter),
///   UI notifie l'utilisateur.
/// - PostgrestException code '23505' (doublon UNIQUE) → succès silencieux
///   (idempotence M4).
class PendingSyncItem {
  /// Nombre maximal de tentatives avant passage en dead-letter.
  static const int maxRetries = 3;

  /// Identifiant unique de l'item (UUID).
  final String id;

  /// Type d'opération (logHabit | logPrayer).
  final SyncItemType type;

  /// Payload JSON arbitraire contenant les paramètres de l'opération.
  ///
  /// Pour `logHabit` : `{habitId, userId, status, date, ...}`.
  /// Pour `logPrayer` : `{prayerName, userId, status, date, ...}`.
  final Map<String, dynamic> payload;

  /// Horodatage de création de l'item (pour l'ordre FIFO).
  final DateTime createdAt;

  /// Nombre de tentatives effectuées.
  final int retryCount;

  /// Statut courant de l'item.
  final SyncItemStatus status;

  const PendingSyncItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncItemStatus.pending,
  });

  /// `true` si l'item est en dead-letter (échec permanent).
  bool get isFailed => status == SyncItemStatus.failed;

  /// `true` si l'item est eligible au replay.
  bool get isPending => status == SyncItemStatus.pending;

  /// Retourne une copie avec [retryCount] incrémenté.
  ///
  /// Si [retryCount] atteint [maxRetries], [status] passe à
  /// [SyncItemStatus.failed] (dead-letter).
  PendingSyncItem incrementRetry() {
    final newCount = retryCount + 1;
    return copyWith(
      retryCount: newCount,
      status: newCount >= maxRetries
          ? SyncItemStatus.failed
          : SyncItemStatus.pending,
    );
  }

  /// Copie avec surcharge de champs.
  PendingSyncItem copyWith({
    String? id,
    SyncItemType? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    SyncItemStatus? status,
  }) {
    return PendingSyncItem(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
    );
  }

  /// Sérialise vers une Map compatible avec sqflite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': jsonEncode(payload),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'status': status.name,
    };
  }

  /// Désérialise depuis une Map sqflite.
  factory PendingSyncItem.fromMap(Map<String, dynamic> map) {
    return PendingSyncItem(
      id: map['id'] as String,
      type: SyncItemType.values.byName(map['type'] as String),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int,
      status: SyncItemStatus.values.byName(map['status'] as String),
    );
  }

  @override
  String toString() =>
      'PendingSyncItem(id: $id, type: ${type.name}, '
      'retryCount: $retryCount, status: ${status.name})';
}
