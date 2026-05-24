import 'dart:async';

import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/local/pending_sync_item.dart';
import 'package:murabbi_mobile/data/local/sync_database.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:uuid/uuid.dart';

/// Service de synchronisation offline ↔ Supabase (M2 — issue #200).
///
/// **Pattern Optimistic UI** :
/// 1. L'UI met à jour l'état immédiatement (dans le notifier appelant).
/// 2. [enqueueLogHabit] persiste l'opération en SQLite sans appel réseau.
/// 3. [processPendingQueue] rejoue les items FIFO quand la connexion revient.
///
/// **Gestion des erreurs** :
/// - Succès → item supprimé de la queue.
/// - Erreur transitoire → [PendingSyncItem.incrementRetry].
/// - PostgrestException code '23505' (doublon UNIQUE — idempotence M4) →
///   supprimé silencieusement (pas d'erreur UI).
/// - Après [PendingSyncItem.maxRetries] échecs → item marque `failed`
///   (dead-letter) et un événement est émis sur [deadLetterStream].
///
/// **Architecture** :
/// - [SyncDatabase] est injecté → testable sans sqflite.
/// - [HabitRepository] est injecté → testable sans Supabase.
/// - Le [SyncService] lui-même ne dépend d'aucun provider Riverpod —
///   il est wrappé dans [syncServiceProvider] dans la couche présentation.
class SyncService {
  final SyncDatabase _db;
  final HabitRepository _habitRepository;

  final _pendingCountController = StreamController<int>.broadcast();
  final _deadLetterController = StreamController<PendingSyncItem>.broadcast();

  static const _tag = 'SyncService';

  SyncService({
    required SyncDatabase db,
    required HabitRepository habitRepository,
  }) : _db = db,
       _habitRepository = habitRepository;

  // ── Streams publics ─────────────────────────────────────────────────────────

  /// Émet le nombre d'items en attente après chaque [enqueueLogHabit] ou
  /// [processPendingQueue].
  ///
  /// L'UI peut consommer ce stream pour afficher un badge ou un banner
  /// "X en attente de sync".
  Stream<int> get pendingCount async* {
    final pending = await _db.getPendingItems();
    yield pending.length;
    yield* _pendingCountController.stream;
  }

  /// Émet un [PendingSyncItem] quand il atteint le statut `failed`
  /// (dead-letter après [PendingSyncItem.maxRetries] tentatives).
  ///
  /// L'UI doit afficher un message du type :
  /// "Une action n'a pas pu être synchronisée. Ouvre l'habitude pour réessayer."
  Stream<PendingSyncItem> get deadLetterStream => _deadLetterController.stream;

  // ── Enqueue ─────────────────────────────────────────────────────────────────

  /// Met en queue un log d'habitude pour sync différée.
  ///
  /// **Garanties** :
  /// - Aucun appel réseau — garanti.
  /// - L'item est persisté avant le retour de la fonction.
  /// - [retryCount] et [status] initiaux : 0 / pending.
  Future<void> enqueueLogHabit({
    required String habitId,
    required String userId,
    required HabitLogStatus status,
    required DateTime date,
    int? actualValue,
  }) async {
    final item = PendingSyncItem(
      id: const Uuid().v4(),
      type: SyncItemType.logHabit,
      payload: {
        'habitId': habitId,
        'userId': userId,
        'status': status.name,
        'date': date.toIso8601String(),
        'actualValue': actualValue,
      },
      createdAt: DateTime.now().toUtc(),
    );

    await _db.insert(item);
    appLog.d('$_tag: enqueued logHabit $habitId (id=${item.id})');

    // Mise à jour du stream pendingCount.
    final pending = await _db.getPendingItems();
    _pendingCountController.add(pending.length);
  }

  // ── Replay ──────────────────────────────────────────────────────────────────

