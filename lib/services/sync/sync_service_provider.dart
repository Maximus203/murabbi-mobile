import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/local/sqflite_sync_database.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/services/sync/sync_service.dart';

/// Provider du [SyncService] — singleton de l'app (M2 — issue #200).
///
/// La base SQLite ([SqfliteSyncDatabase]) est créée et initialisée lors de
/// la construction du provider. Le fichier DB est ouvert dans le répertoire
/// de données de l'app (`getDatabasesPath()`).
///
/// **Override en test** : injecter un [SyncService] avec un mock de
/// [SyncDatabase] via `syncServiceProvider.overrideWithValue(...)`.
///
/// **Lifecycle** : [ref.onDispose] ferme les streams du service.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = SqfliteSyncDatabase();
  final habitRepo = ref.watch(habitRepositoryProvider);

  // On capture le Future d'init pour que SyncService puisse l'await avant
  // tout accès DB — évite la race condition au démarrage (app.dart initState
  // appelle processPendingQueue avant que init() ait résolu).
  final initFuture = db.init().catchError(
    // ignore: avoid_types_on_closure_parameters
    (Object e, StackTrace st) {
      // L'erreur est loggée par SqfliteSyncDatabase — pas d'action ici.
    },
  );

  final service = SyncService(
    db: db,
    habitRepository: habitRepo,
    initFuture: initFuture,
  );

  ref.onDispose(service.dispose);

  return service;
});
