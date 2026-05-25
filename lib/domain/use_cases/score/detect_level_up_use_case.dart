import 'package:murabbi_mobile/domain/entities/level.dart';

/// LEVEL-UP — détecte le franchissement d'un palier de niveau (issue #7).
///
/// Pure function : compare le niveau dérivé de [previousTotal] à celui de
/// [newTotal] (via [Level.fromPoints]). Renvoie le **nouveau** niveau atteint
/// si un palier supérieur a été franchi, sinon `null`.
///
/// Règles :
/// - si plusieurs paliers sont franchis d'un coup, on renvoie le plus haut
///   atteint (`Level.fromPoints(newTotal)`) ;
/// - une baisse de points ne déclenche jamais de level-up ;
/// - au niveau maximum, plus aucun level-up possible.
class DetectLevelUpUseCase {
  const DetectLevelUpUseCase();

  Level? call({required int previousTotal, required int newTotal}) {
    if (newTotal <= previousTotal) return null;
    final before = Level.fromPoints(previousTotal);
    final after = Level.fromPoints(newTotal);
    if (after.index > before.index) return after;
    return null;
  }
}
