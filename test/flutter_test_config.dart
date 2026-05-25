import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Configuration globale des tests Flutter — exécutée AVANT tout test.
///
/// Charge les polices via `loadAppFonts()` pour stabiliser le rendu cross-
/// platform des goldens.
///
/// Installe [_FakeVideoPlayerPlatform] en tant que singleton
/// `VideoPlayerPlatform.instance` pour que `AppVideoBackground` soit
/// testable sans implémentation native (issues #69 #71 #72 #79).
///
/// Stratégie golden Linux-only (cf. ADR-010) :
/// - Sur **Linux** (= CI ubuntu-latest), les goldens sont enforcés (source of
///   truth).
/// - Sur **Windows / macOS** (dev local), `goldenFileComparator` est remplacé
///   par un bypass no-op pour éviter les faux positifs liés au rendu de
///   fonts (DirectWrite vs CoreText vs FreeType).
///
/// Régénération des goldens : déclencher manuellement le workflow GitHub
/// `Update Goldens` (cf. `.github/workflows/update-goldens.yml`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Mock VideoPlayerPlatform — évite UnimplementedError dans les widget tests.
  // Le fake répond à init() / create() / videoEventsFor() sans implémentation native.
  VideoPlayerPlatform.instance = _FakeVideoPlayerPlatform();

  await loadAppFonts();

  if (!Platform.isLinux) {
    goldenFileComparator = _BypassGoldenFileComparator();
  }

  return GoldenToolkit.runWithConfiguration(
    () async {
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      defaultDevices: const [Device.phone],
      enableRealShadows: false,
    ),
  );
}

/// Comparator no-op activé hors Linux : `compare()` renvoie toujours `true`,
/// `update()` ne fait rien. Les goldens commités restent la référence
/// Linux/CI.
class _BypassGoldenFileComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}

/// Implémentation factice de [VideoPlayerPlatform] pour les tests unitaires
/// et widget-tests. Évite l'[UnimplementedError] levé par la plateforme
/// native absente dans l'environnement de test headless.
///
/// Comportement :
/// - [init] : no-op.
/// - [create] / [createWithOptions] : retourne l'id `0` + émet un event
///   `initialized` (size 100×100, durée 1 s) pour que le contrôleur
///   considère la vidéo prête.
/// - [videoEventsFor] : retourne un stream vide infini (aucun event après
///   l'initialisation).
/// - Toutes les autres méthodes (play, pause, setVolume…) sont des no-ops.
class _FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _streams =
      <int, StreamController<VideoEvent>>{};
  int _nextId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => _spawnPlayer();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async =>
      _spawnPlayer();

  int _spawnPlayer() {
    final id = _nextId++;
    final ctrl = StreamController<VideoEvent>.broadcast();
    _streams[id] = ctrl;
    // Émettre l'événement d'initialisation en asynchrone pour que le
    // contrôleur ait le temps de s'abonner avant la réception.
    Future<void>.microtask(
      () => ctrl.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(100, 100),
          duration: const Duration(seconds: 1),
          rotationCorrection: 0,
        ),
      ),
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) =>
      _streams[playerId]?.stream ?? const Stream<VideoEvent>.empty();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {}

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  @override
  Future<void> dispose(int playerId) async {
    await _streams[playerId]?.close();
    _streams.remove(playerId);
  }
}
