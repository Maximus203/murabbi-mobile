import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

/// Configuration globale des tests Flutter — exécutée AVANT tout test.
///
/// Charge les polices via `loadAppFonts()` pour stabiliser le rendu cross-
/// platform des goldens. La tolérance pixel diff entre runners (Windows
/// DirectWrite vs Linux FreeType) est gérée en générant les goldens dans
/// un environnement aligné avec la CI (Docker Linux Ubuntu — cf. README).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
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
