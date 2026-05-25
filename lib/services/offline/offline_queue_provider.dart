import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/services/offline/offline_queue_service.dart';

/// Adaptateur prod : [OfflineStorage] wrappé sur [FlutterSecureStorage].
///
/// Respecte la règle S-1 (§11 CLAUDE.md) : les données de queue sont
/// stockées dans le secure storage, jamais dans SharedPreferences.
class _SecureOfflineStorage implements OfflineStorage {
  final FlutterSecureStorage _storage;

  const _SecureOfflineStorage(this._storage);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);
}

/// Provider singleton de l'[OfflineQueueService] (BUG-002).
///
/// Injecte [FlutterSecureStorage] comme backend de persistence.
/// Dispose le service (ferme le StreamController) quand le container est
/// détruit (logout).
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  // ignore: prefer_const_constructors
  final secureStorage = FlutterSecureStorage();
  final service = OfflineQueueService(
    storage: _SecureOfflineStorage(secureStorage),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Stream du nombre d'opérations offline en attente.
///
/// Utilisé par [OfflineSyncBanner] pour afficher « X action(s) en attente de sync ».
final offlinePendingCountProvider = StreamProvider<int>((ref) {
  return ref.watch(offlineQueueServiceProvider).pendingCount;
});

/// Service de surveillance de la connectivité et déclencheur du replay.
///
/// Écoute [Connectivity.onConnectivityChanged] et déclenche
/// [OfflineQueueService.replayAll] au retour du réseau.
///
/// **Note** : le [executor] par défaut est un no-op — les use cases réels
/// doivent être injectés via l'override du provider (ex: dans les tests) ou
/// via [initConnectivityReplay].
class ConnectivityReplayService {
  final OfflineQueueService _queueService;
  final Connectivity _connectivity;

  ConnectivityReplayService({
    required OfflineQueueService queueService,
    Connectivity? connectivity,
  }) : _queueService = queueService,
       _connectivity = connectivity ?? Connectivity();

  /// Démarre l'écoute et configure le replay.
  ///
  /// [executor] est la fonction de replay injectée par le caller. Elle reçoit
  /// chaque [OfflineOperation] et doit lever une exception si l'exécution
  /// échoue.
  void startListening({
    required Future<void> Function(dynamic operation) executor,
  }) {
    _connectivity.onConnectivityChanged.listen((results) async {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        appLog.i(
          'ConnectivityReplayService: network restored — replaying queue',
        );
        await _queueService.replayAll(executor: executor);
      }
    });
  }
}

/// Provider du [ConnectivityReplayService].
final connectivityReplayServiceProvider = Provider<ConnectivityReplayService>((
  ref,
) {
  return ConnectivityReplayService(
    queueService: ref.watch(offlineQueueServiceProvider),
  );
});
