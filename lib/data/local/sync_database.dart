import 'package:murabbi_mobile/data/local/pending_sync_item.dart';

/// Interface abstraite de la base SQLite locale pour la sync queue (M2).
///
/// Permet l'injection en test via mock sans dépendre de sqflite.
/// L'implémentation production est [SqfliteSyncDatabase].
///
/// Toutes les opérations sont FIFO — les items sont retournés dans l'ordre
/// de leur [PendingSyncItem.createdAt].
abstract interface class SyncDatabase {
  /// Initialise la base de données (crée la table si nécessaire).
  ///
  /// Doit être appelé une seule fois au démarrage (cf. [SyncService.init]).
  Future<void> init();

  /// Insère un [PendingSyncItem] dans la table `pending_sync_items`.
  Future<void> insert(PendingSyncItem item);

  /// Retourne tous les items dont le [PendingSyncItem.status] est
  /// [SyncItemStatus.pending], triés par [PendingSyncItem.createdAt]
  /// croissant (FIFO strict).
  Future<List<PendingSyncItem>> getPendingItems();

  /// Supprime l'item identifié par [id] (succès ou dead-letter purgé).
  Future<void> delete(String id);

  /// Met à jour un item existant (retry_count, status).
  Future<void> update(PendingSyncItem item);

  /// Libère les ressources (ferme la connexion SQLite).
  Future<void> close();
}
