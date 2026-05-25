/// Tokens de durée Murabbi — rythme des animations et intervalles applicatifs.
///
/// **Règle** : toute valeur [Duration] hardcodée dans `lib/presentation/` doit
/// utiliser l'un de ces tokens. Les durées métier (domain, services) restent
/// locales à leur couche.
///
/// Deux familles :
/// - Micro-interactions UI ([fast] → [shimmer]) — vitesse des transitions.
/// - Intervalles applicatifs ([timerTick] → [dashboardTick]) — fréquence des timers.
class AppDuration {
  AppDuration._();

  // -- Micro-interactions (animations UI) -------------------------------------

  /// 120 ms — transition rapide : focus border, AnimatedContainer input.
  static const Duration fast = Duration(milliseconds: 120);

  /// 150 ms — animation de liste : scroll snap, item reveal.
  static const Duration snappy = Duration(milliseconds: 150);

  /// 200 ms — transition standard : toggle, fade, cross-fade page.
  static const Duration standard = Duration(milliseconds: 200);

  /// 250 ms — glissement de page (PageView, slides onboarding).
  static const Duration pageSlide = Duration(milliseconds: 250);

  /// 600 ms — animation lente : ring de progression, graph reveal.
  static const Duration slow = Duration(milliseconds: 600);

  /// 1 200 ms — boucle shimmer skeleton (une passe complète).
  static const Duration shimmer = Duration(milliseconds: 1200);

  // -- Intervalles applicatifs ------------------------------------------------

  /// 1 s — tick du timer in-app habitude.
  static const Duration timerTick = Duration(seconds: 1);

  /// 5 s — intervalle de polling vérification email (AU-04).
  static const Duration pollInterval = Duration(seconds: 5);

  /// 30 s — rafraîchissement ticker dashboard (HM-01).
  static const Duration dashboardTick = Duration(seconds: 30);
}
