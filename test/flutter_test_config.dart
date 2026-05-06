import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Configuration globale des tests Flutter — exécutée AVANT tout test.
///
/// Charge les polices via `loadAppFonts()` pour stabiliser le rendu cross-
/// platform des goldens.
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