  /// Rejoue tous les items en attente dans l'ordre FIFO.
  ///
  /// Appelé :
  /// - Immédiatement après [enqueueLogHabit] si l'app est online.
  /// - Quand [connectivityProvider] passe de `false` à `true`.
  Future<void> processPendingQueue() async {
    final items = await _db.getPendingItems();
    if (items.isEmpty) return;

    appLog.i('$_tag: processing ${items.length} pending item(s)');

    for (final item in items) {
      await _processItem(item);
    }

    // Mise à jour du stream pendingCount.
    final remaining = await _db.getPendingItems();
    _pendingCountController.add(remaining.length);
  }

  // ── Libération des ressources ───────────────────────────────────────────────

  /// Ferme les streams et la connexion DB.
  void dispose() {
    _pendingCountController.close();
    _deadLetterController.close();
  }

  // ── Privé ───────────────────────────────────────────────────────────────────

  Future<void> _processItem(PendingSyncItem item) async {
    try {
      switch (item.type) {
        case SyncItemType.logHabit:
          await _replayLogHabit(item);
        case SyncItemType.logPrayer:
          // Extension point — prayer log sync (futur).
          appLog.w('$_tag: logPrayer replay not yet implemented');
      }
      await _db.delete(item.id);
      appLog.i('$_tag: replayed ${item.id} — deleted');
    } on _UniqueConstraintException {
      // PostgrestException code '23505' — doublon UNIQUE (M4 idempotence).
      // L'opération a déjà été exécutée (ex: double tap avant queue).
      // On supprime silencieusement : pas d'erreur UI.
      await _db.delete(item.id);
      appLog.d(
        '$_tag: item ${item.id} skipped — UNIQUE constraint (23505), '
        'deleted silently',
      );
    } catch (e, st) {
      await _onFailure(item, e, st);
    }
  }

  Future<void> _replayLogHabit(PendingSyncItem item) async {
    final habitId = item.payload['habitId'] as String;
    final statusName = item.payload['status'] as String;
    final dateStr = item.payload['date'] as String;

    final log = HabitLog(
      habitId: HabitId(habitId),
      date: DateTime.parse(dateStr).toUtc(),
      status: HabitLogStatus.values.byName(statusName),
    );

    try {
      await _habitRepository.logHabit(log);
    } catch (e) {
      // Détecte un doublon UNIQUE (code '23505') — wrappé pour isoler
      // l'import supabase_flutter hors du domaine.
      if (_is23505(e)) throw const _UniqueConstraintException();
      rethrow;
    }
  }

  Future<void> _onFailure(PendingSyncItem item, Object e, StackTrace st) async {
    final updated = item.incrementRetry();
    await _db.update(updated);

    if (updated.isFailed) {
      appLog.e(
        '$_tag: dead-letter ${item.id} after ${updated.retryCount} retries',
        error: e,
        stackTrace: st,
      );
      if (!_deadLetterController.isClosed) {
        _deadLetterController.add(updated);
      }
    } else {
      appLog.w(
        '$_tag: retry ${updated.retryCount}/${PendingSyncItem.maxRetries} '
        'for ${item.id}',
        error: e,
      );
    }
  }

  /// Détecte un PostgrestException code '23505' sans importer supabase_flutter.
  ///
  /// On utilise la réflexion duck-typing (accès au champ `code` via toString
  /// ou via runtimeType.toString) pour rester découplé du package Supabase
  /// dans cette couche service — l'import direct est interdit en domain/service.
  bool _is23505(Object e) {
    // Duck-typing sur le champ `code` de PostgrestException.
    try {
      // ignore: avoid_dynamic_calls
      final code = (e as dynamic).code as String?;
      return code == '23505';
    } catch (_) {
      return e.toString().contains('23505');
    }
  }
}

/// Exception interne pour signaler un doublon UNIQUE 23505.
///
/// Isole le code 23505 sans propager l'exception Supabase native.
class _UniqueConstraintException implements Exception {
  const _UniqueConstraintException();
}
