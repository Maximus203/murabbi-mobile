import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/use_cases/score/detect_level_up_use_case.dart';

/// Provider du use case de détection — surchargeable en test.
final detectLevelUpUseCaseProvider = Provider<DetectLevelUpUseCase>((ref) {
  return const DetectLevelUpUseCase();
});

/// Pilote l'overlay LEVEL-UP (issue #7).
///
/// L'état est le niveau **en attente de célébration** (`null` = rien à
/// afficher). Le caller (HM-01) appelle [observeTotal] à chaque nouvelle
/// valeur de score total : si un palier est franchi depuis le dernier
/// total observé, le niveau atteint est mis en état et l'overlay s'affiche.
///
/// [acknowledge] est appelé par le bouton "Continuer" pour fermer l'overlay.
///
/// Le premier total observé sert uniquement de référence (pas de level-up
/// au démarrage de l'app) — sinon chaque cold start rejouerait l'animation.
class LevelUpNotifier extends Notifier<Level?> {
  int? _lastTotal;

  @override
  Level? build() => null;

  /// Confronte [total] au dernier total connu et déclenche l'overlay si un
  /// palier supérieur a été franchi.
  void observeTotal(int total) {
    final previous = _lastTotal;
    _lastTotal = total;
    if (previous == null) return; // référence initiale — pas de trigger
    final reached = ref
        .read(detectLevelUpUseCaseProvider)
        .call(previousTotal: previous, newTotal: total);
    if (reached != null) state = reached;
  }

  /// Ferme l'overlay une fois l'utilisateur a appuyé sur "Continuer".
  void acknowledge() => state = null;
}

final levelUpNotifierProvider = NotifierProvider<LevelUpNotifier, Level?>(
  LevelUpNotifier.new,
);
