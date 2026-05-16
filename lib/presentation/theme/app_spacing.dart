/// Espacement — grille 4px (DS sheet § Espacement).
class AppSpacing {
  AppSpacing._();

  /// 4px — micro espacement.
  static const double s1 = 4;

  /// 8px — petit espacement, gap entre dot+label.
  static const double s2 = 8;

  /// 12px — espacement intermédiaire.
  static const double s3 = 12;

  /// 16px — espacement standard, padding de carte.
  static const double s4 = 16;

  /// 20px — padding interne de carte large.
  static const double s5 = 20;

  /// 24px — section spacing.
  static const double s6 = 24;

  /// 32px — section grande / écart entre sections d'écran.
  static const double s8 = 32;
}

/// Rayons (DS sheet § Rayons).
class AppRadius {
  AppRadius._();

  /// 6px — chips, dots-status agrandis.
  static const double chip = 6;

  /// 10px — boutons.
  static const double button = 10;

  /// 16px — cartes (P-5 — pas d'ombre, juste rayon).
  static const double card = 16;

  /// 100px — pills (avatars, badges arrondis).
  static const double pill = 100;

  /// 20px — bottom sheets (coins supérieurs).
  static const double bottomSheet = 20.0;
}

/// Largeurs de bordure — grammaire ternaire volontaire.
///
/// Décision PO Option A (issue #28) : trois épaisseurs sémantiques distinctes
/// couvrent toutes les surfaces Murabbi. Toute autre valeur littérale dans
/// l'UI est interdite (Q-5 / P-5).
///
///   * [thin]            — bordures fines, séparateurs, cards.
///   * [focusRing]       — anneau de focus accessibilité (états focused).
///   * [indicatorStroke] — indicateurs d'état : loaders circulaires, arcs de
///                         progression, countdown next-prayer (slice 3.C.3).
class AppBorderWidth {
  AppBorderWidth._();

  /// 0.5px — bordure fine standard partout (P-5). Pas d'ombre portée.
  static const double thin = 0.5;

  /// 1.5px — focus ring (états input/bouton focused).
  static const double focusRing = 1.5;

  /// 2.0px — indicateurs d'état (CircularProgressIndicator, arcs Salat).
  static const double indicatorStroke = 2.0;
}
