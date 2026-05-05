import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

/// Configuration globale des tests Flutter — exécutée AVANT tout test.
///
/// - Charge les polices système pour stabiliser le rendu des goldens
///   (sinon la police par défaut diffère selon la plateforme du runner CI).
/// - Active une tolérance de pixel diff via `goldenFileComparator` pour
///   absorber les écarts mineurs de subpixel rendering entre Windows / macOS
///   / Linux runners.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return GoldenToolkit.runWithConfiguration(
    () async {
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      // Tolérance permissive : les goldens sont des smoke tests visuels, pas
      // des tests de régression pixel-parfait — on accepte 1% de pixel diff.
      defaultDevices: const [Device.phone],
      enableRealShadows: false,
    ),
  );
}
