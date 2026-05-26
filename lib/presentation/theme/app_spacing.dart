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

  /// 2px — drag handle, thumb margin.
  static const double drag = 2;

  /// 4px — barre de progression, dots de pagination.
  static const double indicator = 4;
}

/// Tailles d'icônes — hiérarchie sémantique (DS sheet § Iconographie).
///
/// Chaque palier correspond à un rôle précis dans l'UI Murabbi.
/// Toute valeur littérale hors de cette liste est interdite.
class AppIconSize {
  AppIconSize._();

  /// 11px — icône dans un badge/chip.
  static const double badge = 11;

  /// 12px — badge micro.
  static const double xs = 12;

  /// 16px — icône inline (input, bouton, pill, statut salat).
  static const double sm = 16;

  /// 18px — icône support (stats, banners, glyphe).
  static const double md = 18;

  /// 20px — icône UI standard (header, tile, formulaires).
  static const double rg = 20;

  /// 24px — icône navigation (bottom nav, chevrons).
  static const double nav = 24;

  /// 28px — icône intermédiaire (logo auth, timer icon).
  static const double semilg = 28;

  /// 32px — icône décorative de section.
  static const double lg = 32;

  /// 36px — illustration empty state compact.
  static const double xl = 36;

  /// 48px — illustration empty state large.
  static const double xxl = 48;
}

/// Tailles de composants fixes — éléments dont la dimension est contractuelle
/// avec le DS (cellules, avatars, touch targets…).
///
/// À distinguer de [AppIconSize] (icônes SVG) et [AppSpacing] (espacement).
class AppComponentSize {
  AppComponentSize._();

  /// 6px — dot couleur catégorie (badge, chip).
  static const double dotSize = 6;

  /// 20px — spinner dans un bouton.
  static const double spinnerSm = 20;

  /// 20px — pouce du toggle iOS.
  static const double toggleThumb = 20;

  /// 26px — hauteur contractuelle du toggle iOS.
  static const double toggleHeight = 26;

  /// 32px — cellule Heatmap30.
  static const double heatmapCell = 32;

  /// 36px — petit avatar.
  static const double avatarSm = 36;

  /// 40px — conteneur icône tile.
  static const double iconTile = 40;

  /// 44px — touch target minimum a11y.
  static const double touchTarget = 44;

  /// 44px — largeur contractuelle du toggle iOS.
  static const double toggleWidth = 44;

  /// 48px — cellule sélecteur d'icône HB-04.
  static const double iconSelectorCell = 48;

  /// 56px — avatar moyen (paramètres profil).
  static const double avatarMd = 56;

  /// 72px — colonne podium leaderboard / conteneur icône avertissement.
  static const double podiumCol = 72;

  /// 80px — illustration empty state compact.
  static const double emptyStateSm = 80;

  /// 88px — avatar large (écran vérification email, édition profil).
  static const double avatarLg = 88;

  /// 88px — illustration empty state principal.
  static const double emptyStateMd = 88;

  /// 132px — hauteur contractuelle d'une tuile stat du dashboard HM-01.
  /// Garantit une hauteur identique avec ou sans sous-label.
  static const double statTile = 132;

  /// 76px — hauteur contractuelle de la bottom navigation bar (DS v1.5).
  static const double bottomNavHeight = 76;

  /// 220px — cercle du timer habitude (HabitTimerSheet — _TimerCircle).
  static const double timerCircle = 220;

  /// 64px — bouton play/pause/reset du timer (HabitTimerSheet — _TimerButton).
  static const double timerButton = 64;

  /// 48px — hauteur de la barre de filtres par catégorie (HA-01 — _CategoryChipsBar).
  static const double filterChipBar = 48;

  /// 6px — hauteur minimale de la barre de progression habitude (HB-DETAIL).
  static const double progressBarHeight = 6;
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
///   * [progressRing]    — anneau de progression score quotidien (dashboard).
class AppBorderWidth {
  AppBorderWidth._();

  /// 0.5px — bordure fine standard partout (P-5). Pas d'ombre portée.
  static const double thin = 0.5;

  /// 1.5px — focus ring (états input/bouton focused).
  static const double focusRing = 1.5;

  /// 2.0px — indicateurs d'état (CircularProgressIndicator, arcs Salat).
  static const double indicatorStroke = 2.0;

  /// 7.0px — anneau de progression animé (DashboardScoreCard, AppProgressRing).
  static const double progressRing = 7.0;

  /// 6.0px — épaisseur du tracé annulaire du timer habitude (HabitTimerSheet).
  static const double timerStroke = 6.0;
}
