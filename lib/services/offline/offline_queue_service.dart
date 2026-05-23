import 'dart:async';
import 'dart:convert';

import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/services/offline/offline_operation.dart';

/// Abstraction du stockage persistent utilisé par [OfflineQueueService].
///
/// L'implémentation prod utilise `flutter_secure_storage` (cf. BUG-002 spec
/// — jamais SharedPreferences pour des données potentiellement sensibles).
/// Les tests injectent un [MockOfflineStorage].
abstract interface class OfflineStorage {
  /// Lit la valeur associée à [key]. Retourne `null` si absente.
  Future<String?> read(String key);

  /// Écrit [value] pour [key].
  Future<void> write({required String key, required String value});
}

/// Service de queue offline persistante (BUG-002, issue #182).
///
/// Quand l'utilisateur valide une habitude / snooze une occurrence sans
/// connexion, l'action est enfilée ici et rejouée en FIFO au retour du réseau.
///
/// Règles :
/// - FIFO strict (insertion → replay dans l'ordre).
/// - Max [OfflineQueueConfig.maxRetries] tentatives (3). Au-delà : dead-letter.
/// - Dead-letters : marquées `deadLetter=true`, exclues du replay et du
///   [pendingCount], conservées pour audit.
/// - Persistence : [OfflineStorage] (implémenté prod par `flutter_secure_storage`).
/// - Pas d'appel réseau dans [enqueue] — garanti par la séparation des concerns.
///
/// Intégration avec [connectivity_plus] :
/// ```dart
/// Connectivity().onConnectivityChanged.listen((status) async {
///   if (status != ConnectivityResult.none) {
///     await offlineQueueService.replayAll(executor: _executor);
///   }
/// });
/// ```
class OfflineQueueService {
  /// Clé de persistence dans le storage.
  static const String storageKey = 'offline_queue_v1';

  final OfflineStorage _storage;
  final _pendingCountController = StreamController<int>.broadcast();

  OfflineQueueService({required OfflineStorage storage}) : _storage = storage;

  /// Stream du nombre d'opérations en attente (hors dead-letters).
  ///
  /// Émet une nouvelle valeur après chaque [enqueue] et chaque [replayAll].
  Stream<int> get pendingCount async* {
    // Émet la valeur courante immédiatement à l'abonnement.
    final queue = await _loadQueue();
    yield queue.where((op) => !op.deadLetter).length;
    yield* _pendingCountController.stream;
  }

  /// Met une opération en queue.
  ///
  /// Lit la queue existante, ajoute [operation] en fin de liste (FIFO), puis
  /// persiste. Ne tente aucune connexion réseau — garanti.
  Future<void> enqueue(OfflineOperation operation) async {
    final queue = await _loadQueue();
    queue.add(operation);
    await _saveQueue(queue);
    appLog.d(
      'OfflineQueueService: enqueued ${operation.id} (${operation.type.name})',
    );
    _emitPendingCount(queue);
  }

  /// Rejoue toutes les opérations en attente dans l'ordre FIFO.
  ///
  /// [executor] est la fonction de replay (ex: appel Supabase). Elle reçoit
  /// chaque [OfflineOperation] et doit lever une exception si l'exécution
  /// échoue.
  ///
  /// Pour chaque opération :
  /// - Succès → retirée de la queue.
  /// - Échec et `retryCount < maxRetries` → `retryCount++`, remise en queue.
  /// - Échec et `retryCount >= maxRetries` → `deadLetter=true`, remise en
  ///   queue (pour audit) mais exclue des replays futurs.
  Future<void> replayAll({
    required Future<void> Function(OfflineOperation) executor,
  }) async {
    final queue = await _loadQueue();
    if (queue.isEmpty) return;

    // Sépare les actives et les dead-letters.
    final active = queue.where((op) => !op.deadLetter).toList();
    final deadLetters = queue.where((op) => op.deadLetter).toList();

    final surviving = <OfflineOperation>[...deadLetters];

    for (final op in active) {
      try {
        await executor(op);
        appLog.i('OfflineQueueService: replayed ${op.id} successfully');
        // Succès : on ne remet pas l'op dans surviving (retirée).
      } catch (e, st) {
        final updated = op.incrementRetry();
        surviving.add(updated);
        if (updated.deadLetter) {
          appLog.e(
            'OfflineQueueService: dead-letter ${op.id} after '
            '${updated.retryCount} retries',
            error: e,
            stackTrace: st,
          );
        } else {
          appLog.w(
            'OfflineQueueService: retry ${updated.retryCount}/'
            '${OfflineQueueConfig.maxRetries} for ${op.id}',
            error: e,
          );
        }
      }
    }

    await _saveQueue(surviving);
    _emitPendingCount(surviving);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<List<OfflineOperation>> _loadQueue() async {
    final raw = await _storage.read(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(OfflineOperation.fromJson).toList();
    } catch (e, st) {
      appLog.e(
        'OfflineQueueService: failed to parse queue — resetting',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<void> _saveQueue(List<OfflineOperation> queue) async {
    final json = jsonEncode(queue.map((op) => op.toJson()).toList());
    await _storage.write(key: storageKey, value: json);
  }

  void _emitPendingCount(List<OfflineOperation> queue) {
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(queue.where((op) => !op.deadLetter).length);
    }
  }

  /// Libère les ressources du service.
  void dispose() {
    _pendingCountController.close();
  }
}
