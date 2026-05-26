import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contrat de domain pour observer la connectivité réseau (issue #195 — M11).
///
/// Pure interface — l'impl `connectivity_plus` vit dans
/// `connectivity_plus_service.dart` et reste isolée (le reste de l'app ne
/// doit jamais importer `package:connectivity_plus/...` directement,
/// patterns ADR-013/014).
abstract interface class ConnectivityService {
  /// Statut courant — `true` si au moins une interface réseau est active.
  Future<bool> isOnline();

  /// Flux des changements de statut. N'émet pas le statut initial : le
  /// provider Riverpod le combine lui-même via [isOnline].
  Stream<bool> onConnectivityChanged();
}

/// Impl `connectivity_plus`. Mappe `List<ConnectivityResult>` → `bool`
/// (online = au moins une interface != `ConnectivityResult.none`).
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnlineFromResults(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnlineFromResults(results);
  }

  @override
  Stream<bool> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map(_isOnlineFromResults);
  }
}

/// Service connectivité — injectable pour tests via
/// `overrideWithValue(...)`.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityPlusService();
});

/// Statut connectivité courant (issue #195 — M11).
///
/// Émet d'abord le statut initial (via [ConnectivityService.isOnline]) puis
/// relaie tous les changements ultérieurs. L'UI consomme via
/// `ref.watch(connectivityProvider).valueOrNull ?? true` (on assume online
/// tant qu'on n'a pas la réponse, pour éviter un flash de bannière).
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline();
  yield* service.onConnectivityChanged();
});
